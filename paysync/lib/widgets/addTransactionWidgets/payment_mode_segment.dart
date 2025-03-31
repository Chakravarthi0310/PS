import 'package:flutter/material.dart';

class PaymentModeSegment extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PaymentModeSegment({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<PaymentModeSegment> createState() => _PaymentModeSegmentState();
}

class _PaymentModeSegmentState extends State<PaymentModeSegment> {
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
            duration: Duration(milliseconds: 10), // Reduced from 200
            curve: Curves.easeOut, // Changed from easeInOut
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
                    color: widget.value ? Colors.blue : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.value ? Colors.blue : Colors.green)
                            .withOpacity(0.3),
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
                  text: 'Online',
                  icon: Icons.wifi,
                  isSelected: widget.value,
                  onTap: () => widget.onChanged(true),
                ),
              ),
              Expanded(
                child: _buildSegment(
                  text: 'Offline',
                  icon: Icons.money,
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
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
