import 'package:flutter/material.dart';

class FuturisticDateTimeInput extends StatefulWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final Function(BuildContext) onDateTap;
  final Function(BuildContext) onTimeTap;

  const FuturisticDateTimeInput({
    Key? key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateTap,
    required this.onTimeTap,
  }) : super(key: key);

  @override
  State<FuturisticDateTimeInput> createState() => _FuturisticDateTimeInputState();
}

class _FuturisticDateTimeInputState extends State<FuturisticDateTimeInput> {
  bool _isDateFocused = false;
  bool _isTimeFocused = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                color: _isDateFocused
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isDateFocused
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.transparent,
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: InkWell(
              onTapDown: (_) => setState(() => _isDateFocused = true),
              onTapUp: (_) => setState(() => _isDateFocused = false),
              onTapCancel: () => setState(() => _isDateFocused = false),
              onTap: () => widget.onDateTap(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDateFocused
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: _isDateFocused
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withOpacity(0.8),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isDateFocused
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
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
                color: _isTimeFocused
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isTimeFocused
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.transparent,
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: InkWell(
              onTapDown: (_) => setState(() => _isTimeFocused = true),
              onTapUp: (_) => setState(() => _isTimeFocused = false),
              onTapCancel: () => setState(() => _isTimeFocused = false),
              onTap: () => widget.onTimeTap(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isTimeFocused
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: _isTimeFocused
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withOpacity(0.8),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${widget.selectedTime.hour}:${widget.selectedTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isTimeFocused
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}