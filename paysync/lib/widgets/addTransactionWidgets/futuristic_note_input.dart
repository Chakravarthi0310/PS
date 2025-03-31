import 'package:flutter/material.dart';

class FuturisticNoteInput extends StatefulWidget {
  final TextEditingController controller;

  const FuturisticNoteInput({Key? key, required this.controller})
    : super(key: key);

  @override
  State<FuturisticNoteInput> createState() => _FuturisticNoteInputState();
}

class _FuturisticNoteInputState extends State<FuturisticNoteInput> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              _isFocused
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                _isFocused
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : Colors.transparent,
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: 3,
        style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.note,
            color:
                _isFocused
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
