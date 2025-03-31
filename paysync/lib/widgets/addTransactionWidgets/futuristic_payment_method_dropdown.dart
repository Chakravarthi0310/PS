import 'package:flutter/material.dart';

class FuturisticPaymentMethodDropdown extends StatefulWidget {
  final String value;
  final List<String> paymentMethods;
  final ValueChanged<String> onChanged;

  const FuturisticPaymentMethodDropdown({
    Key? key,
    required this.value,
    required this.paymentMethods,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<FuturisticPaymentMethodDropdown> createState() =>
      _FuturisticPaymentMethodDropdownState();
}

class _FuturisticPaymentMethodDropdownState
    extends State<FuturisticPaymentMethodDropdown> {
  bool _isExpanded = false;

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.mobile_friendly;
      case 'card':
        return Icons.credit_card;
      case 'bank transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
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
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            border: InputBorder.none,
          ),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(
                _getPaymentIcon(widget.value),
                color: _isExpanded
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.8),
              ),
              SizedBox(width: 12),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isExpanded
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: widget.paymentMethods.map((method) {
                  final isSelected = method == widget.value;
                  return ListTile(
                    leading: Icon(
                      _getPaymentIcon(method),
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.8),
                    ),
                    title: Text(
                      method,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      widget.onChanged(method);
                      setState(() => _isExpanded = false);
                    },
                    tileColor: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}