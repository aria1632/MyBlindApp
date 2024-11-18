import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyCommentsTab extends StatelessWidget {
  const MyCommentsTab({super.key});

  Future<void> _deleteComment(String commentId, String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
      debugPrint('댓글 삭제 성공: $commentId');
    } catch (e) {
      debugPrint('댓글 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('로그인이 필요합니다.'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('comments')
          .where('authorId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('댓글을 불러오는 중 오류가 발생했습니다.'));
        }

        final comments = snapshot.data!.docs;

        if (comments.isEmpty) {
          return const Center(child: Text('작성한 댓글이 없습니다.'));
        }

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final commentData = comment.data() as Map<String, dynamic>;
            final commentId = comment.id;
            final postId = comment.reference.parent.parent!.id; // 상위 문서(post) ID

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(commentData['content'] ?? '내용 없음'),
                subtitle: Text(
                  commentData['timestamp'] != null
                      ? (commentData['timestamp'] as Timestamp).toDate().toString().split(' ')[0]
                      : '날짜 없음',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('삭제 확인'),
                        content: const Text('정말로 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _deleteComment(commentId, postId);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}