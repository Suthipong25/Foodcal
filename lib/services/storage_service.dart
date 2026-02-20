
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfilePicture(String uid, Uint8List data) async {
    try {
      final ref = _storage.ref().child('users').child(uid).child('profile.jpg');
      final uploadTask = await ref.putData(
        data,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Profile picture uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }
}
