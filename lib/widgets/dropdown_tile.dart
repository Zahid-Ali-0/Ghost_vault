import 'package:flutter/material.dart';

class DropdownTile extends StatelessWidget {
  final String title;
  final String value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;

  const DropdownTile({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          hint: Text(hint),
          initialValue: value,
          style:const TextStyle(color: Colors.white),
          dropdownColor: Colors.grey,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
