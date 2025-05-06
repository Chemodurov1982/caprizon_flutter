import 'package:flutter/material.dart';

class TokenSelector extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const TokenSelector({
    super.key,
    required this.tokens,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selected,
      isExpanded: true,
      hint: const Text('Select token'),
      onChanged: onChanged,
      items: tokens.map((token) {
        final name = token['name'] ?? 'Unnamed';
        final symbol = token['symbol'] ?? '';
        final admin = token['adminName'] ?? '';
        final id = token['tokenId'] ?? token['_id'] ?? '';
        return DropdownMenuItem<String>(
          value: id,
          child: Text('$name ($symbol) — $admin'),
        );
      }).toList(),
    );
  }
}
