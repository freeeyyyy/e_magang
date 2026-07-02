enum SenderRole { siswa, admin }

class ChatMessage {
  final String id;
  final String siswaId; // Room identifier (per siswa)
  final String senderId;
  final SenderRole senderRole;
  final String message;
  final DateTime timestamp;
  bool isRead;

  ChatMessage({
    required this.id,
    required this.siswaId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}
