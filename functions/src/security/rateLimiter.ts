/**
 * Rate Limiter for OpenAI API Usage
 * Implements tiered rate limiting based on user type
 */

import * as admin from "firebase-admin";

export interface RateLimitConfig {
  requestsPerDay: number;
  tokensPerDay: number;
  requestsPerMinute: number;
  requestsPerHour: number;
}

export interface RateLimitResult {
  allowed: boolean;
  reason?: string;
  remainingRequests?: number;
  resetTime?: Date;
}

export class OpenAIRateLimiter {
  private static readonly LIMITS: Record<string, RateLimitConfig> = {
    guest: {
      requestsPerDay: 3,
      tokensPerDay: 1000,
      requestsPerMinute: 1,
      requestsPerHour: 3,
    },
    free: {
      requestsPerDay: 50,
      tokensPerDay: 10000,
      requestsPerMinute: 3,
      requestsPerHour: 20,
    },
    premium: {
      requestsPerDay: 1000,
      tokensPerDay: 100000,
      requestsPerMinute: 10,
      requestsPerHour: 100,
    },
    unlimited: {
      requestsPerDay: 10000,
      tokensPerDay: 1000000,
      requestsPerMinute: 20,
      requestsPerHour: 500,
    },
  };

  private db: admin.firestore.Firestore;

  constructor() {
    this.db = admin.firestore();
  }

  /**
   * Check and update rate limits for a user
   */
  async checkAndUpdateLimits(
    userId: string,
    userType: keyof typeof OpenAIRateLimiter.LIMITS,
    estimatedTokens: number = 150
  ): Promise<RateLimitResult> {
    const limitsRef = this.db.collection("rateLimits").doc(userId);
    
    try {
      return await this.db.runTransaction(async (transaction) => {
        const doc = await transaction.get(limitsRef);
        const now = Date.now();
        const today = new Date().toDateString();
        const currentHour = new Date().getHours();
        
        // Initialize or get existing data
        let data: any = doc.exists && doc.data() ? doc.data() : {
          requestsToday: 0,
          tokensToday: 0,
          lastRequestTime: 0,
          dateKey: today,
          hourKey: currentHour,
          requestsThisHour: 0,
          minuteRequests: [],
        };

        // Reset daily counters if new day
        if (data.dateKey !== today) {
          data = {
            requestsToday: 0,
            tokensToday: 0,
            lastRequestTime: now,
            dateKey: today,
            hourKey: currentHour,
            requestsThisHour: 0,
            minuteRequests: [],
          };
        }

        // Reset hourly counter if new hour
        if (data.hourKey !== currentHour) {
          data.hourKey = currentHour;
          data.requestsThisHour = 0;
        }

        // Clean up old minute requests (older than 1 minute)
        const oneMinuteAgo = now - 60000;
        data.minuteRequests = (data.minuteRequests || []).filter(
          (time: number) => time > oneMinuteAgo
        );

        // Get limits for user type
        const limits = OpenAIRateLimiter.LIMITS[userType] || OpenAIRateLimiter.LIMITS.guest;

        // Check minute rate limit
        if (data.minuteRequests.length >= limits.requestsPerMinute) {
          const oldestRequest = Math.min(...data.minuteRequests);
          const resetTime = new Date(oldestRequest + 60000);
          
          return {
            allowed: false,
            reason: `Rate limit exceeded. Maximum ${limits.requestsPerMinute} requests per minute.`,
            remainingRequests: 0,
            resetTime: resetTime,
          };
        }

        // Check hourly rate limit
        if (data.requestsThisHour >= limits.requestsPerHour) {
          const nextHour = new Date();
          nextHour.setHours(nextHour.getHours() + 1, 0, 0, 0);
          
          return {
            allowed: false,
            reason: `Hourly limit reached. Maximum ${limits.requestsPerHour} requests per hour.`,
            remainingRequests: 0,
            resetTime: nextHour,
          };
        }

        // Check daily request limit
        if (data.requestsToday >= limits.requestsPerDay) {
          const tomorrow = new Date();
          tomorrow.setDate(tomorrow.getDate() + 1);
          tomorrow.setHours(0, 0, 0, 0);
          
          return {
            allowed: false,
            reason: `Daily limit reached. Maximum ${limits.requestsPerDay} requests per day.`,
            remainingRequests: 0,
            resetTime: tomorrow,
          };
        }

        // Check daily token limit
        if (data.tokensToday + estimatedTokens > limits.tokensPerDay) {
          const tomorrow = new Date();
          tomorrow.setDate(tomorrow.getDate() + 1);
          tomorrow.setHours(0, 0, 0, 0);
          
          return {
            allowed: false,
            reason: `Daily token limit reached. Maximum ${limits.tokensPerDay} tokens per day.`,
            remainingRequests: 0,
            resetTime: tomorrow,
          };
        }

        // Update counters
        data.requestsToday += 1;
        data.requestsThisHour += 1;
        data.tokensToday += estimatedTokens;
        data.lastRequestTime = now;
        data.minuteRequests.push(now);

        // Save updated data
        transaction.set(limitsRef, data);

        // Return success with remaining requests
        const remainingRequests = limits.requestsPerDay - data.requestsToday;
        
        return {
          allowed: true,
          remainingRequests: remainingRequests,
        };
      });
    } catch (error) {
      console.error("Rate limiter error:", error);
      // In case of error, allow the request but log for monitoring
      return {
        allowed: true,
        reason: "Rate limiter error - allowing request",
      };
    }
  }

