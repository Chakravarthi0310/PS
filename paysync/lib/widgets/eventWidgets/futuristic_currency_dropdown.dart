import 'package:flutter/material.dart';

class FuturisticCurrencyDropdown extends StatefulWidget {
  final String value;
  final List<String> currencies;
  final ValueChanged<String> onChanged;

  const FuturisticCurrencyDropdown({
    Key? key,
    required this.value,
    required this.currencies,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<FuturisticCurrencyDropdown> createState() =>
      _FuturisticCurrencyDropdownState();
}

class _FuturisticCurrencyDropdownState extends State<FuturisticCurrencyDropdown> {
  bool _isExpanded = false;

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
          color: _isExpanded
              ? Theme.of(context).primaryColor
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isExpanded
                ? Theme.of(context).primaryColor.withOpacity(0.2)
                : Colors.transparent,
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.value,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: _isExpanded
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.8),
          ),
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
          },
          items: widget.currencies.map((String currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Row(
                children: [
                  Icon(
                    Icons.currency_exchange,
                    color: widget.value == currency
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.8),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    currency,
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.value == currency
                          ? Theme.of(context).primaryColor
                          : Colors.grey[800],
                      fontWeight: widget.value == currency
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              widget.onChanged(newValue);
              setState(() => _isExpanded = false);
            }
          },
        ),
      ),
    );
  }
}