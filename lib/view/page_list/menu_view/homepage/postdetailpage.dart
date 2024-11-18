import 'package:blind_diary/view/page_list/menu_view/chatpage/chatroompage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();

  /// 댓글 추가 기능
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'content': _commentController.text.trim(),
      'authorId': user.uid,
      'nickname': userData?['nickname'] ?? '알 수 없음',
      'gender': userData?['gender'] ?? '알 수 없음', // 성별 추가
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  /// 댓글 삭제 기능
  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 삭제 실패!')),
      );
    }
  }

  /// 채팅 화면으로 이동
  Future<void> _navigateToChat(String authorId, String nickname) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid == authorId) {
      return;
    }

    final chatRoomId = user.uid.compareTo(authorId) < 0
        ? '${user.uid}_$authorId'
        : '${authorId}_${user.uid}';

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'participants': [user.uid, authorId],
      'recipientNickname': nickname,
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(chatRoomId: chatRoomId, recipientNickname: nickname),
      ),
    );
  }

  /// 채팅 시도 확인 팝업
  void _showChatConfirmationDialog(String authorId, String nickname) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅 요청'),
        content: const Text('채팅을 시도하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToChat(authorId, nickname);
            },
            child: const Text('예'),
          ),
        ],
      ),
    );
  }

  /// 성별에 따른 아이콘 반환
  Widget _buildGenderIcon(String? gender) {
    if (gender == '남성') {
      return const Text(
        '♂️',
        style: TextStyle(fontSize: 24, color: Colors.blue),
      );
    } else if (gender == '여성') {
      return const Text(
        '♀️',
        style: TextStyle(fontSize: 24, color: Colors.pink),
      );
    } else {
      return const Icon(Icons.person, size: 24, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
      ),
      body: Column(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('posts').doc(widget.postId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('게시글 정보를 불러올 수 없습니다.'));
              }

              final postData = snapshot.data!.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (postData['authorId'] != null && postData['nickname'] != null) {
                                _showChatConfirmationDialog(postData['authorId'], postData['nickname']);
                              }
                            },
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[200],
                              child: _buildGenderIcon(postData['gender']),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  postData['nickname'] ?? '알 수 없음',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  postData['timestamp'] != null
                                      ? (postData['timestamp'] as Timestamp)
                                      .toDate()
                                      .toString()
                                      .split(' ')[0]
                                      : '날짜 없음',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        postData['content'] ?? '내용 없음',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          // 댓글 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('댓글을 불러올 수 없습니다.'));
                }

                final comments = snapshot.data!.docs;
                final user = FirebaseAuth.instance.currentUser;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data() as Map<String, dynamic>;
                    final commentId = comments[index].id;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: _buildGenderIcon(comment['gender']),
                      ),
                      title: Text(comment['content'] ?? '내용 없음'),
                      subtitle: Text('작성자: ${comment['nickname'] ?? '알 수 없음'}'),
                      trailing: user != null && user.uid == comment['authorId']
                          ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteComment(commentId),
                      )
                          : null,
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
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: '댓글을 입력하세요.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}