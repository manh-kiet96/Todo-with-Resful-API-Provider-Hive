import 'package:flutter/material.dart';
import 'package:todo_with_resfulapi/components/app_text.dart';
import 'package:todo_with_resfulapi/components/app_text_style.dart';
import 'package:todo_with_resfulapi/constants/app_color_path.dart';

class AppButton extends StatelessWidget {
  final String content;
  final VoidCallback onTap;
  final double? width;
  final TextStyle? textStyle;
  final Color? color;
  final double borderRadius;

  const AppButton({
    required this.content,
    required this.onTap,
    this.width,
    this.textStyle,
    this.color,
    this.borderRadius = 12,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double btnHeight = 48.0;
    final double btnWidth = width ?? (size.width * 0.9);

    return SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColorsPath.sunburn,
          foregroundColor: AppColorsPath.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: AppText(
          title: content,
          style: textStyle ?? AppTextStyle.textFontM17W500,
        ),
      ),
    );
  }
}
