import 'package:flutter/material.dart';

class AnimatedSegmentButton extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AnimatedSegmentButton({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<AnimatedSegmentButton> createState() => _AnimatedSegmentButtonState();
}

class _AnimatedSegmentButtonState extends State<AnimatedSegmentButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 10),  // Changed from previous value
            curve: Curves.easeOut,
            tween: Tween<double>(
              begin: widget.value ? -1 : 1,
              end: widget.value ? -1 : 1,
            ),
            builder: (context, value, child) {
              return Align(
                alignment: Alignment(value, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.43,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: _buildSegment(
                  text: 'Income',
                  isSelected: widget.value,
                  onTap: () => widget.onChanged(true),
                ),
              ),
              Expanded(
                child: _buildSegment(
                  text: 'Expense',
                  isSelected: !widget.value,
                  onTap: () => widget.onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
