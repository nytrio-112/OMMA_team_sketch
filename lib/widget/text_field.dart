import 'package:flutter/material.dart';
import 'package:my_first_app/constants/colors.dart';

class OmmaTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextStyle? hintStyle;
  final ValueChanged<String>? onChanged; // ✅ 새로 추가된 부분

  const OmmaTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.hintStyle,
    this.onChanged, // ✅ 생성자에 추가
  });

  @override
  Widget build(BuildContext context) {
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
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged, // ✅ 핵심 추가!
          style: const TextStyle(color: OmmaColors.green, fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: hintStyle ?? const TextStyle(color: OmmaColors.green),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    );
  }
}
