import 'package:flutter/material.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final TextEditingController _messageController = TextEditingController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hi Aamir! 👋 I\'m UniFlow AI. I can help you understand topics, summarize notes, create quizzes, and plan your studies.',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          text: message,
          isUser: true,
        ),
      );

      _messages.add(
        const _ChatMessage(
          text:
              'That\'s a great question! 🤖 This is currently a demo response. Soon, UniFlow AI will connect to a real AI service to provide intelligent answers.',
          isUser: false,
        ),
      );
    });

    _messageController.clear();
  }

  void _useQuickAction(String action) {
    setState(() {
      _messages.add(
        _ChatMessage(
          text: action,
          isUser: true,
        ),
      );

      _messages.add(
        _ChatMessage(
          text: _getDemoResponse(action),
          isUser: false,
        ),
      );
    });
  }

  String _getDemoResponse(String action) {
    switch (action) {
      case 'Explain a topic':
        return 'Sure! 📚 Tell me the topic you want explained, and I\'ll break it down into simple steps with examples.';

      case 'Summarize notes':
        return 'Absolutely! 📝 Upload or paste your notes, and I\'ll create a concise summary highlighting the important points.';

      case 'Generate a quiz':
        return 'Let\'s test your knowledge! 🧠 Give me a course or topic, and I\'ll generate practice questions for you.';

      case 'Create study plan':
        return 'I can help you create a study plan. 📅 Tell me your subjects, exam dates, and available study time.';

      default:
        return 'How can I help you with your studies today?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UniFlow AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your intelligent academic assistant',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick actions
        SizedBox(
          height: 46,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: [
              _QuickAction(
                icon: Icons.menu_book_rounded,
                label: 'Explain a topic',
                onTap: () => _useQuickAction('Explain a topic'),
              ),
              _QuickAction(
                icon: Icons.summarize_rounded,
                label: 'Summarize notes',
                onTap: () => _useQuickAction('Summarize notes'),
              ),
              _QuickAction(
                icon: Icons.quiz_rounded,
                label: 'Generate a quiz',
                onTap: () => _useQuickAction('Generate a quiz'),
              ),
              _QuickAction(
                icon: Icons.calendar_month_rounded,
                label: 'Create study plan',
                onTap: () => _useQuickAction('Create study plan'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Chat
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];

              return _MessageBubble(
                message: message.text,
                isUser: message.isUser,
              );
            },
          ),
        ),

        // Input
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ask UniFlow AI...',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 54,
                  width: 54,
                  child: FilledButton(
                    onPressed: _sendMessage,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 17,
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isUser,
  });

  final String message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF2563EB)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: isUser ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}