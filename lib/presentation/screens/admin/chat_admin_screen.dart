import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/data/datasources/shared_data_store.dart';
import 'package:emagang_app/data/models/chat_model.dart';
import 'package:emagang_app/presentation/providers/admin_provider.dart';

/// Daftar inbox pesan dari semua siswa untuk admin
class ChatAdminScreen extends StatefulWidget {
  const ChatAdminScreen({super.key});

  @override
  State<ChatAdminScreen> createState() => _ChatAdminScreenState();
}

class _ChatAdminScreenState extends State<ChatAdminScreen> {
  final _store = SharedDataStore.instance;

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final siswaList = admin.daftarSiswa;

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Pesan Siswa'),
      ),
      body: siswaList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: siswaList.length,
              itemBuilder: (ctx, i) {
                final siswa = siswaList[i];
                final messages = _store.getMessages(siswa.id);
                final unread = _store.unreadCount(siswa.id, SenderRole.admin);
                final lastMsg = messages.isNotEmpty ? messages.last : null;

                return _buildInboxItem(context, siswa, lastMsg, unread);
              },
            ),
    );
  }

  Widget _buildInboxItem(
    BuildContext context,
    SiswaAdminData siswa,
    ChatMessage? lastMsg,
    int unread,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailAdminScreen(siswa: siswa),
            ),
          ).then((_) => setState(() {}));
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                    child: Text(
                      siswa.nama[0].toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                        child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            siswa.nama,
                            style: TextStyle(
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (lastMsg != null)
                          Text(
                            DateFormat('HH:mm').format(lastMsg.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: unread > 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      siswa.nis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMsg != null
                          ? '${lastMsg.senderRole == SenderRole.admin ? "Anda: " : ""}${lastMsg.message}'
                          : 'Belum ada pesan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: unread > 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
                        fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail chat admin dengan 1 siswa
class ChatDetailAdminScreen extends StatefulWidget {
  final SiswaAdminData siswa;
  const ChatDetailAdminScreen({super.key, required this.siswa});

  @override
  State<ChatDetailAdminScreen> createState() => _ChatDetailAdminScreenState();
}

class _ChatDetailAdminScreenState extends State<ChatDetailAdminScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _store = SharedDataStore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _store.markAsRead(widget.siswa.id, SenderRole.admin);
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

    _store.sendMessage(ChatMessage(
      id: 'msg_admin_${DateTime.now().millisecondsSinceEpoch}',
      siswaId: widget.siswa.id,
      senderId: 'admin',
      senderRole: SenderRole.admin,
      message: text,
      timestamp: DateTime.now(),
      isRead: false,
    ));

    _ctrl.clear();
    setState(() {});
    _scrollToBottom();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  @override
  Widget build(BuildContext context) {
    final messages = _store.getMessages(widget.siswa.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(widget.siswa.nama[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.siswa.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('NIS: ${widget.siswa.nis}', style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Belum ada pesan dari siswa ini.', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isAdmin = msg.senderRole == SenderRole.admin;
                      bool showDate = i == 0 || !_sameDay(messages[i - 1].timestamp, msg.timestamp);
                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(msg.timestamp),
                          _buildBubble(msg, isAdmin),
                        ],
                      );
                    },
                  ),
          ),
          // Input
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
                      hintText: 'Balas ${widget.siswa.nama.split(' ').first}...',
                      filled: true,
                      fillColor: const Color(0xFFF0F2F8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.35), blurRadius: 8)],
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

  Widget _buildDateSeparator(DateTime dt) {
    final isToday = _sameDay(dt, DateTime.now());
    final label = isToday ? 'Hari Ini' : DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
        const Expanded(child: Divider()),
      ]),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAdmin) ...[
            CircleAvatar(radius: 14,
                backgroundColor: AppTheme.accentColor.withOpacity(0.15),
                child: Text(widget.siswa.nama[0],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor))),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAdmin ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isAdmin ? 18 : 4),
                      bottomRight: Radius.circular(isAdmin ? 4 : 18),
                    ),
                  ),
                  child: Text(msg.message,
                      style: TextStyle(color: isAdmin ? Colors.white : AppTheme.textPrimary, fontSize: 13)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(DateFormat('HH:mm').format(msg.timestamp),
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 6),
            const CircleAvatar(radius: 14,
                backgroundColor: Colors.white,
                child: Icon(Icons.support_agent_rounded, size: 16, color: AppTheme.primaryColor)),
          ],
        ],
      ),
    );
  }
}
