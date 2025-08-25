/**
 * Content Moderator for AI Safety
 * Uses OpenAI's moderation API to check for harmful content
 */

import {OpenAI} from "openai";

export interface ModerationResult {
  safe: boolean;
  reason?: string;
  categories?: string[];
  scores?: Record<string, number>;
}

export class ContentModerator {
  private openai: OpenAI;
  private moderationCache: Map<string, ModerationResult>;
  private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutes cache

  constructor(apiKey: string) {
    this.openai = new OpenAI({apiKey});
    this.moderationCache = new Map();
    
    // Clear cache periodically
    setInterval(() => this.clearExpiredCache(), this.CACHE_TTL);
  }

  /**
   * Check if content is safe using OpenAI moderation
   */
  async isContentSafe(message: string): Promise<ModerationResult> {
    try {
      // Check cache first
      const cached = this.getCachedResult(message);
      if (cached) {
        return cached;
      }

      // Call OpenAI moderation API
      const moderation = await this.openai.moderations.create({
        input: message,
      });

      const result = moderation.results[0];
      
      if (!result) {
        // If no result, assume safe but log warning
        console.warn("No moderation result received for message");
        return {safe: true};
      }

      // Check if content was flagged
      if (result.flagged) {
        const flaggedCategories = Object.entries(result.categories)
          .filter(([_, flagged]) => flagged)
          .map(([category]) => this.formatCategoryName(category));

        const categoryScores = Object.entries(result.category_scores)
          .filter(([category]) => result.categories[category as keyof typeof result.categories])
          .reduce((acc, [category, score]) => {
            acc[category] = score;
            return acc;
          }, {} as Record<string, number>);

        const moderationResult: ModerationResult = {
          safe: false,
          reason: `Content violates policies: ${flaggedCategories.join(", ")}`,
          categories: flaggedCategories,
          scores: categoryScores,
        };

        // Cache the result
        this.cacheResult(message, moderationResult);
        
        // Log for monitoring
        console.warn("Content flagged by moderation:", {
          categories: flaggedCategories,
          scores: categoryScores,
          messagePreview: message.substring(0, 50),
        });

        return moderationResult;
      }

      // Content is safe
      const safeResult: ModerationResult = {safe: true};
      this.cacheResult(message, safeResult);
      
      return safeResult;
    } catch (error) {
      // Log error but don't block the request
      console.error("Moderation API error:", error);
      
      // In case of API error, perform basic checks
      return this.performBasicModeration(message);
    }
  }

  /**
   * Perform basic moderation when API is unavailable
   */
  private performBasicModeration(message: string): ModerationResult {
    const lowerMessage = message.toLowerCase();
    
    // Basic profanity and harmful content patterns
    const harmfulPatterns = [
      /\bkill\s+(yourself|myself|someone)\b/i,
      /\bsuicid[ea]/i,
      /\bharm\s+(yourself|myself|others)\b/i,
      /\bself[\s-]?harm/i,
      /\bhate\s+(speech|crime)/i,
      /\b(racial|ethnic)\s+slur/i,
    ];

    for (const pattern of harmfulPatterns) {
      if (pattern.test(lowerMessage)) {
        return {
          safe: false,
          reason: "Content contains potentially harmful language",
          categories: ["harmful_content"],
        };
      }
    }

    // Check for excessive profanity (simplified check)
    const profanityCount = (lowerMessage.match(/\b(fuck|shit|damn|hell|ass)\b/gi) || []).length;
    const wordCount = lowerMessage.split(/\s+/).length;
    
    if (profanityCount > 0 && profanityCount / wordCount > 0.2) {
      return {
        safe: false,
        reason: "Excessive profanity detected",
        categories: ["profanity"],
      };
    }

    return {safe: true};
  }

  /**
   * Format category name for display
   */
  private formatCategoryName(category: string): string {
    return category
      .replace(/_/g, " ")
      .replace(/\b\w/g, (l) => l.toUpperCase());
  }

  /**
   * Cache moderation result
   */
  private cacheResult(message: string, result: ModerationResult): void {
    const cacheKey = this.getCacheKey(message);
    this.moderationCache.set(cacheKey, {
      ...result,
      timestamp: Date.now(),
    } as ModerationResult & {timestamp: number});
  }

  /**
   * Get cached moderation result
   */
  private getCachedResult(message: string): ModerationResult | null {
    const cacheKey = this.getCacheKey(message);
    const cached = this.moderationCache.get(cacheKey) as (ModerationResult & {timestamp: number}) | undefined;
    
    if (!cached) {
      return null;
    }

    // Check if cache is still valid
    if (Date.now() - cached.timestamp > this.CACHE_TTL) {
      this.moderationCache.delete(cacheKey);
      return null;
    }

    return {
      safe: cached.safe,
      reason: cached.reason,
      categories: cached.categories,
      scores: cached.scores,
    };
  }

  /**
   * Generate cache key for message
   */
  private getCacheKey(message: string): string {
    // Simple hash function for cache key
    let hash = 0;
    for (let i = 0; i < message.length; i++) {
      const char = message.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return `msg_${hash}`;
  }

  /**
   * Clear expired cache entries
   */
  private clearExpiredCache(): void {
    const now = Date.now();
    for (const [key, value] of this.moderationCache.entries()) {
      const cached = value as ModerationResult & {timestamp: number};
      if (now - cached.timestamp > this.CACHE_TTL) {
        this.moderationCache.delete(key);
      }
    }
  }

  /**
   * Check for crisis content that needs immediate resources
   */
  static detectCrisisContent(message: string): boolean {
    const crisisPatterns = [
      /\b(want|going|plan)\s+to\s+(die|kill|end|hurt)/i,
      /\bsuicidal?\b/i,
      /\bself[\s-]?harm/i,
      /\bcut(ting)?\s+myself\b/i,
      /\bend\s+it\s+all\b/i,
      /\bno\s+reason\s+to\s+live\b/i,
      /\bbetter\s+off\s+(dead|gone)\b/i,
    ];

    const lowerMessage = message.toLowerCase();
    return crisisPatterns.some(pattern => pattern.test(lowerMessage));
  }
}

export default ContentModerator;