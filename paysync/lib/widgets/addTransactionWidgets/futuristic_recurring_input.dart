import 'package:flutter/material.dart';

class FuturisticRecurringInput extends StatefulWidget {
  final bool isRecurring;
  final String recurringType;
  final List<String> recurringTypes;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<String> onTypeChanged;

  const FuturisticRecurringInput({
    Key? key,
    required this.isRecurring,
    required this.recurringType,
    required this.recurringTypes,
    required this.onRecurringChanged,
    required this.onTypeChanged,
  }) : super(key: key);

  @override
  State<FuturisticRecurringInput> createState() =>
      _FuturisticRecurringInputState();
}

class _FuturisticRecurringInputState extends State<FuturisticRecurringInput> {
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
              widget.isRecurring
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                widget.isRecurring
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : Colors.transparent,
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          CheckboxListTile(
            title: Text(
              'Recurring Transaction',
              style: TextStyle(
                color:
                    widget.isRecurring
                        ? Theme.of(context).primaryColor
                        : Colors.grey[700],
                fontWeight:
                    widget.isRecurring ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            value: widget.isRecurring,
            onChanged: (bool? value) {
              widget.onRecurringChanged(value ?? false);
            },
            activeColor: Theme.of(context).primaryColor,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          if (widget.isRecurring) ...[
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recurring Type',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.recurringType,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).primaryColor,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          borderRadius: BorderRadius.circular(15),
                          items:
                              widget.recurringTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.repeat,
                                        color:
                                            widget.recurringType == type
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        type,
                                        style: TextStyle(
                                          color:
                                              widget.recurringType == type
                                                  ? Theme.of(
                                                    context,
                                                  ).primaryColor
                                                  : Colors.grey[700],
                                          fontWeight:
                                              widget.recurringType == type
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
                              widget.onTypeChanged(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
