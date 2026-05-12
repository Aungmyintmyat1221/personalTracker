import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../service/groq_ai_service.dart';
import '../theme/app_theme.dart';

class AiView extends StatefulWidget {
  const AiView({super.key});

  @override
  State<AiView> createState() => _AiViewState();
}

class _AiViewState extends State<AiView> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController apiKeyController = TextEditingController();
  final List<_AiMessage> messages = [
    const _AiMessage(
      text:
          'Ask me about your tasks, routines, or money. Add your Groq API key first.',
      isUser: false,
    ),
  ];
  bool isLoading = false;
  bool hasApiKey = false;
  AiAnswerMode selectedMode = AiAnswerMode.tracker;

  final List<String> trackerSuggestions = const [
    'Plan my day from my tracker',
    'What task should I do next?',
    'Give me money advice for this month',
    'Improve my next routine',
  ];
  final List<String> globalSuggestions = const [
    'What is the crypto market today?',
    'Top world news today',
    'Explain inflation simply',
    'What should I learn about AI?',
  ];
  final List<String> englishSuggestions = const [
    'Give me one speaking lesson for today',
    'Practice small talk with me',
    'Correct my English: I am go to work',
    'Teach me 10 useful daily phrases',
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    messageController.dispose();
    apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                children: [
                  _apiKeyCard(),
                  const SizedBox(height: 16),
                  _modeSelector(),
                  const SizedBox(height: 16),
                  _suggestions(),
                  const SizedBox(height: 16),
                  ...messages.map(_messageBubble),
                  if (isLoading) _loadingBubble(),
                ],
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _apiKeyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasApiKey ? Icons.lock_outline : Icons.key_outlined,
                color: hasApiKey ? AppTheme.teal : AppTheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasApiKey ? 'Groq key saved' : 'Groq API Key',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: hasApiKey ? 'Paste a new key to replace' : 'gsk_...',
              prefixIcon: const Icon(Icons.password_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveApiKey,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Key'),
                ),
              ),
              if (hasApiKey) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Remove key',
                  onPressed: _clearApiKey,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestions() {
    final suggestions = switch (selectedMode) {
      AiAnswerMode.tracker => trackerSuggestions,
      AiAnswerMode.global => globalSuggestions,
      AiAnswerMode.english => englishSuggestions,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((text) {
        return ActionChip(
          avatar: const Icon(Icons.auto_awesome, size: 18),
          label: Text(text),
          onPressed: isLoading ? null : () => _send(text),
        );
      }).toList(),
    );
  }

  Widget _modeSelector() {
    return SegmentedButton<AiAnswerMode>(
      segments: const [
        ButtonSegment(
          value: AiAnswerMode.tracker,
          label: Text('Tracker'),
          icon: Icon(Icons.insights_outlined),
        ),
        ButtonSegment(
          value: AiAnswerMode.global,
          label: Text('Global'),
          icon: Icon(Icons.public_outlined),
        ),
        ButtonSegment(
          value: AiAnswerMode.english,
          label: Text('English'),
          icon: Icon(Icons.record_voice_over_outlined),
        ),
      ],
      selected: {selectedMode},
      onSelectionChanged: isLoading
          ? null
          : (value) => setState(() => selectedMode = value.first),
    );
  }

  Widget _messageBubble(_AiMessage message) {
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.isUser ? AppTheme.ink : Colors.white;
    final textColor = message.isUser ? Colors.white : AppTheme.ink;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: premiumCard(color: color),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: 16, height: 1.45),
        ),
      ),
    );
  }

  Widget _loadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: premiumCard(),
        child: const Text(
          'Thinking...',
          style: TextStyle(color: AppTheme.muted),
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(messageController.text),
              decoration: InputDecoration(
                hintText: selectedMode == AiAnswerMode.tracker
                    ? 'Ask about your tracker...'
                    : selectedMode == AiAnswerMode.global
                    ? 'Ask global news, crypto, or knowledge...'
                    : 'Practice English speaking...',
                prefixIcon: const Icon(Icons.chat_bubble_outline),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: isLoading ? null : () => _send(messageController.text),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Future<void> _loadApiKey() async {
    final key = await GroqAiService.readApiKey();
    if (!mounted) return;
    setState(() => hasApiKey = key != null && key.isNotEmpty);
  }

  Future<void> _saveApiKey() async {
    final key = apiKeyController.text.trim();
    if (key.isEmpty) return;
    await GroqAiService.saveApiKey(key);
    apiKeyController.clear();
    if (!mounted) return;
    setState(() => hasApiKey = true);
    Get.snackbar('Saved', 'Groq API key saved on this device.');
  }

  Future<void> _clearApiKey() async {
    await GroqAiService.clearApiKey();
    if (!mounted) return;
    setState(() => hasApiKey = false);
    Get.snackbar('Removed', 'Groq API key removed.');
  }

  Future<void> _send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || isLoading) return;

    messageController.clear();
    setState(() {
      isLoading = true;
      messages.add(_AiMessage(text: text, isUser: true));
    });

    try {
      final reply = await GroqAiService.ask(text, mode: selectedMode);
      if (!mounted) return;
      setState(() => messages.add(_AiMessage(text: reply, isUser: false)));
    } on GroqAiException catch (error) {
      if (!mounted) return;
      setState(
        () => messages.add(_AiMessage(text: error.message, isUser: false)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        messages.add(
          const _AiMessage(
            text:
                'Something went wrong. Check your API key and internet connection.',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

class _AiMessage {
  final String text;
  final bool isUser;

  const _AiMessage({required this.text, required this.isUser});
}
