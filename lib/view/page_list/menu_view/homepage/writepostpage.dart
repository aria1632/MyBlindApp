import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WritePostPage extends StatefulWidget {
  const WritePostPage({super.key});

  @override
  State<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _savePost() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw '로그인 상태를 확인할 수 없습니다.';
        }

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        await FirebaseFirestore.instance.collection('posts').add({
          'content': _contentController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'authorId': user.uid,
          'nickname': userData?['nickname'] ?? '알 수 없음',
          'gender': userData?['gender'] ?? '알 수 없음', // 성별 추가
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('글이 저장되었습니다.')),
        );
        Navigator.pop(context); // 홈 화면으로 돌아가기
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('글 저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글쓰기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty ? '내용을 입력하세요.' : null,
                decoration: const InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _savePost,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}