import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_first_app/constants/colors.dart';
import 'package:my_first_app/widget/appbar.dart';
import 'package:my_first_app/widget/text_field.dart'; // 너의 커스텀 텍스트 필드 import

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

    if (email.isEmpty || password.isEmpty) {
      _showMessage("정보를 입력해주세요");
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage("올바른 이메일 주소가 아닙니다");
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushReplacementNamed(context, '/mypage');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showMessage("사용자 정보를 찾을 수 없습니다. 회원가입을 진행해주세요.");
      } else if (e.code == 'wrong-password') {
        _showMessage("비밀번호가 일치하지 않습니다. 다시 시도해주세요.");
      } else {
        _showMessage("로그인에 실패했습니다. 다시 시도해주세요.");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLoginButton() {
    return FractionallySizedBox(
      widthFactor: 0.6,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: OmmaColors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '로그인',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleBackAppBar(),
      backgroundColor: OmmaColors.pink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 8,
              left: 32,
              right: 32,
              bottom: 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'OMMA',
                  style: TextStyle(
                    fontFamily: 'OmmaLogoFont',
                    fontSize: 50,
                    color: OmmaColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                OmmaTextField(controller: _emailController, hintText: '이메일'),
                OmmaTextField(
                  controller: _passwordController,
                  hintText: '비밀번호',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: OmmaColors.green,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 40),
                const Text(
                  '문의: 1126jypark@snu.ac.kr\n📞 010-5819-6276',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
