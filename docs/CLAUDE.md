# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OmniAI is a therapeutic mental health companion iOS app built with SwiftUI. Originally a React Native app, this is a complete Swift/SwiftUI reimplementation focusing on evidence-based design for anxiety and depression support.

**Current Version:** 1.1 (22)
**Key Technical Details:**
- Swift 5.9+ with SwiftUI framework  
- iOS 16.0+ deployment target
- Architecture: MVVM with ObservableObject pattern
- No backend integration - all data is mocked/local

## Files to Exclude from Analysis

**IMPORTANT:** When analyzing or reviewing code in this repository, ALWAYS skip the following files as they are system-generated, temporary, or not relevant to code review:

### System Files (Never analyze these)
- `.DS_Store` - macOS finder metadata (large and irrelevant)
- `._*` - macOS resource fork files
- `Thumbs.db` - Windows thumbnail cache
- `.Spotlight-V100` - macOS Spotlight index
- `.Trashes` - macOS trash metadata

### Build Artifacts
- `build/` - Xcode build output
- `DerivedData/` - Xcode derived data
- `*.xcuserdata` - User-specific Xcode data
- `*.dSYM` - Debug symbols
- `*.ipa` - App archives

### Temporary Files
- `*.tmp`, `*.swp`, `*.swo` - Temporary editor files
- `*~` - Backup files
- `npm-debug.log*` - npm logs
- `yarn-error.log*` - yarn logs

### Large Binary Files
- Images in `test_screenshots/` - Screenshot files
- `*.png`, `*.jpg` when in Temp/ directories

**Note:** Focus analysis on Swift source files (.swift), configuration files, and documentation. Skip all system-generated metadata.

## Development Commands

### Building and Running
```bash
# Open correct project (critical - there may be old project files)
open OmniAI.xcodeproj

# Build via command line
xcodebuild -project OmniAI.xcodeproj -scheme OmniAI -destination 'platform=iOS Simulator,name=iPhone 16' build

# Archive for TestFlight (version/build auto-incremented in project.pbxproj)
xcodebuild -project OmniAI.xcodeproj -scheme OmniAI -configuration Release archive
```

**Critical:** Always use `OmniAI.xcodeproj` - ignore any old `Omni.xcodeproj` files.

### Version Management
Version info is stored in `project.pbxproj`:
- `MARKETING_VERSION` = user-facing version (e.g. "1.1") 
- `CURRENT_PROJECT_VERSION` = build number (e.g. "22")
- Profile screen dynamically shows these via `Bundle.main.object(forInfoDictionaryKey:)`

### No Testing Framework
App uses SwiftUI Preview providers only. All data is mocked - no real API integration.

## Architecture Overview

### Core State Management Pattern
The app uses a three-manager system injected as environment objects:
- **AuthenticationManager**: User authentication, sign-in/sign-up flow
- **PremiumManager**: Subscription features and premium access control  
- **ThemeManager**: Dark/light mode and color system

These are injected at the app root in `OmniAIApp.swift` and accessed throughout the view hierarchy via `@EnvironmentObject`.

### Navigation & State Flow
**Key Pattern:** The app avoids NavigationStack in favor of programmatic sheet/fullScreenCover presentations for major flows:
- Chat is presented via `fullScreenCover` 
- Mood selection uses callback pattern from child to parent
- Bottom sheets use `presentationDetents` for partial coverage

**Mood Flow Architecture:** When a user selects a mood emoji:
1. `HomeView` shows `MoodBottomSheet` via `.sheet()`
2. MoodBottomSheet uses callback pattern: `onTalkToOmni: (String) -> Void` 
3. Parent `HomeView` manages chat presentation state and initial prompt
4. This prevents modal-within-modal dismissal issues

### Data Models
- **MoodEntry**: Enum-based mood tracking with emoji, color, and labels
- **ChatMessage**: Simple message model with content, user flag, timestamp
- **JournalEntry**: Support for free-form, tagged, and themed journal entries
- **User**: Authentication model supporting email and Apple Sign In

### UI Component Patterns
- **Callback-driven components**: Complex components like `MoodBottomSheet` use callback parameters rather than internal navigation
- **Environment color system**: Custom semantic colors (`.omniTextPrimary`, `.omniprimary`, etc.)
- **State hoisting**: Child components receive state and callbacks from parents rather than managing their own navigation

## Therapeutic Design System (Evidence-Based)

### Color Psychology Implementation
**Critical:** This app uses scientifically-researched therapeutic colors to reduce anxiety:
- **Primary Color:** Sage green (`#7FB069`) - proven to reduce anxiety and heart rate
- **Backgrounds:** Warm cream (`#F9F7F4`) instead of clinical white - creates nurturing environment  
- **Text Colors:** Warm grays (`#3A3D42`, `#6B7280`) - less harsh than pure black
- **Mood Colors:** Muted versions (avoid bright yellow/orange that trigger anxious users)

