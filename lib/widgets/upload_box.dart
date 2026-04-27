import 'package:Ghost_Vault/widgets/file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';


class UploadBox extends StatefulWidget {
  final Function(List<PickedFileModel>) onFilesPicked;

  const UploadBox({super.key, required this.onFilesPicked});

  @override
  State<UploadBox> createState() => _UploadBoxState();
}

List<PickedFileModel> selectedFiles = [];

class _UploadBoxState extends State<UploadBox> {
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      final files = result.files.map((file) {
        return PickedFileModel(
          name: file.name,
          size: file.size,
          path: file.path,
        );
      }).toList();

      widget.onFilesPicked(files);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pickFiles,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file, color: Colors.white54),
              SizedBox(height: 6),
              Text(
                "Upload file here\nChoose file",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
