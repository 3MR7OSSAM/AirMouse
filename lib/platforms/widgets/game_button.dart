import 'package:flutter/material.dart';

class GameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;
  final double size;
  final Color color;

  const GameButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.onPointerDown,
    this.onPointerUp,
    this.size = 50,
    this.color = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        onPointerDown?.call();
      },
      onPointerUp: (event) {
        onPointerUp?.call();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
