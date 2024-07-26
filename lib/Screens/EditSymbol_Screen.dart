import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gtext/gtext.dart';
import '../Modules/Symbol/AddEditImage_Mod.dart';
import '../Modules/Symbol/LinkBoard_Mod.dart';
import '../Modules/Symbol/SymbolCategory_Mod.dart';
import '../Modules/Symbol/AddEditAudio_Mod.dart';
import '../Modules/Symbol/AddEditVideo_Mod.dart';

class EditSymbol extends StatefulWidget {
  final String userId;
  final String boardId;
  final String symbolId;
  final Function() refreshParent;

  const EditSymbol({
    Key? key,
    required this.boardId,
    required this.symbolId,
    required this.userId,
    required this.refreshParent,
  }) : super(key: key);

  @override
  _EditSymbolState createState() => _EditSymbolState();
}

class _EditSymbolState extends State<EditSymbol> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String wordImage;
  late String wordAudio;
  late String wordVideo;
  late String wordCategory;
  DocumentReference? isLinked;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  String? _previousImageUrl;
  String? _previousAudioUrl;
  String? _previousVideoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _loadSymbolData();
  }

  Future<void> _loadSymbolData() async {
    try {
      DocumentSnapshot symbolDoc = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardId)
          .collection('words')
          .doc(widget.symbolId)
          .get();

      if (symbolDoc.exists) {
        var data = symbolDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['wordName'] ?? '';
          _descController.text = data['wordDesc'] ?? '';
          wordImage = data['wordImage'] ?? '';
          wordAudio = data['wordAudio'] ?? '';
          wordVideo = data['wordVideo'] ?? '';
          wordCategory = data['wordCategory'] ?? '';
          isLinked = data['isLinked'] != null
              ? data['isLinked'] as DocumentReference
              : null;
          _previousImageUrl = wordImage;
          _previousAudioUrl = wordAudio;
          _previousVideoUrl = wordVideo;
          _isLoading = false;
        });
      } else {
        _initializeDefaults();
      }
    } catch (e) {
      _initializeDefaults();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Error loading symbol data: $e')),
      );
    }
  }

  void _initializeDefaults() {
    setState(() {
      _nameController.text = '';
      _descController.text = '';
      wordImage = '';
      wordAudio = '';
      wordVideo = '';
      wordCategory = '';
      isLinked = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: GText('Edit Symbol'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GText('Edit Symbol'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmCancel,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          onChanged: () => _hasUnsavedChanges = true,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildSymbolForm(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade500),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ElevatedButton(
                            onPressed: _confirmCancel,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: GText('Cancel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade500),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ElevatedButton(
                            onPressed: _confirmSave,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: GText('Save'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSymbolForm() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade500),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => showAddEditImageDialog(context, wordImage, (newImage) {
              setState(() {
                if (wordImage != newImage) {
                  _handleImageReplacement(newImage);
                  wordImage = newImage;
                  _hasUnsavedChanges = true;
                }
              });
            }),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade500),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImageContainer(wordImage),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.grey.shade500),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              if (value.contains('/') || value.contains('\\')) {
                return 'Name cannot contain / or \\';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.grey.shade500),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildListTile(
            title: 'Category *',
            subtitle: wordCategory.isEmpty ? 'No category selected' : wordCategory,
            onTap: () => showSymbolCategoryDialog(context, wordCategory, (newCategory) {
              setState(() {
                wordCategory = newCategory;
                _hasUnsavedChanges = true;
              });
            }),
          ),
          _buildListTile(
            title: 'Audio',
            subtitle: wordAudio.isEmpty ? 'No audio recorded' : 'Audio recorded',
            onTap: () => showAddEditAudioDialog(
              context,
              wordAudio,
                  (newAudio) {
                setState(() {
                  if (wordAudio != newAudio) {
                    _deleteFileFromStorage(wordAudio);
                  }
                  wordAudio = newAudio;
                  _hasUnsavedChanges = true;
                });
              },
              boardId: widget.boardId,
              symbolId: widget.symbolId,
            ),
          ),
          _buildListTile(
            title: 'Video',
            subtitle: wordVideo.isEmpty ? 'No video selected' : 'Video selected',
            onTap: () => showAddEditVideoDialog(context, wordVideo, (newVideo) {
              setState(() {
                if (wordVideo != newVideo) {
                  _deleteFileFromStorage(wordVideo);
                }
                wordVideo = newVideo;
                _hasUnsavedChanges = true;
              });
            }),
          ),
          LinkBoardMod(
            isLinked: isLinked != null,
            linkedBoard: isLinked?.id,
            currentBoardId: widget.boardId,
            userId: widget.userId,
            onLinkChanged: (isLinked, boardId) {
              setState(() {
                this.isLinked = isLinked ? FirebaseFirestore.instance.collection('board').doc(boardId) : null;
                _hasUnsavedChanges = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(Icons.add, size: 50, color: Color.fromARGB(255, 177, 176, 176));
    } else if (imageUrl.toLowerCase().endsWith('.svg')) {
      // SVG image
      return SvgPicture.network(imageUrl, fit: BoxFit.cover);
    } else if (imageUrl.startsWith('http')) {
      // URL image
      return Image.network(imageUrl, fit: BoxFit.cover);
    } else {
      // Local file
      return Image.file(File(imageUrl), fit: BoxFit.cover);
    }
  }

  Widget _buildListTile({required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade500),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        title: GText(title),
        subtitle: GText(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: onTap,
      ),
    );
  }

  Future<void> _confirmCancel() async {
    if (_hasUnsavedChanges) {
      bool? discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: GText('Discard changes?'),
          content: GText('Are you sure you want to discard all changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: GText('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: GText('Yes'),
            ),
          ],
        ),
      );
      if (discard == true) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmSave() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: GText('Confirm Save'),
        content: GText('Are you sure you want to save the changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: GText('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: GText('Yes'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _saveSymbol();
    }
  }

  Future<void> _confirmDelete() async {
    bool? delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: GText('Confirm Delete'),
        content: GText('Are you sure you want to delete this symbol?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: GText('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: GText('Yes'),
          ),
        ],
      ),
    );
    if (delete == true) {
      await _deleteSymbol();
      widget.refreshParent(); // Refresh the parent widget
      Navigator.pop(context);
    }
  }

  Future<void> _deleteSymbol() async {
    try {
      if (wordImage.isNotEmpty && wordImage.startsWith('http')) {
        await _deleteFileFromStorage(wordImage);
      }

      if (wordAudio.isNotEmpty && wordAudio.startsWith('http')) {
        await _deleteFileFromStorage(wordAudio);
      }

      if (wordVideo.isNotEmpty && wordVideo.startsWith('http')) {
        await _deleteFileFromStorage(wordVideo);
      }

      await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardId)
          .collection('words')
          .doc(widget.symbolId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Error deleting symbol: $e')),
      );
    }
  }

  Future<void> _deleteFileFromStorage(String imagePath) async {
    if (imagePath.contains('http') && imagePath.contains('firebase')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(imagePath);
        await ref.delete();
      } catch (e) {
        /*ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: GText('Error deleting file from storage: $e')),
        );*/
      }
    }
  }

  void _handleImageReplacement(String newImage) {
    if (_previousImageUrl != null) {
      if (_previousImageUrl!.startsWith('http') && _previousImageUrl!.contains('firebase')) {
        _deleteFileFromStorage(_previousImageUrl!);
      }
      if (newImage.startsWith('http')) {
        if (_previousImageUrl!.startsWith('http') && _previousImageUrl!.contains('firebase')) {
          _deleteFileFromStorage(_previousImageUrl!);
        }
      }
    }
  }

  Future<void> _saveSymbol() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String finalWordImage = wordImage;
      String finalWordAudio = wordAudio;
      String finalWordVideo = wordVideo;
      String fileName = 'Board ${widget.boardId} - "${_nameController.text}"';

      try {
        final storageRef = FirebaseStorage.instance.ref();

        // Handle wordImage
        if (_previousImageUrl != wordImage) {
          if (_previousImageUrl != null && _previousImageUrl!.startsWith('http') && _previousImageUrl!.contains('firebase')) {
            await _deleteFileFromStorage(_previousImageUrl!);
          }
          if (!wordImage.startsWith('http') && wordImage.isNotEmpty) {
            File imageFile = File(wordImage);
            Uint8List imageBytes = await imageFile.readAsBytes();
            final imageRef = storageRef.child('media/images/$fileName.jpg');
            await imageRef.putData(imageBytes);
            finalWordImage = await imageRef.getDownloadURL();
          }
        }

        // Handle wordAudio
        if (_previousAudioUrl != wordAudio && _previousAudioUrl != null && _previousAudioUrl!.startsWith('http') && _previousAudioUrl!.contains('firebase')) {
          await _deleteFileFromStorage(_previousAudioUrl!);
        }
        if (!wordAudio.startsWith('http') && wordAudio.isNotEmpty) {
          File audioFile = File(wordAudio);
          Uint8List audioBytes = await audioFile.readAsBytes();
          final audioRef = storageRef.child('media/audio/$fileName.mp3');
          await audioRef.putData(audioBytes);
          finalWordAudio = await audioRef.getDownloadURL();
        }

        // Handle wordVideo
        if (_previousVideoUrl != wordVideo && _previousVideoUrl != null && _previousVideoUrl!.startsWith('http') && _previousVideoUrl!.contains('firebase')) {
          await _deleteFileFromStorage(_previousVideoUrl!);
        }
        if (!wordVideo.startsWith('http') && wordVideo.isNotEmpty) {
          File videoFile = File(wordVideo);
          Uint8List videoBytes = await videoFile.readAsBytes();
          final videoRef = storageRef.child('media/videos/$fileName.mp4');
          await videoRef.putData(videoBytes);
          finalWordVideo = await videoRef.getDownloadURL();
        }

        Map<String, dynamic> data = {
          'wordName': _nameController.text,
          'wordDesc': _descController.text,
          'wordImage': finalWordImage,
          'wordAudio': finalWordAudio,
          'wordVideo': finalWordVideo,
          'wordCategory': wordCategory,
          'isLinked': isLinked,
        };

        await FirebaseFirestore.instance
            .collection('board')
            .doc(widget.boardId)
            .collection('words')
            .doc(widget.symbolId)
            .update(data);

        _hasUnsavedChanges = false;
        widget.refreshParent();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: GText('Error saving symbol: $e')),
        );
      }
    }
  }
}
