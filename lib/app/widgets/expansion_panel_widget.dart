import 'package:flutter/material.dart';

class ExpansionPanelWidget extends StatefulWidget {
  const ExpansionPanelWidget({
    Key? key,
    required this.title,
    required this.body,
    required this.isSelected,
    required this.isPremium,
    required this.onChanged,
  }) : super(key: key);

  final String title;
  final Widget body;
  final bool isSelected;
  final bool isPremium;
  final void Function(bool? value)? onChanged;

  @override
  State<ExpansionPanelWidget> createState() => _ExpansionPanelWidgetState();
}

class _ExpansionPanelWidgetState extends State<ExpansionPanelWidget> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          onTap: _toggleExpanded,
          contentPadding: EdgeInsets.zero,
          leading: Checkbox(
            value: widget.isSelected,
            onChanged: widget.isPremium ? (value) {} : widget.onChanged,
            activeColor: Colors.yellow[700],
          ),
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
        ),
        if (_isExpanded)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: widget.body,
          ),
      ],
    );
  }
}
