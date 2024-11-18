import 'package:blind_diary/view/page_list/join_login/loginpage_profile.dart';
import 'package:blind_diary/view/page_list/menu_view/profilepage/mycommentstab.dart';
import 'package:blind_diary/view/page_list/menu_view/profilepage/myinfotab.dart';
import 'package:blind_diary/view/page_list/menu_view/profilepage/mypoststab.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../join_login/singuppage_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 여유로운 상단 공간
          Container(
            height: 80, // 상단 여백 크기
            alignment: Alignment.center,
            color: Colors.grey[200], // 선택 사항: 배경색 설정

          ),
          // TabBar
          Container(
            color: Colors.grey[200],
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '내 글'),
                Tab(text: '내 댓글'),
                Tab(text: '내 정보'),
              ],
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoggedIn
                    ? const MyPostsTab() // 내 글 탭
                    : _buildLoginPrompt(context), // 로그아웃 상태에서 로그인 화면 표시
                _isLoggedIn
                    ? const MyCommentsTab() // 내 댓글 탭
                    : _buildLoginPrompt(context), // 로그아웃 상태에서 로그인 화면 표시
                _isLoggedIn
                    ? MyInfoTab(onLogout: _handleLogout) // 내 정보 탭
                    : _buildLoginPrompt(context), // 로그아웃 상태에서 로그인 화면 표시
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('로그인이 필요합니다.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(
                        onLoginSuccess: _onLoginSuccess, // 로그인 성공 시 콜백
                      ),
                    ),
                  );
                },
                child: const Text('로그인'),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignUpPage(),
                  ),
                );
              },
              child: const Text('회원가입하기', style: TextStyle(color: Colors.blue)),
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }
}