import 'package:flutter/material.dart';

class AppIconWidget extends StatelessWidget {
  final double size;
  final Color color;

  const AppIconWidget({
    super.key,
    this.size = 100,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 5),
      ),
      child: Center(
        child: Icon(
          Icons.document_scanner_rounded,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}
