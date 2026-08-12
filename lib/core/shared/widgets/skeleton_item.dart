import 'package:flutter/material.dart';

class SkeletonItem extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;

  const SkeletonItem({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.color,
  });

  @override
  State<SkeletonItem> createState() => _SkeletonItemState();
}

class _SkeletonItemState extends State<SkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.8).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color ?? Colors.grey[300],
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
