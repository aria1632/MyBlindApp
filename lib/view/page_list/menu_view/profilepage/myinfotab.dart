import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyInfoTab extends StatelessWidget {
  final VoidCallback onLogout;

  const MyInfoTab({super.key, required this.onLogout});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 성공!')),
      );
      onLogout(); // 로그아웃 성공 시 상태 업데이트
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: ${e}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('사용자 정보를 불러올 수 없습니다.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이름: ${user.displayName ?? '알 수 없음'}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('이메일: ${user.email}', style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Center(
            child: ElevatedButton(
              onPressed: () => _logout(context),
              child: const Text('로그아웃'),
            ),
          ),
        ],
      ),
    );
  }
}