import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomId;
  final String recipientNickname;

  const ChatRoomPage({
    super.key,
    required this.chatRoomId,
    required this.recipientNickname,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();

  /// 메시지 전송 로직
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messageContent = _messageController.text.trim();
    final chatDocRef =
    FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatDocRef);

      // 메시지 Firestore에 저장 및 채팅방 정보 업데이트
      transaction.set(
        chatDocRef.collection('messages').doc(),
        {
          'senderId': user.uid,
          'content': messageContent,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      if (!chatSnapshot.exists) {
        transaction.set(chatDocRef, {
          'participants': [user.uid, widget.recipientNickname],
          'recipientNickname': widget.recipientNickname,
          'lastMessage': messageContent,
          'lastTimestamp': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.update(chatDocRef, {
          'lastMessage': messageContent,
          'lastTimestamp': FieldValue.serverTimestamp(),
        });
      }
    });

    _messageController.clear();
  }

  /// 타임스탬프 포맷팅
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final isAm = hour < 12;
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${isAm ? '오전' : '오후'} $formattedHour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientNickname),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('메시지를 불러올 수 없습니다.'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                    messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    final timestamp = message['timestamp'] as Timestamp?;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            const CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.person, size: 16),
                            ),
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                isMe ? Colors.blue[100] : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                                  bottomRight: isMe
                                      ? Radius.zero
                                      : const Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['content'] ?? '',
                                    style: const TextStyle(fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                  if (timestamp != null)
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        _formatTimestamp(timestamp),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe)
                            const CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.person, size: 16),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}