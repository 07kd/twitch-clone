import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String> uploadToSupabaseStorage(Uint8List image) async {
  try {
    // Generate a unique filename using timestamp
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = 'uploads/$fileName';

    // Upload the image bytes
    await Supabase.instance.client.storage
        .from('twitchProfilePhotos')
        .uploadBinary(filePath, image,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
            ));

    // Get the public URL
    final String downloadUrl = Supabase.instance.client.storage
        .from('twitchProfilePhotos')
        .getPublicUrl(filePath);

    return downloadUrl;
  } catch (e) {
    print('Error uploading image: $e');
    rethrow;
  }
}
