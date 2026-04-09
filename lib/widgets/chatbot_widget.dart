import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chat message model
// ─────────────────────────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser})
      : time = DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating chatbot button — add this as a FAB or inside a Stack
// ─────────────────────────────────────────────────────────────────────────────
class ChatbotFab extends StatelessWidget {
  const ChatbotFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'chatbot_fab',
      backgroundColor: const Color(0xFF2D6A1E),
      shape: const CircleBorder(),
      tooltip: 'SafeRide Assistant',
      onPressed: () => _openChat(context),
      child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
    );
  }

  void _openChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChatModal(),
    );
  }
}

/// Public alias — lets operator screens open the chat modal directly.
class ChatbotFabSheet extends StatelessWidget {
  const ChatbotFabSheet({super.key});
  @override
  Widget build(BuildContext context) => const _ChatModal();
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat modal bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ChatModal extends StatefulWidget {
  const _ChatModal();

  @override
  State<_ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends State<_ChatModal> {
  final ChatbotService _service = ChatbotService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  static const _green = Color(0xFF2D6A1E);
  static const _lightGreen = Color(0xFF4BA028);

  @override
  void initState() {
    super.initState();
    // Greeting
    _messages.add(_ChatMessage(
      text:
          'Hello! I am the SafeRide Assistant 🚌\n\n'
          'I can help you with:\n'
          '• **Safety reporting** (overloading, reckless driving, etc.)\n'
          '• **Technical support** for operators and jeepney owners\n\n'
          'How can I assist you today?',
      isUser: false,
    ));

    // Quick suggestion chips
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await _service.sendMessage(text);

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: _green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SafeRide Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Powered by Gemini AI',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Quick Chips ──────────────────────────────────────────────────
          if (_messages.length == 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Report overloading'),
                    _chip('Sensor not working'),
                    _chip('How to register a jeepney?'),
                    _chip('Report reckless driving'),
                  ],
                ),
              ),
            ),

          // ── Messages ─────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (_isLoading && i == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[i];
                return _buildBubble(msg);
              },
            ),
          ),

          // ── Input ────────────────────────────────────────────────────────
          AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isLoading ? null : () => _send(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey[300] : _lightGreen,
                        shape: BoxShape.circle,
                        boxShadow: _isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: _lightGreen.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _send(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF7EA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2D6A1E).withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF2D6A1E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    const botColor = Color(0xFFF3F8F1);
    const userColor = Color(0xFF2D6A1E);

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? userColor : botColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildMessageText(msg),
      ),
    );
  }

  Widget _buildMessageText(_ChatMessage msg) {
    // Simple bold markdown: **text**
    final text = msg.text;
    final spans = <TextSpan>[];
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            color: msg.isUser ? Colors.white : const Color(0xFF1A1A1A),
            fontSize: 14,
            height: 1.45,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: msg.isUser ? Colors.white : const Color(0xFF1A1A1A),
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          color: msg.isUser ? Colors.white : const Color(0xFF1A1A1A),
          fontSize: 14,
          height: 1.45,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8F1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return _DotPulse(delay: Duration(milliseconds: i * 200));
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated typing dot
// ─────────────────────────────────────────────────────────────────────────────
class _DotPulse extends StatefulWidget {
  final Duration delay;
  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Color(0xFF4BA028),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
