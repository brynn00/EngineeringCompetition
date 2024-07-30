import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// MyPage 클래스: 사용자 기본정보 및 로그아웃 기능을 제공하는 화면
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

// _MyPageState 클래스: MyPage 화면의 상태를 관리
class _MyPageState extends State<MyPage> {
  String? userName;
  String? userEmail;
  String? userPhone;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  // Firestore에서 사용자 정보를 가져오는 함수
  Future<void> fetchUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'];
          userEmail = userDoc['email'];
          userPhone = userDoc['phone'];
        });
      }
    }
  }

  // 로그아웃 함수
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/'); // 로그아웃 후 메인 화면으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (userName != null) Text('Name: $userName', style: TextStyle(fontSize: 18)),
            if (userEmail != null) Text('Email: $userEmail', style: TextStyle(fontSize: 18)),
            if (userPhone != null) Text('Phone: $userPhone', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: logout,
              child: Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
