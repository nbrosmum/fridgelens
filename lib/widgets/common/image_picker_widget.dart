import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A reusable widget for picking, displaying, and removing an image.
/// Usage: ImagePickerWidget(onImagePicked: (file) { ... })
class ImagePickerWidget extends StatefulWidget {
  final File? initialImage;
  final ValueChanged<File?> onImagePicked;
  final double size;
  final String addLabel;

  const ImagePickerWidget({
    super.key,
    this.initialImage,
    required this.onImagePicked,
    this.size = 120,
    this.addLabel = 'Add Image',
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _imageFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImage;
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImage?.path != oldWidget.initialImage?.path) {
      setState(() {
        _imageFile = widget.initialImage;
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() {
                    _imageFile = File(image.path);
                  });
                  widget.onImagePicked(_imageFile);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (photo != null) {
                  setState(() {
                    _imageFile = File(photo.path);
                  });
                  widget.onImagePicked(_imageFile);
                }
              },
            ),
            if (_imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Image',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  setState(() {
                    _imageFile = null;
                  });
                  widget.onImagePicked(null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceOptions,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            image: _imageFile != null
                ? DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _imageFile == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, size: 36, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      widget.addLabel,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}
