import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// RegisterPage StatefulWidget 클래스 선언
class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

// _RegisterPageState 클래스 선언
class _RegisterPageState extends State<RegisterPage> {
  // FirebaseAuth 인스턴스 생성
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // FirebaseFirestore 인스턴스 생성
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TextEditingController 인스턴스 생성
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // 전화번호 컨트롤러 추가

  // 에러 메시지 저장 변수
  String? _errorMessage;

  // 회원가입 함수
  Future<void> _register() async {
    try {
      // FirebaseAuth를 사용하여 새로운 사용자 생성
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Firestore에 사용자 정보 저장
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text, // 전화번호 필드 추가
      });

      // 회원가입 완료 후 이전 화면으로 이동
      Navigator.pop(context);
    } catch (e) {
      // 에러 발생 시 에러 메시지 설정
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'), // AppBar 제목 설정
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 이름 입력 필드
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // 이메일 입력 필드
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // 비밀번호 입력 필드
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // 비밀번호 입력 시 텍스트 숨김
            ),
            SizedBox(height: 16),

            // 전화번호 입력 필드
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone, // 전화번호 입력 타입 설정
            ),
            SizedBox(height: 16),

            // 에러 메시지 표시
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),

            // 회원가입 버튼
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
