# Gemma Local

A Flutter demo app that runs a large language model fully on-device using the [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) package. No internet connection required at inference time.

## Features

- On-device LLM inference via `flutter_gemma`
- Streaming token-by-token responses
- Clean chat UI with typing indicator
- Configurable model and system instructions via `AppConstants`

## Getting Started

### Prerequisites

- Flutter SDK
- A HuggingFace account and access token ([get one here](https://huggingface.co/settings/tokens))
- A physical Android device recommended (emulator works but is slow on CPU)

### Setup

1. Clone the repository
2. Open `lib/core/utilities/constants/app_constants.dart` and fill in your HuggingFace token:

```dart
static const String hfToken = "hf_your_token_here";
```

3. Run `flutter pub get`
4. Run the app — the model will download on first launch (~500MB), then be cached on-device for all subsequent runs

### Switching Models

Any model supported by `flutter_gemma` can be used. Update `modelUrl` and `modelType` in `AppConstants` and `ModelService` accordingly. See the [supported models list](https://pub.dev/packages/flutter_gemma#-supported-models).

## Project Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── i_model_service.dart   # Service interface
│   │   └── model_service.dart     # flutter_gemma integration
│   └── utilities/
│       └── constants/
│           └── app_constants.dart # Token, URL, model config
└── presentation/
    ├── gemma_local_app.dart        # App root
    └── chat_screen.dart            # Chat UI + inference logic
```

## Notes

- The model file is downloaded once and cached on the device. Uninstalling the app will remove it.
- On Android emulators, CPU backend is used automatically. Expect slower responses compared to a physical device with GPU.
- Keep `systemInstruction` set to avoid markdown in responses — most on-device models need to be explicitly told to use plain text.

## Dependencies

- [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) — on-device LLM inference for Flutter
