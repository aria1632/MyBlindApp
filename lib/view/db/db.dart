import 'package:cloud_firestore/cloud_firestore.dart';

void addPost(String gender, String content) {
  FirebaseFirestore.instance.collection('posts').add({
    'gender': gender,
    'content': content,
    'timestamp': FieldValue.serverTimestamp(), // 서버에서 현재 시간 설정
  });
}



void fetchPosts() async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('posts').get();

  // 데이터 출력
  for (var doc in querySnapshot.docs) {
    print(doc.data()); // 각 문서 데이터 출력
  }
}