**Key Research:** Users with anxiety/depression avoid warm colors and prefer soft blues/greens. All colors defined in `ThemeManager.swift` extension.

### Therapeutic UX Patterns
- **Gentle Mood Emojis:** `🙂😔🙁😮‍💨😌` (avoid intense expressions like `😰🤯😢`)
- **Soft Interactions:** Only specific buttons clickable (not entire cards) 
- **Calming Animations:** Smooth, slow transitions to reduce stimulation
- **Therapeutic Messaging:** "Your safe space for mental wellness" branding

### Mental Health Features Implementation

#### Mood-Aware Chat System
Chat behavior adapts to emotional context:
- Mood-triggered chats receive empathetic initial prompts: "I see you're feeling [mood]..."
- Chat/Voice toggle with polished circular mic button (not boxy design)
- Generic welcome for non-mood chats: "Hi there! 👋 How are you feeling today?"

#### Anxiety Management Card
Special interaction pattern:
- **Only "Let's Start" button is clickable** (not entire card surface)
- Uses stress-reducing lavender background (`omniCardLavender`)
- Compact design with leaf icon and therapeutic sage green button

#### Journal System with Therapeutic Colors
- **Free-form:** Beige cards (`omniCardBeige`) for warmth
- **Tagged/Themed:** Lavender cards (`omniCardLavender`) for calm
- Empty states properly centered for all device sizes
- Soft placeholder text and gentle encouragement

## Development Notes

### Premium Feature Gates
Premium features are controlled via `PremiumManager.isPremium`. Components check this before allowing access to:
- Unlimited chat conversations
- Chat history access
- Advanced mood analytics
- Export functionality

### Data Persistence
Currently uses local storage only:
- `@AppStorage` for user preferences and daily data
- `UserDefaults` for authentication state
- No backend integration (all API calls are mocked)

### Animation & UX Patterns
- Bottom sheets use `.presentationDetents([.height(300), .medium])`
- State changes use `.animation()` modifiers for smooth transitions
- Callback pattern prevents navigation stack complexity

### Asset Management
Images use proper Xcode imageset structure in `Assets.xcassets/Images/`. Each image requires a `Contents.json` file with scale variants.

