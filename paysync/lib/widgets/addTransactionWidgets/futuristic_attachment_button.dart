import 'package:flutter/material.dart';

class FuturisticAttachmentButton extends StatefulWidget {
  final VoidCallback onPressed;

  const FuturisticAttachmentButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<FuturisticAttachmentButton> createState() =>
      _FuturisticAttachmentButtonState();
}

class _FuturisticAttachmentButtonState extends State<FuturisticAttachmentButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _isPressed
              ? Theme.of(context).primaryColor
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isPressed
                ? Theme.of(context).primaryColor.withOpacity(0.2)
                : Colors.transparent,
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.attach_file,
                  color: _isPressed
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Attach Receipt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isPressed
                        ? Theme.of(context).primaryColor
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}