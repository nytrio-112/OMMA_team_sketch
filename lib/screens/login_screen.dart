import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_first_app/constants/colors.dart'; // 색상 상수 정의한 곳

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ✅ 입력값 검증
    if (email.isEmpty || password.isEmpty) {
      _showMessage("모든 정보를 입력해주세요");
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage("이메일 형식을 지켜주세요");
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushReplacementNamed(context, '/mypage');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showMessage("사용자 정보를 찾을 수 없습니다. 메인 페이지로 돌아가 회원가입을 진행해주세요.");
      } else if (e.code == 'wrong-password') {
        _showMessage("비밀번호가 틀렸습니다. 비밀번호가 기억나지 않는 경우, 아래 연락처로 문의 바랍니다.");
      } else {
        _showMessage("로그인에 실패했습니다. 다시 시도해주세요.");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmmaColors.pink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 상단: 뒤로가기 + 로고 + 입력 폼 + 버튼
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'OMMA',
                      style: TextStyle(
                        fontFamily: 'OmmaLogoFont', // 폰트 적용 여부에 따라 생략 가능
                        fontSize: 36,
                        color: OmmaColors.green,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(offset: Offset(2, 2), blurRadius: 3)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: '이메일',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: '비밀번호',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OmmaColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '로그인',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: Colors.white),
                            ],
                          ),
                  ),
                ],
              ),
              // 하단 문의처
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '문의: 1126jypark@snu.ac.kr / 010-5819-6276',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
