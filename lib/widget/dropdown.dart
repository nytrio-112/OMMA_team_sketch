import 'package:flutter/material.dart';
import '../constants/colors.dart';

class OmmaDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final Function(String?) onChanged;
  final TextStyle? hintStyle;

  const OmmaDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.hintStyle,
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
        child: DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: OmmaColors.green.withOpacity(0.5), // 연한 초록
              fontSize: 16,
            ),
          ),
          validator: (val) {
            if (val == null || val == hint) return '선택해주세요';
            return null;
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: OmmaColors.green, fontSize: 16),
          iconEnabledColor: const Color.fromRGBO(3, 166, 106, 1),
          dropdownColor: Colors.white,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 16)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
