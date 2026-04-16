import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:gemma_local/core/models/chat_message.dart';
import 'package:gemma_local/core/services/model_service.dart';
import 'package:gemma_local/core/utilities/constants/app_constants.dart';
import 'package:gemma_local/presentation/theme/app_colors.dart';
import 'package:gemma_local/presentation/widgets/chat_bubble.dart';
import 'package:gemma_local/presentation/widgets/send_button.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title});

  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // --- Services & Model ---
  final ModelService _modelService = ModelService();
  InferenceModel? _model;
  InferenceChat? _chat;

  // --- UI State ---
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isModelReady = false;
  bool _isResponding = false;
  String _statusText = 'Setting up model...';

  // --- Streaming buffer ---
  String _streamBuffer = '';

  @override
  void initState() {
    super.initState();
    _setupModel();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _modelService.closeModel();
    super.dispose();
  }

  Future<void> _setupModel() async {
    try {
      setState(() => _statusText = 'Loading model...');

      _model = await _modelService.createAndSetupModel(
        AppConstants.maxTokens,
        AppConstants.systemInstruction,
      );

      _chat = await _model!.createChat(
        systemInstruction: AppConstants.systemInstruction,
      );

      setState(() {
        _isModelReady = true;
        _statusText = 'Ready';
      });
    } catch (e) {
      setState(() => _statusText = 'Error: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || !_isModelReady || _isResponding) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isResponding = true;
      _streamBuffer = '';
      _inputController.clear();
    });

    _scrollToBottom();

    // Add a placeholder for the assistant's streaming response
    setState(() {
      _messages.add(ChatMessage(text: '', isUser: false));
    });

    try {
      await _chat!.addQueryChunk(Message.text(text: text, isUser: true));

      _chat!.generateChatResponseAsync().listen(
        (ModelResponse response) {
          if (response is TextResponse) {
            _streamBuffer += response.token;
            _streamBuffer = _streamBuffer.replaceAll('\\n', '\n');

            setState(() {
              _messages.last = ChatMessage(text: _streamBuffer, isUser: false);
            });
            _scrollToBottom();
          }
        },
        onDone: () {
          setState(() {
            _messages.last = ChatMessage(
              text: _streamBuffer.trim(),
              isUser: false,
            );
            _isResponding = false;
          });
        },
        onError: (error) {
          setState(() {
            _messages.last = ChatMessage(
              text: 'Error generating response.',
              isUser: false,
              isError: true,
            );
            _isResponding = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _messages.last = ChatMessage(
          text: 'Something went wrong: $e',
          isUser: false,
          isError: true,
        );
        _isResponding = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isModelReady ? AppColors.green : AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: _isModelReady ? AppColors.green : AppColors.amber,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.auto_awesome, size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          const Text(
            'On-device AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Running fully on your device. No internet needed.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: _isModelReady && !_isResponding,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: _isModelReady
                    ? 'Type a message...'
                    : 'Waiting for model...',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SendButton(
            enabled: _isModelReady && !_isResponding,
            onTap: _sendMessage,
          ),
        ],
      ),
    );
  }
}
