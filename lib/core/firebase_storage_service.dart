import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_service.dart';

class FirebaseStorageService {
  FirebaseStorageService._();

  static Future<String> uploadLearningFile({
    required File file,
    required String folder,
    required String name,
  }) async {
    if (!FirebaseService.isEnabled) {
      return file.path;
    }

    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final reference = FirebaseStorage.instance
        .ref()
        .child('learning_materials')
        .child(folder)
        .child('${DateTime.now().millisecondsSinceEpoch}_$safeName');
    await reference.putFile(file);
    return reference.getDownloadURL();
  }
}