  /**
   * Get user type based on subscription status
   */
  async getUserType(userId: string, isAnonymous: boolean = false): Promise<keyof typeof OpenAIRateLimiter.LIMITS> {
    // Check for anonymous/guest users
    if (isAnonymous || userId.startsWith("guest_")) {
      return "guest";
    }

    try {
      // Check user's subscription status in Firestore
      const userDoc = await this.db.collection("users").doc(userId).get();
      
      if (!userDoc.exists) {
        return "guest";
      }

      const userData = userDoc.data();
      
      // Check subscription status
      if (userData?.subscriptionStatus === "active") {
        // Check subscription tier
        switch (userData.subscriptionTier) {
          case "premium":
            return "premium";
          case "unlimited":
            return "unlimited";
          default:
            return "free";
        }
      }

      // Check if user has completed sign-up (has email)
      if (userData?.email && userData?.emailVerified) {
        return "free";
      }

      return "guest";
    } catch (error) {
      console.error("Error getting user type:", error);
      return "guest"; // Default to most restrictive
    }
  }

  /**
   * Reset daily limits (for scheduled function)
   */
  async resetDailyLimits(): Promise<void> {
    const batch = this.db.batch();
    const snapshot = await this.db.collection("rateLimits").get();
    
    snapshot.forEach((doc) => {
      batch.update(doc.ref, {
        requestsToday: 0,
        tokensToday: 0,
        dateKey: new Date().toDateString(),
      });
    });

    await batch.commit();
    console.log(`Reset daily limits for ${snapshot.size} users`);
  }

  /**
   * Get usage statistics for a user
   */
  async getUsageStats(userId: string): Promise<{
    requestsToday: number;
    tokensToday: number;
    limits: RateLimitConfig;
  }> {
    const doc = await this.db.collection("rateLimits").doc(userId).get();
    const data = doc.exists && doc.data() ? doc.data() : {requestsToday: 0, tokensToday: 0};
    
    const userType = await this.getUserType(userId);
    const limits = OpenAIRateLimiter.LIMITS[userType];

    return {
      requestsToday: data?.requestsToday || 0,
      tokensToday: data?.tokensToday || 0,
      limits: limits,
    };
  }

  /**
   * Estimate token count for a message
   */
  static estimateTokens(message: string): number {
    // Rough estimation: 1 token ≈ 4 characters
    // This is a simplified estimation; in production, use tiktoken library
    const baseTokens = Math.ceil(message.length / 4);
    
    // Add overhead for system prompt and response
    const overhead = 150; // Approximate system prompt + response structure
    
    return baseTokens + overhead;
  }

  /**
   * Check if user is approaching limits
   */
  async checkLimitWarning(userId: string): Promise<{
    warning: boolean;
    message?: string;
  }> {
    const stats = await this.getUsageStats(userId);
    const requestPercentage = (stats.requestsToday / stats.limits.requestsPerDay) * 100;
    const tokenPercentage = (stats.tokensToday / stats.limits.tokensPerDay) * 100;

    if (requestPercentage >= 80 || tokenPercentage >= 80) {
      return {
        warning: true,
        message: `You've used ${Math.round(Math.max(requestPercentage, tokenPercentage))}% of your daily limit`,
      };
    }

    return {warning: false};
  }
}

export default OpenAIRateLimiter;