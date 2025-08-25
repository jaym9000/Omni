/**
 * Input Validator for Security
 * Sanitizes and validates user input to prevent injection attacks
 */

export class InputValidator {
  // Patterns that could indicate injection attempts
  // Be more specific to avoid false positives
  private static readonly INJECTION_PATTERNS = [
    /\[system\]/gi,
    /\[assistant\]/gi,
    /\[user\]/gi,
    /ignore previous instructions/gi,
    /forget everything above/gi,
    /disregard all prior commands/gi,
    /new instructions:/gi,
    /you are now a/gi,
    /roleplay as an?/gi,
    /simulate being a/gi,
    /bypass your safety/gi,
    /override your restrictions/gi,
    /jailbreak mode/gi,
    /DAN mode/gi,
    /developer mode enabled/gi,
  ];

  // Message length constraints
  private static readonly MAX_MESSAGE_LENGTH = 1000;
  private static readonly MIN_MESSAGE_LENGTH = 1;
  
  // Session ID pattern (alphanumeric with dashes)
  private static readonly SESSION_ID_PATTERN = /^[a-zA-Z0-9-]{10,50}$/;
  
  // Valid mood options - includes both Cloud Function and iOS app mood values
  private static readonly VALID_MOODS = [
    // Original Cloud Function moods
    "balanced", "creative", "focused", "empathetic",
    // iOS app MoodType values
    "happy", "anxious", "sad", "overwhelmed", "calm"
  ];

  /**
   * Sanitize and validate a message
   */
  static sanitizeMessage(message: unknown): string {
    // Type check
    if (typeof message !== "string") {
      throw new Error("Message must be a string");
    }

    // Trim whitespace
    let sanitized = message.trim();

    // Check length
    if (sanitized.length < this.MIN_MESSAGE_LENGTH) {
      throw new Error("Message is too short");
    }

    if (sanitized.length > this.MAX_MESSAGE_LENGTH) {
      // Truncate instead of rejecting
      sanitized = sanitized.substring(0, this.MAX_MESSAGE_LENGTH);
    }

    // Check for injection patterns
    for (const pattern of this.INJECTION_PATTERNS) {
      if (pattern.test(sanitized)) {
        // Log potential injection attempt for monitoring
        console.warn("Potential injection attempt detected:", {
          pattern: pattern.source,
          message: sanitized.substring(0, 100),
        });
        
        // Replace suspicious content
        sanitized = sanitized.replace(pattern, "[FILTERED]");
      }
    }

    // Remove control characters and null bytes
    sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "");

    // Remove excessive whitespace
    sanitized = sanitized.replace(/\s+/g, " ");

    // Escape HTML to prevent XSS if the message is ever displayed in HTML context
    sanitized = this.escapeHtml(sanitized);

    return sanitized;
  }

  /**
   * Validate session ID format
   */
  static validateSessionId(sessionId: unknown): string {
    if (typeof sessionId !== "string") {
      throw new Error("Session ID must be a string");
    }

    if (!this.SESSION_ID_PATTERN.test(sessionId)) {
      throw new Error("Invalid session ID format");
    }

    return sessionId;
  }

  /**
   * Validate and normalize mood parameter
   */
  static validateMood(mood: unknown): string {
    // Default to balanced if not provided
    if (!mood || typeof mood !== "string") {
      return "balanced";
    }

    const normalizedMood = mood.toLowerCase().trim();
    
    if (!this.VALID_MOODS.includes(normalizedMood)) {
      console.warn(`Invalid mood "${mood}" provided, defaulting to balanced`);
      return "balanced";
    }

    return normalizedMood;
  }

  /**
   * Escape HTML special characters
   */
  private static escapeHtml(text: string): string {
    const htmlEscapes: Record<string, string> = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#x27;",
      "/": "&#x2F;",
    };

    return text.replace(/[&<>"'\/]/g, (match) => htmlEscapes[match]);
  }

  /**
   * Validate request body structure
   */
  static validateRequestBody(body: unknown): {
    message: string;
    sessionId: string;
    mood: string;
  } {
    if (!body || typeof body !== "object") {
      throw new Error("Invalid request body");
    }

    const requestBody = body as Record<string, unknown>;

    // Validate and sanitize each field
    const message = this.sanitizeMessage(requestBody.message);
    const sessionId = this.validateSessionId(requestBody.sessionId);
    const mood = this.validateMood(requestBody.mood);

    return {
      message,
      sessionId,
      mood,
    };
  }

  /**
   * Check if content appears to be malicious
   */
  static isSuspiciousContent(message: string): boolean {
    // Check for excessive special characters (increased threshold)
    const specialCharCount = (message.match(/[!@#$%^&*()_+=\[\]{};':"\\|,.<>\/?]/g) || []).length;
    const specialCharRatio = specialCharCount / message.length;
    
    // Increased threshold - normal messages can have punctuation
    if (specialCharRatio > 0.5) {
      return true;
    }

    // Check for excessive uppercase (shouting/spam)
    const letterCount = (message.match(/[a-zA-Z]/g) || []).length;
    if (letterCount > 0) {  // Only check if there are letters
      const uppercaseCount = (message.match(/[A-Z]/g) || []).length;
      const uppercaseRatio = uppercaseCount / letterCount;
      
      // Allow acronyms and normal capitalization
      if (uppercaseRatio > 0.8 && letterCount > 10) {
        return true;
      }
    }

    // Check for repeated patterns (spam) - more lenient
    const words = message.split(" ");
    const uniqueWords = new Set(words.map(w => w.toLowerCase()));
    
    // Only flag if very repetitive
    if (words.length > 10 && uniqueWords.size < words.length / 4) {
      return true;
    }

    return false;
  }
}

export default InputValidator;