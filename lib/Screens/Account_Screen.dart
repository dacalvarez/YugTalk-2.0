import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gtext/gtext.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? loggedInEmail;
  List<CameraDescription> cameras = [];
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianPhoneController = TextEditingController();
  String _originalFullName = '';
  String _originalAge = '';
  String _originalGuardianName = '';
  String _originalGuardianPhone = '';
  bool _isEditing = false;
  bool isMounted = true;

  @override
  void initState() {
    super.initState();
    loggedInEmail = FirebaseAuth.instance.currentUser?.email;
    getUserData(loggedInEmail!);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    isMounted = false;
    super.dispose();
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _fullNameController.text = _originalFullName;
      _ageController.text = _originalAge;
      _guardianNameController.text = _originalGuardianName;
      _guardianPhoneController.text = _originalGuardianPhone;
    });
  }

  void _saveChanges() async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: loggedInEmail)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        await userSnapshot.docs.first.reference.update({
          'fullName': _fullNameController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'guardianName': _guardianNameController.text,
          'guardianNo': _guardianPhoneController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: GText('Changes saved successfully.'),
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GText('Error saving changes: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _changePassword(BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: FirebaseAuth.instance.currentUser!.email!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: GText('Password reset email sent. Check your inbox.'),
        duration: Duration(seconds: 5),
      ));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: GText('Failed to send password reset email: $error'),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GText("Select Profile Picture"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _captureImage();
                  },
                  child: GText("Camera"),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                  child: GText("Gallery"),
                ),
                const SizedBox(height: 20),
                GText(
                  "* Please do not upload pictures exceeding 1 MiB.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickImage() async {
    if (!kIsWeb) {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _showLoadingDialog(); // Show loading dialog

        final bytes = await File(pickedFile.path).readAsBytes();

        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: 1024,
          minWidth: 1024,
          quality: 80,
        );

        final imageData = base64Encode(compressedBytes);

        QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('user').where('email', isEqualTo: loggedInEmail).get();
        if (userSnapshot.docs.isNotEmpty) {
          await userSnapshot.docs.first.reference.update({
            'profilePicture': imageData,
          }).then((value) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: GText('Profile picture updated successfully.'),
                duration: Duration(seconds: 3),
              ),
            );
            setState(() {});
          }).catchError((error) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: GText('Failed to update profile picture: $error'),
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }
      }
    } else {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files!.length == 1) {
          final file = files[0];
          final reader = html.FileReader();

          reader.onLoadEnd.listen((e) async {
            _showLoadingDialog(); // Show loading dialog

            final bytes = Uint8List.fromList(reader.result as List<int>);

            final compressedBytes = await FlutterImageCompress.compressWithList(
              bytes,
              minHeight: 1024,
              minWidth: 1024,
              quality: 80,
            );

            final imageData = base64Encode(compressedBytes);

            QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('user').where('email', isEqualTo: loggedInEmail).get();
            if (userSnapshot.docs.isNotEmpty) {
              await userSnapshot.docs.first.reference.update({
                'profilePicture': imageData,
              }).then((value) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: GText('Profile picture updated successfully.'),
                    duration: Duration(seconds: 3),
                  ),
                );
                setState(() {});
              }).catchError((error) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: GText('Failed to update profile picture: $error'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }
          });

          reader.readAsArrayBuffer(file);
        }
      });
    }
  }

  void _captureImage() async {
    if (!mounted) return;

    try {
      if (cameras.isEmpty) {
        cameras = await availableCameras();
      }

      final CameraDescription camera = cameras.first;
      final CameraController controller = CameraController(
        camera,
        ResolutionPreset.max,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;

      final BuildContext dialogContext = context;

      showDialog(
        context: dialogContext,
        builder: (BuildContext context) => AlertDialog(
          title: GText("Capture Image"),
          content: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                try {
                  final XFile imageFile = await controller.takePicture();
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop(); // Close the camera preview dialog

                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (BuildContext context) => const AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          GText("Processing image..."),
                        ],
                      ),
                    ),
                  );

                  final bytes = await File(imageFile.path).readAsBytes();

                  final compressedBytes = await FlutterImageCompress.compressWithList(
                    bytes,
                    minHeight: 1024,
                    minWidth: 1024,
                    quality: 80,
                  );

                  if (!mounted) return;

                  if (compressedBytes.length > 1048576) {
                    Navigator.of(dialogContext).pop(); // Close loading dialog
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: GText('The picture is too big. Please choose a smaller image.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }

                  final imageData = base64Encode(compressedBytes);

                  await FirebaseFirestore.instance.collection('user').where('email', isEqualTo: loggedInEmail).get().then((querySnapshot) {
                    querySnapshot.docs.first.reference.update({
                      'profilePicture': imageData,
                    }).then((_) {
                      if (!mounted) return;
                      Navigator.of(dialogContext).pop(); // Close loading dialog
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: GText('Profile picture updated successfully.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      setState(() {});
                    }).catchError((error) {
                      if (!mounted) return;
                      Navigator.of(dialogContext).pop(); // Close loading dialog
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: GText('Failed to update profile picture: $error'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    });
                  });
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop(); // Close loading dialog
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: GText("Error capturing image: $e"),
                    ),
                  );
                }
              },
              child: GText("Capture"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: GText("Cancel"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GText("Error initializing camera: $e"),
        ),
      );
    }
  }

  Future<void> getUserData(String email) async {
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('user').get();

    for (QueryDocumentSnapshot userDoc in userSnapshot.docs) {
      int subcollectionIndex = 1;
      bool subcollectionFound = true;

      while (subcollectionFound) {
        QuerySnapshot querySnapshot = await userDoc.reference.collection('$subcollectionIndex').where('email', isEqualTo: email).get();

        if (querySnapshot.docs.isNotEmpty) {
          print('Email found in subcollection: $subcollectionIndex, Document: ${userDoc.id}');
        } else {
          subcollectionFound = false;
        }
        subcollectionIndex++;
      }
    }
  }


  Widget _buildEditableField(BuildContext context, String label, TextEditingController controller, {bool isPhoneNumber = false}) {
    final TextStyle labelStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold);
    final TextStyle valueStyle = Theme.of(context).textTheme.bodyMedium!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(top: 8),
              child: GText(
                '$label',
                style: labelStyle,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerLeft,
              child: _isEditing
                  ? SizedBox(
                width: 200,
                child: TextField(
                  controller: controller,
                  style: valueStyle,
                  keyboardType: isPhoneNumber ? TextInputType.phone : (label == 'Age' ? TextInputType.number : TextInputType.text),
                  inputFormatters: [
                    if (isPhoneNumber)
                      FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*$'))
                    else if (label == 'Age')
                      FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  controller.text,
                  style: valueStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              GText("Processing image..."),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldMessengerKey,
      appBar: AppBar(
        title: GText('Your Account'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEditing,
            ),
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                _originalFullName = _fullNameController.text;
                _originalAge = _ageController.text;
                _originalGuardianName = _guardianNameController.text;
                _originalGuardianPhone = _guardianPhoneController.text;
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user')
            .where('email', isEqualTo: loggedInEmail)
            .snapshots()
            .map((snapshot) => snapshot.docs.first),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: GText('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: GText('No user data found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          _fullNameController.text = data['fullName'] ?? '';
          _ageController.text = (data['age'] ?? '').toString();
          _guardianNameController.text = data['guardianName'] ?? '';
          _guardianPhoneController.text = data['guardianNo'] ?? '';

          final List<String> nameParts = _fullNameController.text.split(' ');
          final String username = nameParts.isNotEmpty ? nameParts.first : '';

          return SingleChildScrollView(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      GestureDetector(
                        onTap: () {
                          _showImagePickerDialog(context);
                        },
                        child: CircleAvatar(
                          radius: 120,
                          backgroundImage: data['profilePicture'] != null
                              ? Image.memory(
                            base64Decode(data['profilePicture']),
                            fit: BoxFit.cover,
                          ).image
                              : const AssetImage('assets/images/profile_picture.jpg'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GText(
                        username,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField(context, 'Full Name:', _fullNameController),
                      _buildEditableField(context, 'Age:', _ageController, isPhoneNumber: true),
                      _buildEditableField(context, 'Guardian:', _guardianNameController),
                      _buildEditableField(context, 'Guardian Phone Number', _guardianPhoneController, isPhoneNumber: true),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _changePassword(context),
                        style: ButtonStyle(
                          textStyle: WidgetStateProperty.all(
                            Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        child: GText('Change Password'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}