import 'package:blind_diary/view/page_list/menu_view/homepage/postdetailpage.dart';
import 'package:blind_diary/view/page_list/menu_view/homepage/writepostpage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      debugPrint('게시글 삭제 성공: $postId');
    } catch (e) {
      debugPrint('게시글 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
          }

          final posts = snapshot.data?.docs ?? [];

          if (posts.isEmpty) {
            return const Center(child: Text('게시글이 없습니다.'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postData = post.data() as Map<String, dynamic>;
              final postId = post.id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(postId: postId),
                    ),
                  );
                },
                child: Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    children: [
                      // 성별 기호 표시
                      Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            postData['gender'] == '남성'
                                ? '\u2642'
                                : '\u2640', // 남성(♂), 여성(♀) 기호
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: postData['gender'] == '남성'
                                  ? Colors.blue
                                  : Colors.pink, // 색상
                            ),
                          ),
                        ),
                      ),
                      // 내용 표시
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                postData['content'] ?? '내용 없음',
                                maxLines: 3, // 최대 3줄까지만 표시
                                overflow: TextOverflow.ellipsis, // 3줄 이상일 경우 생략
                                style: const TextStyle(fontSize: 19),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '작성자: ${postData['nickname'] ?? '알 수 없음'}',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.grey),
                              ),
                              Text(
                                postData['timestamp'] != null
                                    ? (postData['timestamp'] as Timestamp)
                                    .toDate()
                                    .toString()
                                    .split(' ')[0]
                                    : '날짜 없음',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 삭제 버튼 (작성자 본인만 표시)
                      if (user != null && postData['authorId'] == user.uid)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('삭제 확인'),
                                content: const Text('이 게시글을 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _deletePost(postId);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WritePostPage()),
          );
        },
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
      ),
    );
  }
}