import 'package:flutter/material.dart';

/// Search-by-name-or-phone text field for [CustomerListScreen], with a
/// clear button that only appears once text has been entered.
class CustomerSearchBar extends StatefulWidget {
  const CustomerSearchBar({
    super.key,
    required this.onChanged,
    this.initialQuery = '',
  });

  final ValueChanged<String> onChanged;
  final String initialQuery;

  @override
  State<CustomerSearchBar> createState() => _CustomerSearchBarState();
}

class _CustomerSearchBarState extends State<CustomerSearchBar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  void didUpdateWidget(covariant CustomerSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resync when the query changes externally (e.g. a "Clear Search &
    // Filters" action resetting CustomerProvider.searchQuery directly) —
    // during normal typing, onChanged already keeps the provider and this
    // controller in lockstep, so this is a no-op then.
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Search by name or phone',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear search',
                    onPressed: _clear,
                  ),
            border: const OutlineInputBorder(),
          ),
        );
      },
    );
  }
}
