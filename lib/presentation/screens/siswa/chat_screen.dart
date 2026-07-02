import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/data/datasources/shared_data_store.dart';
import 'package:emagang_app/data/models/chat_model.dart';
import 'package:emagang_app/presentation/providers/auth_provider.dart';

class ChatSiswaScreen extends StatefulWidget {
  const ChatSiswaScreen({super.key});

  @override
  State<ChatSiswaScreen> createState() => _ChatSiswaScreenState();
}

class _ChatSiswaScreenState extends State<ChatSiswaScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _store = SharedDataStore.instance;

  @override
  void initState() {
    super.initState();
    // Tandai semua pesan admin sebagai sudah dibaca
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _store.markAsRead(_store.activeSiswaId, SenderRole.siswa);
      setState(() {});
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final siswaId = _store.activeSiswaId;
    _store.sendMessage(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      siswaId: siswaId,
      senderId: siswaId,
      senderRole: SenderRole.siswa,
      message: text,
      timestamp: DateTime.now(),
    ));

    _ctrl.clear();
    setState(() {});
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final siswaId = _store.activeSiswaId;
    final messages = _store.getMessages(siswaId);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Admin / Pembimbing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('PT. Media Balai Nusa Astronet', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.success.withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: AppTheme.success, size: 8),
                SizedBox(width: 4),
                Text('Online', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.primaryColor.withOpacity(0.08),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primaryColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chat ini untuk komunikasi seputar kegiatan magang Anda.',
                    style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Belum ada percakapan', style: TextStyle(color: AppTheme.textSecondary)),
                        const Text('Mulai kirim pesan ke admin', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isMe = msg.senderRole == SenderRole.siswa;

                      // Date separator
                      bool showDate = i == 0 ||
                          !_sameDay(messages[i - 1].timestamp, msg.timestamp);

                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(msg.timestamp),
                          _buildBubble(msg, isMe, auth.user?.nama ?? 'Siswa'),
                        ],
                      );
                    },
                  ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  Widget _buildDateSeparator(DateTime dt) {
    final isToday = _sameDay(dt, DateTime.now());
    final label = isToday ? 'Hari Ini' : DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe, String namaKu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              child: const Icon(Icons.support_agent_rounded, size: 16, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 2),
                    child: Text('Admin', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.done_all_rounded, size: 12,
                            color: msg.isRead ? AppTheme.accentColor : AppTheme.textSecondary),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.accentColor.withOpacity(0.15),
              child: Text(namaKu[0].toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
            ),
          ],
        ],
      ),
    );
  }
}
