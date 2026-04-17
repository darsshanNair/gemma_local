# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

### Linting
- `flutter analyze` – run static analysis with the lint rules defined in `analysis_options.yaml`

## Project Architecture

Gemma Local is a Flutter app that runs an LLM fully on-device using the `flutter_gemma` package.

### Directory Structure
```
lib/
├── core/
│   ├── models/
│   │   └── chat_message.dart        # ChatMessage model (text, isUser, isError)
│   ├── services/
│   │   ├── i_model_service.dart     # IModelService interface
│   │   └── model_service.dart       # ModelService – initializes flutter_gemma, creates inference model
│   └── utilities/
│       └── constants/
│           └── app_constants.dart   # HF_TOKEN (from environment), modelUrl, systemInstruction, maxTokens
├── presentation/
│   ├── gemma_local_app.dart         # App root widget
│   ├── screens/
│   │   └── chat_screen.dart         # Main chat UI and streaming inference logic
│   ├── widgets/
│   │   ├── chat_bubble.dart         # Message bubble
│   │   ├── send_button.dart         # Send button
│   │   └── typing_indicator.dart    # Loading indicator
│   └── theme/
│       └── app_colors.dart          # Color palette
└── main.dart                        # Entry point, initializes ModelService
```

### Key Components

**ModelService** (`lib/core/services/model_service.dart`)
- Initializes `FlutterGemma` with HuggingFace token and downloads model from `modelUrl`
- Creates and configures `InferenceModel` with `maxTokens` and `systemInstruction`
- Uses CPU backend in debug mode, GPU otherwise

**ChatScreen** (`lib/presentation/screens/chat_screen.dart`)
- Manages chat messages list and streaming state
- Calls `ModelService` to create model and chat session
- Handles token-by‑token streaming via `generateChatResponseAsync`
- Updates UI with progressive text replacement

**AppConstants** (`lib/core/utilities/constants/app_constants.dart`)
- `HF_TOKEN` is read from compile‑time environment (`String.fromEnvironment`)
- `modelUrl` points to the HuggingFace model file (currently Qwen2.5‑0.5B‑Instruct)
- `systemInstruction` and `maxTokens` shape the model’s behavior

## Configuration

### On-device Model
- Currently `modelUrl` points to a Qwen2.5‑0.5B‑Instruct model, and `modelType` is set to `ModelType.qwen` in `AppConstants.modelType`.
- Change `modelUrl` and `modelType` (in `ModelService.init`) to use a different model supported by `flutter_gemma`. See the package documentation for supported models.
- The `systemInstruction` is set to “You are a helpful assistant.” to discourage markdown in responses.
- Change `systemInstruction` to specify the model's context to be more specific or to add guardrails.

## Development Workflow

For development workflow and Git practices, see [claude_docs/Workflow.md](claude_docs/Workflow.md).

## Flutter-specific Instructions

For additional instructions specific to Flutter-based projects, see  [claude_docs/Flutter.md](claude_docs/Flutter.md).

## Flutter version

Uses FVM with Flutter 3.41.6 (stable channel). The `flutter_gemma` package requires SDK >=3.10.7.

## Notes

- The model file is downloaded on first launch (~500 MB) and cached on the device.
- The app does not require an internet connection at inference time.
- On emulators the CPU backend is used automatically; responses will be slower than on a physical device with GPU.