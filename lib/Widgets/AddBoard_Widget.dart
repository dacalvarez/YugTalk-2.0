import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:gtext/gtext.dart';

class AddBoardWidget extends StatefulWidget {
  final String userID;
  final VoidCallback onBoardAdded;
  bool isActivityBoard;

  AddBoardWidget({
    super.key,
    this.isActivityBoard = false,
    required this.userID,
    required this.onBoardAdded,
  });

  @override
  _AddBoardWidgetState createState() => _AddBoardWidgetState();
}

class _AddBoardWidgetState extends State<AddBoardWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customCategoryController =
  TextEditingController();
  final TextEditingController _customRowsController = TextEditingController();
  final TextEditingController _customColumnsController =
  TextEditingController();
  String? _selectedDimension;
  String? _selectedLanguage;
  String? _selectedCategory;
  bool _isCustomDimension = false;

  static const List<String> _commonDimensions = [
    '2x2',
    '3x3',
    '4x4',
    '5x5',
    '6x6',
    '7x7',
    '8x8',
    '8x10',
    '10x10',
    '4x6'
  ];

  static const List<String> _languages = ['Filipino', 'English'];
  final List<String> _categories = [
    'Basic Needs',
    'Cognitive and Language Development',
    'Social Interaction',
    'Academic Support',
    'None',
    'Other'
  ];

  Future<int> _getNextDocumentID(BuildContext context) async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('board').get();
      List<int> ids =
      querySnapshot.docs.map((doc) => int.parse(doc.id)).toList();
      return ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1;
    } catch (e) {
      print('Error fetching next document ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Failed to fetch next document ID: $e')),
      );
      return -1;
    }
  }

  Future<void> _addBoard(BuildContext parentContext, String name,
      String category, int rows, int columns, String language) async {
    try {
      int newID = await _getNextDocumentID(parentContext);
      if (newID == -1) return;

      DocumentReference boardRef =
      FirebaseFirestore.instance.collection('board').doc(newID.toString());

      DateTime now = DateTime.now();
      DateTime dateOnly = DateTime(now.year, now.month, now.day);

      await boardRef.set({
        'name': name,
        'ownerID': widget.userID,
        'category': category,
        'isMain': false,
        'rows': rows,
        'columns': columns,
        'language': language,
        'connectedForm': name,
        'dateCreated': Timestamp.fromDate(dateOnly),
        'isActivityBoard': widget.isActivityBoard,
      });

      await boardRef
          .collection('words')
          .doc('placeholder')
          .set({'initialized': true});

      widget.onBoardAdded();
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: GText('Board Added Successfully')),
      );
    } catch (e) {
      print('Error adding board: $e');
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: GText('Failed to add board: $e')),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool enabled = true, bool isRequired = true}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[1000] : Colors.grey[200],
          suffixIcon: isRequired
              ? const Icon(Icons.star, color: Colors.red, size: 10)
              : null,
        ),
        enabled: enabled,
        validator: isRequired
            ? (value) => value!.isEmpty ? 'This field is required' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged,
      {bool isRequired = true}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[1000] : Colors.grey[200],
          suffixIcon: isRequired
              ? const Icon(Icons.star, color: Colors.red, size: 10)
              : null,
        ),
        value: value,
        isExpanded: true,
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        validator: isRequired
            ? (value) => value == null ? 'This field is required' : null
            : null,
      ),
    );
  }

  Future<void> _showAddBoardDialog(BuildContext parentContext) async {
    _nameController.clear();
    _customCategoryController.clear();
    _customRowsController.clear();
    _customColumnsController.clear();
    setState(() {
      _selectedDimension = null;
      _isCustomDimension = false;
      _selectedLanguage = null;
      _selectedCategory = null;
    });

    double width = MediaQuery.of(parentContext).size.width * 0.30;
    double height = MediaQuery.of(parentContext).size.height * 0.40;

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: GText('Add New Board'),
              content: Container(
                width: width,
                height: height,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildTextField(_nameController, 'Board Name'),
                        _buildDropdown(
                          'Category',
                          _selectedCategory,
                          _categories,
                              (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          },
                        ),
                        if (_selectedCategory == 'Other')
                          _buildTextField(_customCategoryController,
                              'Enter Custom Category'),
                        _buildDropdown(
                          'Language',
                          _selectedLanguage,
                          _languages,
                              (String? newValue) {
                            setState(() {
                              _selectedLanguage = newValue;
                            });
                          },
                        ),
                        _buildDropdown(
                          'Board Dimensions',
                          _selectedDimension,
                          [..._commonDimensions, 'Custom'],
                              (String? newValue) {
                            setState(() {
                              _selectedDimension = newValue;
                              _isCustomDimension =
                                  _selectedDimension == 'Custom';
                              if (!_isCustomDimension &&
                                  _selectedDimension != null) {
                                List<String> dims =
                                _selectedDimension!.split('x');
                                _customRowsController.text = dims[0];
                                _customColumnsController.text = dims[1];
                              } else {
                                _customRowsController.clear();
                                _customColumnsController.clear();
                              }
                            });
                          },
                        ),
                        if (_isCustomDimension)
                          Row(
                            children: [
                              Expanded(
                                  child: _buildTextField(
                                      _customRowsController, 'Rows',
                                      enabled: _isCustomDimension)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _buildTextField(
                                      _customColumnsController, 'Columns',
                                      enabled: _isCustomDimension)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: GText('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: GText('Add'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      int rows, columns;
                      if (_isCustomDimension) {
                        rows = int.tryParse(_customRowsController.text) ?? 4;
                        columns =
                            int.tryParse(_customColumnsController.text) ?? 4;
                      } else if (_selectedDimension != null) {
                        List<String> dims = _selectedDimension!.split('x');
                        rows = int.parse(dims[0]);
                        columns = int.parse(dims[1]);
                      } else {
                        rows = 4;
                        columns = 4;
                      }
                      String category = _selectedCategory == 'Other'
                          ? _customCategoryController.text
                          : _selectedCategory!;
                      Navigator.of(context).pop();
                      _addBoard(parentContext, _nameController.text, category,
                          rows, columns, _selectedLanguage!);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await _showAddBoardDialog(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(115, 73, 189, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        minimumSize: const Size(100, 50),
      ),
      child: GText('Add Board', style: TextStyle(color: Colors.white)),
    );
  }
}