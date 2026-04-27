import 'package:flutter/material.dart';

class FileCard extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final VoidCallback onDelete;

  const FileCard({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$fileName\n$fileSize",
              style: const TextStyle(fontSize: 11, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
