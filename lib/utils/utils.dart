import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<Uint8List?> pickImage() async {
  FilePickerResult? pickedImage =
      await FilePicker.platform.pickFiles(type: FileType.image);
  if (pickedImage != null) {
    if (kIsWeb) {
      return pickedImage.files.single.bytes;
    }
    return await File(pickedImage.files.single.path!).readAsBytes();
  }
}
