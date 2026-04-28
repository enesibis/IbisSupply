import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../../../core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _accent     = Color(0xFF3F3FE8);
const _accentSoft = Color(0xFFEEEEFE);
const _ink900     = Color(0xFF0A0A0B);
const _ink400     = Color(0xFFA1A1AA);
const _ink300     = Color(0xFFD4D4D8);
const _line200    = Color(0xFFE4E4E7);
const _line100    = Color(0xFFF4F4F5);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(ChatBloc bloc) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    bloc.add(SendChatMessage(text));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(),
      child: Builder(builder: (ctx) {
        final bloc = ctx.read<ChatBloc>();
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text('AI Asistan',
                style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _line200),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (_, state) {
                    if (state is ChatMessagesState) _scrollToBottom();
                  },
                  builder: (_, state) {
                    final messages = state is ChatMessagesState
                        ? state.messages
                        : <ChatMessage>[];
                    final isLoading =
                        state is ChatMessagesState && state.isLoading;

                    if (messages.isEmpty && !isLoading) {
                      return _WelcomeHint();
                    }
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == messages.length) return const _TypingBubble();
                        return _MessageBubble(msg: messages[i]);
                      },
                    );
                  },
                ),
              ),
              _InputBar(ctrl: _inputCtrl, onSend: () => _send(bloc)),
            ],
          ),
        );
      }),
    );
  }
}

// ── Welcome hint ──────────────────────────────────────────────────────────────
class _WelcomeHint extends StatelessWidget {
  static const _hints = [
    'Soğuk zincir ihlali nedir?',
    'Batch nasıl oluştururum?',
    'QR kod nasıl taranır?',
    'Blockchain kaydı neden önemli?',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _accent.withValues(alpha: 0.2)),
            ),
            child: const Icon(LucideIcons.sparkles, color: _accent, size: 28),
          ),
          const SizedBox(height: 20),
          Text('IbisSupply AI Asistan',
              style: AppTheme.sans(fontSize: 18, weight: FontWeight.w600, color: _ink900)),
          const SizedBox(height: 8),
          Text(
            'Gıda tedarik zinciri, platform kullanımı\nve gıda güvenliği konularında yardımcı olurum.',
            textAlign: TextAlign.center,
            style: AppTheme.sans(fontSize: 13, color: _ink400),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _hints.map((h) => _HintChip(text: h)).toList(),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String text;
  const _HintChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ChatBloc>().add(SendChatMessage(text)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _accentSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withValues(alpha: 0.25)),
        ),
        child: Text(text,
            style: AppTheme.sans(fontSize: 12, weight: FontWeight.w500, color: _accent)),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _accentSoft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _accent.withValues(alpha: 0.2)),
              ),
              child: const Icon(LucideIcons.sparkles, color: _accent, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _ink900 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: isUser ? null : Border.all(color: _line200),
                boxShadow: isUser
                    ? []
                    : [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
              ),
              child: Text(
                msg.content,
                style: AppTheme.sans(
                    fontSize: 14,
                    color: isUser ? Colors.white : _ink900),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _accent.withValues(alpha: 0.2)),
            ),
            child: const Icon(LucideIcons.sparkles, color: _accent, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14), topRight: Radius.circular(14),
                bottomRight: Radius.circular(14), bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _line200),
            ),
            child: const SizedBox(
              width: 32, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _ink400),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  const _InputBar({required this.ctrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _line200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: AppTheme.sans(fontSize: 14, color: _ink900),
                  maxLines: 4, minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Bir şey sor...',
                    hintStyle: AppTheme.sans(fontSize: 14, color: _ink300),
                    filled: true,
                    fillColor: _line100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _line200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _accent, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (_, state) {
                  final loading =
                      state is ChatMessagesState && state.isLoading;
                  return GestureDetector(
                    onTap: loading ? null : onSend,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: loading
                            ? _ink900.withValues(alpha: 0.35)
                            : _ink900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.send,
                              color: Colors.white, size: 18),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
