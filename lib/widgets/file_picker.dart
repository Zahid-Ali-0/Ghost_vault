
class PickedFileModel {
  final String name;
  final int size;
  final String? path;

  PickedFileModel({
    required this.name,
    required this.size,
    this.path,
  });
}
