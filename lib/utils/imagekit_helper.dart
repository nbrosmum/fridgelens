import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'imagekit_config.dart';

class ImageKitHelper {
  /// Uploads an image file to ImageKit in the specified folder.
  /// Returns a map with 'success', 'url', and 'fileId' keys.
  static Future<Map<String, dynamic>> uploadImageToImageKit(
    File imageFile,
    String folderPath,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ImageKitConfig.authenticationEndpoint),
      );
      request.headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('${ImageKitConfig.privateKey}:'))}';
      request.fields['fileName'] =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      request.fields['folder'] = folderPath;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': jsonResponse['url'],
          'fileId': jsonResponse['fileId'],
        };
      } else {
        return {
          'success': false,
          'error': jsonResponse['message'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Upload error: $e'};
    }
  }

  /// Downloads an image from originalImageUrl and uploads it to /history/userId folder in ImageKit.
  /// Returns a map with 'url' and 'fileId' if successful, or null if failed.
  static Future<Map<String, dynamic>?> copyImageToHistoryFolder(
    String originalFileId,
    String originalImageUrl,
    String userId,
  ) async {
    try {
      if (originalFileId.isEmpty || originalImageUrl.isEmpty) {
        return null;
      }
      // Download the original image
      final response = await http.get(Uri.parse(originalImageUrl));
      if (response.statusCode != 200) {
        print('Failed to download original image: ${response.statusCode}');
        return null;
      }
      // Create a temporary file
      final tempDir = await Directory.systemTemp.createTemp(
        'fridgelens_history',
      );
      final tempFile = File('${tempDir.path}/temp_image.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);
      // Upload to user-specific history folder
      final historyFolderPath = '/history/$userId';
      final uploadResult = await uploadImageToImageKit(
        tempFile,
        historyFolderPath,
      );
      // Clean up temp file
      await tempFile.delete();
      await tempDir.delete();
      if (uploadResult['success']) {
        return {'url': uploadResult['url'], 'fileId': uploadResult['fileId']};
      } else {
        print(
          'Failed to upload image to history folder: ${uploadResult['error']}',
        );
        return null;
      }
    } catch (e) {
      print('Error copying image to history folder: $e');
      return null;
    }
  }

  /// Deletes an image from ImageKit by fileId. Returns true if successful.
  static Future<bool> deleteImageFromImageKit(String fileId) async {
    try {
      final url = Uri.parse('https://api.imagekit.io/v1/files/$fileId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${ImageKitConfig.privateKey}:'))}',
        },
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting image from ImageKit: $e');
      return false;
    }
  }
}
