

import 'package:flutter/material.dart';
class CustomTextField extends StatelessWidget {
  final String hint;
  final int maxLines;
  final bool obscure;
   final TextEditingController controller;
  const  CustomTextField({    
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.obscure = false,
    
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
