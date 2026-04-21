import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../../../core/theme/ibis_colors.dart';
import '../../../core/widgets/ibis_app_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
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
    final c = IbisColors.of(context);
    return BlocProvider(
      create: (_) => ChatBloc(),
      child: Builder(builder: (ctx) {
        final bloc = ctx.read<ChatBloc>();
        return Scaffold(
          backgroundColor: c.pageBg,
          extendBodyBehindAppBar: true,
          appBar: IbisAppBar(
            title: 'AI Asistan',
            accentColor: const Color(0xFF7C4DFF),
            leading: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF42A5F5)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 16),
                ),
              ],
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
                    final isLoading = state is ChatMessagesState && state.isLoading;

                    if (messages.isEmpty && !isLoading) {
                      return _WelcomeHint();
                    }
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.fromLTRB(
                          16,
                          MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                          16,
                          12),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == messages.length) return _TypingBubble();
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
  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    final hints = [
      'Soğuk zincir ihlali nedir?',
      'Batch nasıl oluştururum?',
      'QR kod nasıl taranır?',
      'Blockchain kaydı neden önemli?',
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + kToolbarHeight + 32,
          20,
          20),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                    blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 20),
          Text('IbisSupply AI Asistan',
              style: TextStyle(color: c.text, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Gıda tedarik zinciri, platform kullanımı\nve gıda güvenliği konularında yardımcı olurum.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: hints.map((h) => _HintChip(text: h)).toList(),
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
    final c = IbisColors.of(context);
    return GestureDetector(
      onTap: () => context.read<ChatBloc>().add(SendChatMessage(text)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFEEF4FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF42A5F5).withValues(alpha: 0.35)),
        ),
        child: Text(text,
            style: const TextStyle(color: Color(0xFF1976D2), fontSize: 12)),
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
    final c = IbisColors.of(context);
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF42A5F5)]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF1565C0)
                    : c.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: c.border),
                boxShadow: isUser || c.isDark
                    ? []
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : c.text,
                  fontSize: 14, height: 1.45,
                ),
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
  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
                bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: c.border),
            ),
            child: SizedBox(
              width: 32, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: c.textMuted),
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
    final c = IbisColors.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.95),
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: TextStyle(color: c.text, fontSize: 14),
                  maxLines: 4, minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Bir şey sor...',
                    hintStyle: TextStyle(color: c.textDisabled, fontSize: 14),
                    filled: true,
                    fillColor: c.inputFill,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF7C4DFF), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (_, state) {
                  final loading = state is ChatMessagesState && state.isLoading;
                  return GestureDetector(
                    onTap: loading ? null : onSend,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: loading
                              ? [Colors.grey.withValues(alpha: 0.3),
                                 Colors.grey.withValues(alpha: 0.2)]
                              : const [Color(0xFF7C4DFF), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
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
