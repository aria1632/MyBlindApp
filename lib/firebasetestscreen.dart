import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseTestScreen extends StatelessWidget {
  // Firestore에 데이터를 추가하는 함수
  Future<void> testFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'message': 'Firebase is connected!',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Data added to Firestore successfully!');
    } catch (e) {
      print('Error adding data to Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await testFirestore(); // 버튼 클릭 시 Firestore에 데이터 추가
          },
          child: Text('Test Firebase Connection'),
        ),
      ),
    );
  }
}