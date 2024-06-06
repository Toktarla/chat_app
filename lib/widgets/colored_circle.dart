import 'package:flutter/material.dart';

class ColoredCircle extends StatelessWidget {
  final double radius;
  final Color color;

  const ColoredCircle({required this.radius, required this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}