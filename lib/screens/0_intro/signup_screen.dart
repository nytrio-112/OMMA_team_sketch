import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/constants/colors.dart';
import 'package:my_first_app/widget/appbar.dart'; // 공통 AppBar 위젯 import

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

  Widget _buildTextField(TextEditingController controller, String hintText) {
    return FractionallySizedBox(
      widthFactor: 0.7,
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
        child: TextFormField(
          controller: controller,
          style: const TextStyle(color: OmmaColors.green, fontSize: 16),
          validator: (value) {
            if (value == null || value.isEmpty) return '$hintText을 입력하세요';
            if (hintText == '출생 연도(4자)' && value.length != 4) {
              return '출생 연도는 4자리 숫자여야 합니다';
            }
            if (hintText == '비밀번호 확인' && value != _passwordController.text) {
              return '비밀번호가 일치하지 않습니다';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: OmmaColors.green),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String hintText,
    bool obscure,
    void Function() toggle,
  ) {
    return FractionallySizedBox(
      widthFactor: 0.7,
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
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: OmmaColors.green, fontSize: 16),
          validator: (value) {
            if (value == null || value.isEmpty) return '$hintText을 입력하세요';
            if (hintText == '비밀번호 확인' && value != _passwordController.text) {
              return '비밀번호가 일치하지 않습니다';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: OmmaColors.green),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: OmmaColors.green,
              ),
              onPressed: toggle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return FractionallySizedBox(
      widthFactor: 0.7,
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
      appBar: const SimpleBackAppBar(), // ✅ 여기만 바뀐 부분!
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
                  _buildTextField(_nameController, '이름'),
                  _buildTextField(_yearController, '출생 연도(4자)'),
                  _buildGenderDropdown(),
                  _buildTextField(_emailController, '이메일'),
                  _buildPasswordField(
                    _passwordController,
                    '비밀번호',
                    _obscurePassword,
                    () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  _buildPasswordField(
                    _confirmPasswordController,
                    '비밀번호 확인',
                    _obscureConfirmPassword,
                    () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FractionallySizedBox(
                    widthFactor: 0.5,
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
