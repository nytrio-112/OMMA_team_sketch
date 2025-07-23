import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/constants/colors.dart';
import 'package:my_first_app/widget/appbar.dart';
import 'package:my_first_app/widget/text_field.dart'; // 커스텀 텍스트 필드 import

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

  String _selectedGender = '성별';
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

  Widget _buildGenderDropdown() {
    return FractionallySizedBox(
      widthFactor: 0.8,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedGender,
          validator: (value) {
            if (value == '성별') return '성별을 선택해주세요';
            return null;
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: OmmaColors.green, fontSize: 16),
          iconEnabledColor: OmmaColors.green,
          dropdownColor: Colors.white,
          items: ['성별', '여자', '남자', '기타']
              .map(
                (gender) =>
                    DropdownMenuItem(value: gender, child: Text(gender)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedGender = value!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmmaColors.pink,
      appBar: const SimpleBackAppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 8,
              left: 32,
              right: 32,
              bottom: 40,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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

                  // 이름
                  OmmaTextField(
                    controller: _nameController,
                    hintText: '이름',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이름을 입력하세요';
                      }
                      return null;
                    },
                  ),

                  // 출생연도
                  OmmaTextField(
                    controller: _yearController,
                    hintText: '출생 연도(4자)',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '출생 연도를 입력하세요';
                      }
                      if (value.length != 4) {
                        return '출생 연도는 4자리 숫자여야 합니다';
                      }
                      return null;
                    },
                  ),

                  // 성별 드롭다운
                  _buildGenderDropdown(),

                  // 이메일
                  OmmaTextField(
                    controller: _emailController,
                    hintText: '이메일',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력하세요';
                      }
                      return null;
                    },
                  ),

                  // 비밀번호
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
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력하세요';
                      }
                      return null;
                    },
                  ),

                  // 비밀번호 확인
                  OmmaTextField(
                    controller: _confirmPasswordController,
                    hintText: '비밀번호 확인',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: OmmaColors.green,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호 확인을 입력하세요';
                      }
                      if (value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // 가입하기 버튼
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OmmaColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '가입하기',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
