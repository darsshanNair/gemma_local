# Fix: Turn-based conversation loop for categorization

**Date**: 2026-05-13
**Branch**: `feature/llm-categorization`

## Problem

`_handleToolCall` calls `chat.addQueryChunk()` inside the `await for` loop of `generateChatResponseAsync()`. The native MediaPipe engine rejects this with `IllegalStateException: Previous invocation still processing. Wait for done=true.`

## Solution

Replace the single `await for` with a `while` loop (max 3 turns). Collect function calls during streaming, send tool responses after the stream ends.

### Flow

1. Send initial prompt via `addQueryChunk`
2. `while (turn < 3)`:
   - Stream `generateChatResponseAsync()`
   - Collect `FunctionCallResponse`s in a list (don't call `addQueryChunk` yet)
   - If no function calls received → LLM is done, break
   - Process all collected calls (now safe to call `addQueryChunk`)
   - `turn++`
3. Return `CategorizationResult` with whatever was categorized

### Files modified

- `lib/core/services/todo_categorization_service.dart` — restructure `categorizeGeneralTodos()` only

### No changes to

- `_handleToolCall`, `_sendToolError`, `_parseCategory`, tool builders — all unchanged
- UI layer (`todo_screen.dart`) — unchanged
- All other files — unchanged
