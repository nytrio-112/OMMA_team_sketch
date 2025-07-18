import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedGender = '여자';
  bool isLoading = false;

  // 사용자 등록 메서드
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await firestore.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'yearOfBirth': int.parse(_yearController.text),
        'gender': _selectedGender,
        'email': _emailController.text.trim(),
        'uid': uid,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.pushNamed(context, '/onboarding');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류: ${e.message}')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC0CB), // 핑크 배경
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'OMMA',
                    style: TextStyle(
                      fontFamily: 'OmmaLogoFont',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, '이름'),
                  _buildTextField(
                    _yearController,
                    '출생 연도(4자)',
                    keyboardType: TextInputType.number,
                  ),
                  _buildGenderDropdown(),
                  _buildTextField(_emailController, '이메일'),
                  _buildTextField(
                    _passwordController,
                    '비밀번호',
                    isPassword: true,
                  ),
                  _buildTextField(
                    _confirmPasswordController,
                    '비밀번호 확인',
                    isPassword: true,
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('가입하기'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) return '$labelText을 입력하세요';
          if (labelText == '출생 연도(4자)' && value.length != 4) {
            return '출생 연도는 4자리 숫자여야 합니다';
          }
          if (labelText == '비밀번호 확인' && value != _passwordController.text) {
            return '비밀번호가 일치하지 않습니다';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: '성별',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          filled: true,
          fillColor: Colors.white,
        ),
        items: ['남자', '여자']
            .map(
              (gender) => DropdownMenuItem(value: gender, child: Text(gender)),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedGender = value!),
      ),
    );
  }
}
