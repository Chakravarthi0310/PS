import 'package:flutter/material.dart';

class FuturisticEventInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;

  const FuturisticEventInput({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
  }) : super(key: key);

  @override
  State<FuturisticEventInput> createState() => _FuturisticEventInputState();
}

class _FuturisticEventInputState extends State<FuturisticEventInput> {
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
        validator: widget.validator,
        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
        decoration: InputDecoration(
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          labelStyle: TextStyle(
            fontSize: 16,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            color:
                _isFocused
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.8),
          ),
          prefixIcon: Icon(
            widget.icon,
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
        ),
      ),
    );
  }
}
