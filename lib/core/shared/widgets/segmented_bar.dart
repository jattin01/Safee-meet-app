import 'package:flutter/material.dart';

/// A row of equal-width rounded segments, used for step progress (auth
/// register flow) and password-strength indicators.
class SegmentedBar extends StatelessWidget {
  final int segments;
  final int filled;
  final Color filledColor;
  final Color unfilledColor;
  final double height;
  final double gap;

  const SegmentedBar({
    super.key,
    required this.segments,
    required this.filled,
    required this.filledColor,
    required this.unfilledColor,
    this.height = 4,
    this.gap = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(segments, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == segments - 1 ? 0 : gap),
            height: height,
            decoration: BoxDecoration(
              color: i < filled ? filledColor : unfilledColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      }),
    );
  }
}
