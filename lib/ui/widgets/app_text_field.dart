import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

InputDecoration appInputDecoration({
  String? hintText,
  TextStyle? hintStyle,
  Widget? suffixIcon,
  String? suffixText,
  TextStyle? suffixStyle,
}) {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.bgInput,
    hintText: hintText,
    hintStyle: hintStyle,
    suffixIcon: suffixIcon,
    suffixText: suffixText,
    suffixStyle: suffixStyle,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.accent),
    ),
  );
}

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final bool autofocus;
  final bool obscureText;
  final String? hintText;
  final Widget? suffixIcon;
  final String? suffixText;
  final TextStyle? suffixStyle;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final double? height;

  const AppTextField({
    super.key,
    this.controller,
    this.autofocus = false,
    this.obscureText = false,
    this.hintText,
    this.suffixIcon,
    this.suffixText,
    this.suffixStyle,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      obscureText: obscureText,
      style: context.txt.body,
      cursorColor: AppColors.accent,
      decoration: appInputDecoration(
        hintText: hintText,
        hintStyle: hintText != null
            ? context.txt.body.copyWith(color: AppColors.fgMuted)
            : null,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
        suffixStyle: suffixStyle,
      ),
      onSubmitted: onSubmitted,
      onChanged: onChanged,
    );
    if (height != null) {
      return SizedBox(height: height, child: field);
    }
    return field;
  }
}
