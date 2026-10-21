# Smooth Chat Keyboard UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the voice chat interface into a 60fps buttery-smooth experience identical to Messenger and Telegram when opening/closing the keyboard, avoiding jumpy animations, keyboard overlaps, and bottom navigation stutter.

**Architecture:** 
1. Adopt the industry-standard `reverse: true` scroll architecture for chat messages where index 0 is anchored to the bottom viewport.
2. Replace abrupt `null` unmounting of `bottomNavigationBar` in `MainNavigationScreen` with smooth animated transition (`AnimatedContainer` + `AnimatedSlide` or keyboard-aware wrapper).
3. Connect native `keyboardDismissBehavior: onDrag` with intuitive tap-to-dismiss `GestureDetector` and zero-delay anchor syncing.

**Tech Stack:** Flutter 3.32+, Material 3, `flutter_bloc`, `Cubit`.

**Spec:** `docs/superpowers/specs/2026-10-21-lingua-local-ai-design.md`

## Global Constraints

- Clean Architecture layers must remain untouched.
- All 19 unit & widget tests must continue to pass.
- Flutter analyze must maintain 0 warnings/errors.
- Response in concise natural Vietnamese.

## Review Focus

1. **Reversed list index mapping:** Index 0 is the most recent message; oldest message is at index `messages.length - 1`. Verify message order visually and logically.
2. **Keyboard pop-up anchor:** When keyboard rises, latest messages must remain visible directly above the input bar with 0 frame drops and no jumping.
3. **Empty state centering:** When there are no messages, the welcome hero card must remain properly centered and not inverted.
4. **Bottom bar transition:** The bottom navigation bar must disappear/appear smoothly without causing layout jerk or flashing.
5. **Dismiss behavior:** Dragging down on the list or tapping background smoothly dismisses keyboard without losing scroll position.

---

### Task 1: Convert `VoiceChatScreen` to `reverse: true` (Messenger/Telegram Architecture)

**Files:**
- Modify: `d:/app/lib/features/voice_chat/presentation/views/voice_chat_screen.dart`
- Test: `d:/app/test/features/voice_chat/presentation/views/voice_chat_keyboard_test.dart` (or `voice_chat_cubit_test.dart`)

- [ ] **Step 1:** In `voice_chat_screen.dart`, configure `ListView.builder` with `reverse: true`.
- [ ] **Step 2:** Map `itemBuilder` so `index 0` renders the latest message (`state.messages[state.messages.length - 1 - index]`), preserving chronological visual flow from top (old) to bottom (new).
- [ ] **Step 3:** Update `_scrollToBottom()` to simply animate to `0.0` (`_scrollController.animateTo(0.0, ...)`), eliminating dependency on unstable `maxScrollExtent` during keyboard transitions.
- [ ] **Step 4:** Keep `_buildWelcomeHero` non-reversed when `state.messages.isEmpty`.
- [ ] **Step 5:** Run `flutter test` and confirm no regressions.

---

### Task 2: Smooth Bottom Navigation Bar Animation in `MainNavigationScreen`

**Files:**
- Modify: `d:/app/lib/features/home/presentation/views/main_navigation_screen.dart`
- Test: `d:/app/test/widget_test.dart`

- [ ] **Step 1:** In `main_navigation_screen.dart`, replace the abrupt `isKeyboardOpen ? null : NavigationBar(...)` with a smooth animated transition (`AnimatedContainer` / `AnimatedSlide` / height clip) so the layout does not re-build with jarring height pops.
- [ ] **Step 2:** Ensure `resizeToAvoidBottomInset: true` is retained so the outer Scaffold cleanly shrinks the body above the keyboard.
- [ ] **Step 3:** Verify widget tests in `test/widget_test.dart` still locate all 3 destinations without error.

---

### Task 3: Input Bar & Keyboard Dismiss UX Polish

**Files:**
- Modify: `d:/app/lib/features/voice_chat/presentation/views/voice_chat_screen.dart`

- [ ] **Step 1:** Verify `focusNode: _focusNode` is linked to `TextField`.
- [ ] **Step 2:** Ensure `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` is active on `ListView.builder`.
- [ ] **Step 3:** Wrap the message viewport in `GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => FocusScope.of(context).unfocus())` to dismiss on background tap.
- [ ] **Step 4:** Set `textInputAction: TextInputAction.send` on `TextField` for smooth keyboard enter-to-send action.

---

### Task 4: Verification and Quality Gate

**Files:**
- Run static checks and test suite:
  - `flutter analyze`
  - `flutter test`

- [ ] **Step 1:** Run `flutter analyze` and confirm 0 issues.
- [ ] **Step 2:** Run `flutter test` and confirm all 19 tests pass.
- [ ] **Step 3:** Validate on emulator that tapping text field keeps the latest message cleanly docked right above the input bar with zero jumpiness.
