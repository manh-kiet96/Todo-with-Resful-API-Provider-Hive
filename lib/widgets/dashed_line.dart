import 'package:flutter/material.dart';
import 'package:todo_with_resfulapi/constants/app_color_path.dart';

class DashedLine extends StatelessWidget {
  final double height;
  final double dashWidth;
  final Color? color;

  const DashedLine({this.height = 1, this.dashWidth = 6, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final boxWidth = constraints.constrainWidth();
      final dashCount = (boxWidth / (dashWidth * 2)).floor();
      return SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: height,
              color: color ?? AppColorsPath.grey,
            );
          }),
        ),
      );
    });
  }
}
