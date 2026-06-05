// models/chat_message.dart
// โมเดลข้อความในแชท — แก้ตรงนี้ถ้าอยากเพิ่ม field เช่น timestamp, type

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({
    required this.text,
    required this.isUser,
  });
}
