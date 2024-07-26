import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gtext/gtext.dart';
import '../Modules/Symbol/AddEditImage_Mod.dart';
import '../Modules/Symbol/LinkBoard_Mod.dart';
import '../Modules/Symbol/SymbolCategory_Mod.dart';

class AddSymbol extends StatefulWidget {
  final String userId;
  final String boardId;
  final Function() refreshParent;

  const AddSymbol({
    Key? key,
    required this.boardId,
    required this.userId,
    required this.refreshParent,
  }) : super(key: key);

  @override
  _AddSymbolState createState() => _AddSymbolState();
}

class _AddSymbolState extends State<AddSymbol> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String wordImage;
  late String wordCategory;
  DocumentReference? isLinked;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    wordImage = '';
    wordCategory = '';
    isLinked = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  GText('Add Symbol'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmCancel,
        ),
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
                wordImage = newImage;
                _hasUnsavedChanges = true;
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
                child: wordImage.isEmpty
                    ? Icon(Icons.add, size: 50, color: Colors.grey.shade700)
                    : _buildImageContainer(wordImage),
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
    try {
      if (_formKey.currentState!.validate()) {
        if (wordImage.isEmpty || wordCategory.isEmpty) {
          _showErrorDialog('Please ensure that the symbol has an image, name, and category.');
          return;
        }

        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: GText('Confirm Save'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GText(
                  'Are you sure you want to save the changes?',
                ),
                SizedBox(height: 10),
                GText(
                  'Note: To add audio or video, go to edit symbol.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
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
      } else {
        _showErrorDialog('Please fill out the required fields.');
      }
    } catch (e) {
      _showErrorDialog('An unexpected error occurred. Please try again.');
    }
  }

  Future<int> _getNextDocumentID(BuildContext context) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('board').doc(widget.boardId).collection('words').get();
      List<int> ids = querySnapshot.docs.map((doc) => int.parse(doc.id)).toList();
      if (ids.isEmpty) {
        return 1;
      } else {
        ids.sort();
        return ids.last + 1;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Failed to fetch next document ID: $e')),
      );
      return -1; // Return an invalid ID or handle appropriately
    }
  }

  Future<void> _saveSymbol() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String finalWordImage = wordImage;

      if (!wordImage.startsWith('http') && !kIsWeb) {
        try {
          File imageFile = File(wordImage);
          Uint8List imageBytes = await imageFile.readAsBytes();
          String fileName = 'Board ${widget.boardId} - "${_nameController.text}"';        
          Reference ref = FirebaseStorage.instance.ref().child('media/images/$fileName');
          TaskSnapshot uploadTask = await ref.putData(imageBytes);
          finalWordImage = await ref.getDownloadURL();
        } catch (e) {
          _showErrorDialog('Failed to upload image. Please try again.');
          return;
        }
      }

      Map<String, dynamic> data = {
        'wordName': _nameController.text,
        'wordDesc': _descController.text,
        'wordImage': finalWordImage,
        'wordCategory': wordCategory,
        'isLinked': isLinked,
        'wordAudio': '',
        'wordVideo': '',
        'usageCount': 0 // Initialize usageCount to 0
      };

      try {
        int newId = await _getNextDocumentID(context);
        if (newId == -1) {
          // Handle invalid ID case appropriately
          return;
        }

        await FirebaseFirestore.instance
            .collection('board')
            .doc(widget.boardId)
            .collection('words')
            .doc(newId.toString())
            .set(data);

        _hasUnsavedChanges = false;
        widget.refreshParent();
        Navigator.pop(context);
      } catch (e) {
        _showErrorDialog('Failed to save symbol. Please try again.');
      }
    }
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

  Widget _buildImageContainer(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
        },
      );
    } else if (imagePath.isNotEmpty) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
        },
      );
    } else {
      return const Icon(Icons.broken_image);
    }
  }
}
