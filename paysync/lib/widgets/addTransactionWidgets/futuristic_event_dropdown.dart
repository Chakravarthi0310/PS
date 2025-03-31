import 'package:flutter/material.dart';
import 'package:paysync/models/event_model.dart';

class FuturisticEventDropdown extends StatefulWidget {
  final String value;
  final List<EventModel> events;
  final ValueChanged<String> onChanged;

  const FuturisticEventDropdown({
    Key? key,
    required this.value,
    required this.events,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<FuturisticEventDropdown> createState() => _FuturisticEventDropdownState();
}

class _FuturisticEventDropdownState extends State<FuturisticEventDropdown> {
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
                Icons.event,
                color: _isExpanded
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.8),
              ),
              SizedBox(width: 12),
              Text(
                widget.value == 'default' 
                    ? 'Default'
                    : widget.events
                        .firstWhere((e) => e.eventId == widget.value)
                        .nameOfEvent,
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
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.event_available,
                      color: widget.value == 'default'
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.8),
                    ),
                    title: Text(
                      'Default',
                      style: TextStyle(
                        color: widget.value == 'default'
                            ? Theme.of(context).primaryColor
                            : Colors.grey[700],
                        fontWeight: widget.value == 'default'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      widget.onChanged('default');
                      setState(() => _isExpanded = false);
                    },
                    tileColor: widget.value == 'default'
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  ...widget.events.map((event) {
                    final isSelected = event.eventId == widget.value;
                    return ListTile(
                      leading: Icon(
                        Icons.event_note,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withOpacity(0.8),
                      ),
                      title: Text(
                        event.nameOfEvent,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        widget.onChanged(event.eventId);
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}