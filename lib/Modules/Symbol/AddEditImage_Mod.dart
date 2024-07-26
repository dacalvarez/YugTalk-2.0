import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter_svg/flutter_svg.dart';
import 'SearchSymbol_Mod.dart';

class AddEditImage extends StatefulWidget {
  final String wordImage;
  final ValueChanged<String> onImageChanged;

  const AddEditImage({
    required this.wordImage,
    required this.onImageChanged,
  });

  @override
  _AddEditImageState createState() => _AddEditImageState();
}

class _AddEditImageState extends State<AddEditImage> {
  late String _currentImage;
  late String _originalImage;
  static const int _maxFileSize = 5 * 1024 * 1024; // 5 MB in bytes
  static const int _resizeFileSize = 1 * 1024 * 1024; // 1 MB in bytes
  List<CameraDescription> cameras = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentImage = widget.wordImage;
    _originalImage = widget.wordImage;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        final fileSize = await pickedFile.length();
        if (fileSize > _maxFileSize) {
          _showErrorDialog('The selected image exceeds the 5 MB size limit.');
          return;
        }

        File imageFile = File(pickedFile.path);
        img.Image? image = img.decodeImage(imageFile.readAsBytesSync());

        if (image != null) {
          // Resize to 720x720 and convert to 1:1 aspect ratio
          image = img.copyResizeCropSquare(image, size: image.width > image.height ? image.height : image.width);
          image = img.copyResize(image, width: 720, height: 720);

          // Convert to JPEG if necessary
          if (!imageFile.path.toLowerCase().endsWith('.jpg') && !imageFile.path.toLowerCase().endsWith('.jpeg')) {
            Uint8List jpegBytes = img.encodeJpg(image);
            String newPath = '${imageFile.path.split('.').first}.jpg';
            imageFile = await File(newPath).writeAsBytes(jpegBytes);
          } else {
            await imageFile.writeAsBytes(img.encodeJpg(image));
          }

          setState(() {
            _currentImage = imageFile.path;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _confirmDeleteImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: GText('Confirm'),
        content: GText('Do you want to delete the selected image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: GText('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearImage();
            },
            child: GText('Yes'),
          ),
        ],
      ),
    );
  }

  void _clearImage() {
    setState(() {
      _currentImage = '';
    });
  }

  void _confirmClearImage() {
    if (_currentImage.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: GText('Confirm'),
          content: GText('Do you want to discard the selected image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: GText('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearImage();
                Navigator.pop(context); // Close the Select Symbol dialog
              },
              child: GText('Yes'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _saveImage() {
    setState(() {
      _originalImage = _currentImage;
    });
    widget.onImageChanged(_currentImage);
    Navigator.pop(context); // Close the dialog after saving
  }

  void _navigateToSearch() {
    showSearchSymbolDialog(context, (String imageUrl) {
      setState(() {
        _currentImage = imageUrl;
      });
      _saveImage(); // Save the image directly
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: GText('Error'),
        content: GText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: GText('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: AlertDialog(
        title: GText('Select Symbol'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                width: 200,
                color: Colors.grey[500],
                child: _currentImage.isEmpty
                    ? const Center(child: GText('No symbol selected'))
                    : _buildImageContainer(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _navigateToSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: GText('Search',
                          style: TextStyle(color: Colors.white)
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: GText('Camera',
                          style: TextStyle(color: Colors.white)
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: GText('Gallery',
                        style: TextStyle(color: Colors.white)
                      ),
                    ),
                  ),
                ],
              ),
              if (_currentImage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmDeleteImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: GText(
                            'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _confirmClearImage,
            child: GText('Cancel'),
          ),
          TextButton(
            onPressed: _saveImage,
            child: GText('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer() {
    if (_currentImage.isEmpty) {
      return Container(
        width: 200,
        height: 200,
        child: const Center(
          child: GText(
            'No symbol selected',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isSvg = _currentImage.toLowerCase().endsWith('.svg');
    final isLocalFile = File(_currentImage).existsSync();
    Widget imageWidget;

    if (isSvg) {
      imageWidget = SvgPicture.network(
        _currentImage,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
        height: 200, // Set height for SVG
        width: 200, // Set width for SVG
      );
    } else if (isLocalFile) {
      imageWidget = Image.file(
        File(_currentImage),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
        },
      );
    } else {
      imageWidget = Image.network(
        _currentImage,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
        },
      );
    }

    return Container(
      width: 200,
      height: 200,
      child: FittedBox(
        fit: BoxFit.contain,
        child: imageWidget,
      ),
    );
  }
}

void showAddEditImageDialog(BuildContext context, String wordImage, ValueChanged<String> onImageChanged) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (context) => AddEditImage(wordImage: wordImage, onImageChanged: onImageChanged),
  );
}