import 'package:blind_diary/view/page_list/menu_view/chatpage/chatroompage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .orderBy('lastTimestamp', descending: true) // 최신 메시지 정렬
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('채팅 목록을 불러올 수 없습니다.'));
        }

        final chatRooms = snapshot.data!.docs;

        if (chatRooms.isEmpty) {
          return const Center(child: Text('현재 진행 중인 채팅이 없습니다.'));
        }

        return ListView.separated(
          itemCount: chatRooms.length,
          separatorBuilder: (context, index) => const Divider(height: 1), // 구분선 추가
          itemBuilder: (context, index) {
            final chatRoom = chatRooms[index];
            final chatData = chatRoom.data() as Map<String, dynamic>;
            final recipientNickname = chatData['recipientNickname'] ?? '알 수 없음';
            final recipientGender = chatData['recipientGender'] ?? '알 수 없음'; // 성별 정보 추가
            final chatRoomId = chatRoom.id;
            final lastMessage = chatData['lastMessage'] ?? '메시지가 없습니다.';
            final lastTimestamp = chatData['lastTimestamp'] as Timestamp?;

            // 마지막 메시지 시간 포맷팅
            final formattedTime = lastTimestamp != null
                ? _formatTimestamp(lastTimestamp)
                : '시간 없음';

            // 성별 아이콘 설정
            final genderIcon = recipientGender == '남성'
                ? '\u2642' // 남성 기호
                : '\u2640'; // 여성 기호
            final genderColor =
            recipientGender == '남성' ? Colors.blue : Colors.pink;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .where('isRead', isEqualTo: false) // 읽지 않은 메시지만 필터링
                  .where('senderId', isNotEqualTo: user.uid) // 상대방이 보낸 메시지만
                  .snapshots(),
              builder: (context, unreadSnapshot) {
                int unreadCount = 0;
                if (unreadSnapshot.hasData) {
                  unreadCount = unreadSnapshot.data!.docs.length;
                }

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: genderColor.withOpacity(0.2),
                        child: Text(
                          genderIcon,
                          style: TextStyle(
                            fontSize: 24,
                            color: genderColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) // 읽지 않은 메시지가 있는 경우
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    recipientNickname,
                    style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        formattedTime,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomPage(
                          chatRoomId: chatRoomId,
                          recipientNickname: recipientNickname,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// 타임스탬프를 '오전/오후 HH:mm' 형식으로 변환
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final isAm = hour < 12;
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${isAm ? '오전' : '오후'} $formattedHour:$minute';
  }
}