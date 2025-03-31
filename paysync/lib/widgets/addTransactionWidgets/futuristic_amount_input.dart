import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FuturisticAmountInput extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? currency;

  const FuturisticAmountInput({
    Key? key,
    required this.controller,
    this.validator,
    this.currency,
  }) : super(key: key);

  @override
  State<FuturisticAmountInput> createState() => _FuturisticAmountInputState();
}

class _FuturisticAmountInputState extends State<FuturisticAmountInput> {
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
        focusNode: _focusNode, // Add this line
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        validator: widget.validator,
        // Remove onFocusChanged
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
        decoration: InputDecoration(
          labelText: 'Amount',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          labelStyle: TextStyle(
            fontSize: 16,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            color: _isFocused
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.8),
          ),
          prefixIcon: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.currency ?? '₹',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      _isFocused
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.8),
                ),
              ),
            ),
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