### Therapeutic Color System
All colors in `ThemeManager.swift` are research-based for mental health:
- **Text Hierarchy:** `.omniTextPrimary` (warm dark gray), `.omniTextSecondary` (medium), `.omniTextTertiary` (light)
- **Therapeutic Cards:** `.omniCardBeige`, `.omniCardLavender`, `.omniCardSoftBlue`
- **Mood Colors:** Muted versions - `.moodHappy` (soft yellow), `.moodAnxious` (coral), `.moodCalm` (sage)
- **Brand Color:** `.omniprimary` (therapeutic sage green #7FB069)

## Critical Design Patterns When Making Changes

### 1. Therapeutic Color Consistency
**Always maintain the evidence-based color system:**
```swift
// ✅ Good - uses therapeutic colors
.background(Color.omniCardLavender)
.foregroundColor(.omniprimary)

// ❌ Bad - breaks therapeutic design
.background(Color.white)  
.foregroundColor(.blue)
```

### 2. Gentle User Interactions  
**Only make intended elements clickable:**
```swift
// ✅ Good - specific button only
VStack {
    Text("Content")  // Not clickable
    Button("Action") { ... }  // Only this clickable
}

// ❌ Bad - entire card clickable
Button(action: { ... }) {
    VStack { /* entire content */ }
}
```

### 3. Mental Health-Appropriate UX
- Use gentle, non-alarming language
- Implement smooth, calming animations  
- Avoid bright/stimulating colors (yellow, orange, bright red)
- Center empty states properly with GeometryReader for all devices
- Use muted emoji expressions to avoid triggering sensitive users

### 4. App-Specific Navigation Patterns
- **Chat:** Use `fullScreenCover` with dismiss pattern
- **Mood Selection:** Callback pattern to parent, avoid nested modals
- **Bottom Sheets:** `.presentationDetents([.height(300), .medium])`
- **State Flow:** Inject environment objects, use callback pattern for complex interactions

### 5. Version Updates
Update both version fields in `project.pbxproj`:
- `MARKETING_VERSION` for user-facing version
- `CURRENT_PROJECT_VERSION` for build number (must always increment)

## Simulator Testing
Universal iOS app - test on both iPhone and iPad simulators. All layouts must be optimized for both device types.

# Claude Code Guidelines by Sabrina Ramonov

## Implementation Best Practices

### 0 — Purpose  

These rules ensure maintainability, safety, and developer velocity. 
**MUST** rules are enforced by CI; **SHOULD** rules are strongly recommended.

---

### 1 — Before Coding

- **BP-1 (MUST)** Ask the user clarifying questions.
- **BP-2 (SHOULD)** Draft and confirm an approach for complex work.  
- **BP-3 (SHOULD)** If ≥ 2 approaches exist, list clear pros and cons.

---

### 2 — While Coding

- **C-1 (MUST)** Follow TDD: scaffold stub -> write failing test -> implement.
- **C-2 (MUST)** Name functions with existing domain vocabulary for consistency.  
- **C-3 (SHOULD NOT)** Introduce classes when small testable functions suffice.  
- **C-4 (SHOULD)** Prefer simple, composable, testable functions.
- **C-5 (MUST)** Prefer branded `type`s for IDs
  ```ts
  type UserId = Brand<string, 'UserId'>   // ✅ Good
  type UserId = string                    // ❌ Bad
  ```  
- **C-6 (MUST)** Use `import type { … }` for type-only imports.
- **C-7 (SHOULD NOT)** Add comments except for critical caveats; rely on self‑explanatory code.
- **C-8 (SHOULD)** Default to `type`; use `interface` only when more readable or interface merging is required. 
- **C-9 (SHOULD NOT)** Extract a new function unless it will be reused elsewhere, is the only way to unit-test otherwise untestable logic, or drastically improves readability of an opaque block.

---

### 3 — Testing

- **T-1 (MUST)** For a simple function, colocate unit tests in `*.spec.ts` in same directory as source file.
- **T-2 (MUST)** For any API change, add/extend integration tests in `packages/api/test/*.spec.ts`.
- **T-3 (MUST)** ALWAYS separate pure-logic unit tests from DB-touching integration tests.
- **T-4 (SHOULD)** Prefer integration tests over heavy mocking.  
- **T-5 (SHOULD)** Unit-test complex algorithms thoroughly.
- **T-6 (SHOULD)** Test the entire structure in one assertion if possible
  ```ts
  expect(result).toBe([value]) // Good

  expect(result).toHaveLength(1); // Bad
  expect(result[0]).toBe(value); // Bad
  ```

---

### 4 — Database

- **D-1 (MUST)** Type DB helpers as `KyselyDatabase | Transaction<Database>`, so it works for both transactions and DB instances.  
- **D-2 (SHOULD)** Override incorrect generated types in `packages/shared/src/db-types.override.ts`. e.g. autogenerated types show incorrect BigInt value – so we override to `string` manually.

---

### 5 — Code Organization

- **O-1 (MUST)** Place code in `packages/shared` only if used by ≥ 2 packages.

---

### 6 — Tooling Gates

- **G-1 (MUST)** `prettier --check` passes.  
- **G-2 (MUST)** `turbo typecheck lint` passes.  

---

### 7 - Git

- **GH-1 (MUST**) Use Conventional Commits format when writing commit messages: https://www.conventionalcommits.org/en/v1.0.0
- **GH-2 (SHOULD NOT**) Refer to Claude or Anthropic in commit messages.

---

## Writing Functions Best Practices

When evaluating whether a function you implemented is good or not, use this checklist:

1. Can you read the function and HONESTLY easily follow what it's doing? If yes, then stop here.
2. Does the function have very high cyclomatic complexity? (number of independent paths, or, in a lot of cases, number of nesting if if-else as a proxy). If it does, then it's probably sketchy.
3. Are there any common data structures and algorithms that would make this function much easier to follow and more robust? Parsers, trees, stacks / queues, etc.
4. Are there any unused parameters in the function?
5. Are there any unnecessary type casts that can be moved to function arguments?
6. Is the function easily testable without mocking core features (e.g. sql queries, redis, etc.)? If not, can this function be tested as part of an integration test?
7. Does it have any hidden untested dependencies or any values that can be factored out into the arguments instead? Only care about non-trivial dependencies that can actually change or affect the function.
8. Brainstorm 3 better function names and see if the current name is the best, consistent with rest of codebase.

IMPORTANT: you SHOULD NOT refactor out a separate function unless there is a compelling need, such as:
  - the refactored function is used in more than one place
  - the refactored function is easily unit testable while the original function is not AND you can't test it any other way
  - the original function is extremely hard to follow and you resort to putting comments everywhere just to explain it

## Writing Tests Best Practices

When evaluating whether a test you've implemented is good or not, use this checklist:

1. SHOULD parameterize inputs; never embed unexplained literals such as 42 or "foo" directly in the test.
2. SHOULD NOT add a test unless it can fail for a real defect. Trivial asserts (e.g., expect(2).toBe(2)) are forbidden.
3. SHOULD ensure the test description states exactly what the final expect verifies. If the wording and assert don't align, rename or rewrite.
4. SHOULD compare results to independent, pre-computed expectations or to properties of the domain, never to the function's output re-used as the oracle.
5. SHOULD follow the same lint, type-safety, and style rules as prod code (prettier, ESLint, strict types).
6. SHOULD express invariants or axioms (e.g., commutativity, idempotence, round-trip) rather than single hard-coded cases whenever practical. Use `fast-check` library e.g.
```
import fc from 'fast-check';
import { describe, expect, test } from 'vitest';
import { getCharacterCount } from './string';

describe('properties', () => {
  test('concatenation functoriality', () => {
    fc.assert(
      fc.property(
        fc.string(),
        fc.string(),
        (a, b) =>
          getCharacterCount(a + b) ===
          getCharacterCount(a) + getCharacterCount(b)
      )
    );
  });
});
```

7. Unit tests for a function should be grouped under `describe(functionName, () => ...`.
8. Use `expect.any(...)` when testing for parameters that can be anything (e.g. variable ids).
9. ALWAYS use strong assertions over weaker ones e.g. `expect(x).toEqual(1)` instead of `expect(x).toBeGreaterThanOrEqual(1)`.
10. SHOULD test edge cases, realistic input, unexpected input, and value boundaries.
11. SHOULD NOT test conditions that are caught by the type checker.

## Code Organization

- `packages/api` - Fastify API server
  - `packages/api/src/publisher/*.ts` - Specific implementations of publishing to social media platforms
- `packages/web` - Next.js 15 app with App Router
- `packages/shared` - Shared types and utilities
  - `packages/shared/social.ts` - Character size and media validations for social media platforms
- `packages/api-schema` - API contract schemas using TypeBox

## Remember Shortcuts

Remember the following shortcuts which the user may invoke at any time.

### QNEW

When I type "qnew", this means:

```
Understand all BEST PRACTICES listed in CLAUDE.md.
Your code SHOULD ALWAYS follow these best practices.
```

### QPLAN
When I type "qplan", this means:
```
Analyze similar parts of the codebase and determine whether your plan:
- is consistent with rest of codebase
- introduces minimal changes
- reuses existing code
```

## QCODE

When I type "qcode", this means:

```
Implement your plan and make sure your new tests pass.
Always run tests to make sure you didn't break anything else.
Always run `prettier` on the newly created files to ensure standard formatting.
Always run `turbo typecheck lint` to make sure type checking and linting passes.
```

### QCHECK

When I type "qcheck", this means:

```
You are a SKEPTICAL senior software engineer.
Perform this analysis for every MAJOR code change you introduced (skip minor changes):

1. CLAUDE.md checklist Writing Functions Best Practices.
2. CLAUDE.md checklist Writing Tests Best Practices.
3. CLAUDE.md checklist Implementation Best Practices.
```

### QCHECKF

When I type "qcheckf", this means:

```
You are a SKEPTICAL senior software engineer.
Perform this analysis for every MAJOR function you added or edited (skip minor changes):

1. CLAUDE.md checklist Writing Functions Best Practices.
```

### QCHECKT

When I type "qcheckt", this means:

```
You are a SKEPTICAL senior software engineer.
Perform this analysis for every MAJOR test you added or edited (skip minor changes):

1. CLAUDE.md checklist Writing Tests Best Practices.
```

### QUX

When I type "qux", this means:

```
Imagine you are a human UX tester of the feature you implemented. 
Output a comprehensive list of scenarios you would test, sorted by highest priority.
```

### QGIT

When I type "qgit", this means:

```
Add all changes to staging, create a commit, and push to remote.

Follow this checklist for writing your commit message:
- SHOULD use Conventional Commits format: https://www.conventionalcommits.org/en/v1.0.0
- SHOULD NOT refer to Claude or Anthropic in the commit message.
- SHOULD structure commit message as follows:
<type>[optional scope]: <description>
[optional body]
[optional footer(s)]
- commit SHOULD contain the following structural elements to communicate intent: 
fix: a commit of the type fix patches a bug in your codebase (this correlates with PATCH in Semantic Versioning).
feat: a commit of the type feat introduces a new feature to the codebase (this correlates with MINOR in Semantic Versioning).
BREAKING CHANGE: a commit that has a footer BREAKING CHANGE:, or appends a ! after the type/scope, introduces a breaking API change (correlating with MAJOR in Semantic Versioning). A BREAKING CHANGE can be part of commits of any type.
types other than fix: and feat: are allowed, for example @commitlint/config-conventional (based on the Angular convention) recommends build:, chore:, ci:, docs:, style:, refactor:, perf:, test:, and others.
footers other than BREAKING CHANGE: <description> may be provided and follow a convention similar to git trailer format.
```
 but tailor it to this project. Make sure tests include building the project in xcode and fixing any errors it comes along until build is successful.