import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FuturisticBudgetInput extends StatefulWidget {
  final TextEditingController controller;
  final String currency;

  const FuturisticBudgetInput({
    Key? key,
    required this.controller,
    required this.currency,
  }) : super(key: key);

  @override
  State<FuturisticBudgetInput> createState() => _FuturisticBudgetInputState();
}

class _FuturisticBudgetInputState extends State<FuturisticBudgetInput> {
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
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        validator:
            (value) =>
                value?.isEmpty ?? true ? 'Please enter event budget' : null,
        decoration: InputDecoration(
          labelText: 'Budget ',
          labelStyle: TextStyle(
            color:
                _isFocused
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.8),
          ),
          prefixIcon: Icon(
            Icons.account_balance_wallet,
            color:
                _isFocused
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.8),
          ),
          prefixText: widget.currency,
          prefixStyle: TextStyle(
            color:
                _isFocused ? Theme.of(context).primaryColor : Colors.grey[800],
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
