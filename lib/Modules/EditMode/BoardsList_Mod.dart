import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gtext/gtext.dart';
import '/Screens/ViewCommBoard_Screen.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BoardsListWidget extends StatefulWidget {
  final String userID;
  final bool showActivityBoards;
  final bool showOnlyActivityBoards;

  const BoardsListWidget({
    Key? key,
    required this.userID,
    this.showActivityBoards = false,
    this.showOnlyActivityBoards = false,
  }) : super(key: key);

  @override
  BoardsListWidgetState createState() => BoardsListWidgetState();
}

class BoardsListWidgetState extends State<BoardsListWidget> {
  List<Map<String, dynamic>> _boards = [];
  List<Map<String, dynamic>> _filteredBoards = [];
  String _searchQuery = '';
  String? _selectedLanguage;
  String? _selectedDimensions;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _ensureSingleMainBoard();
    _fetchBoards();
  }

  Future<void> _ensureSingleMainBoard() async {
    QuerySnapshot userBoards = await FirebaseFirestore.instance
        .collection('board')
        .where('ownerID', isEqualTo: widget.userID)
        .get();

    List<QueryDocumentSnapshot> mainBoards = userBoards.docs
        .where((doc) => (doc.data() as Map<String, dynamic>)['isMain'] == true)
        .toList();

    if (mainBoards.isEmpty && userBoards.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('board')
          .doc(userBoards.docs.first.id)
          .update({'isMain': true});
    } else if (mainBoards.length > 1) {
      for (int i = 1; i < mainBoards.length; i++) {
        await FirebaseFirestore.instance
            .collection('board')
            .doc(mainBoards[i].id)
            .update({'isMain': false});
      }
    }
  }

  Future<void> _fetchBoards() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('board').get();

      List<Map<String, dynamic>> boards = querySnapshot.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool isDefault = data['isDefault'] ?? false;
        List<dynamic> hiddenBy = data['hiddenBy'] ?? [];
        String ownerID = data['ownerID'] ?? '';
        bool isActivityBoard = data['isActivityBoard'] ?? false;

        if (hiddenBy.contains(widget.userID)) {
          return false;
        }

        if (widget.showOnlyActivityBoards) {
          return isActivityBoard && ownerID == widget.userID;
        }

        if (!widget.showActivityBoards && isActivityBoard) {
          return false;
        }

        if (isDefault || ownerID == widget.userID) {
          return true;
        }

        return false;
      }).map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'],
          'isDefault': data['isDefault'] ?? false,
          'isMain': data['isMain'] ?? false,
          'category':
          data['category']?.isEmpty ?? true ? 'None' : data['category'],
          'language': (data['language'] ?? 'Filipino').toString().replaceFirst(
              data['language'][0], data['language'][0].toUpperCase()),
          'rows': data['rows'] ?? 4,
          'columns': data['columns'] ?? 4,
          'dateCreated': data['dateCreated'] != null
              ? DateFormat('MMMM d, yyyy')
              .format((data['dateCreated'] as Timestamp).toDate())
              : '',
          'isActivityBoard': data['isActivityBoard'] ?? false,
        };
      }).toList();

      boards.sort((a, b) {
        if (a['isMain'] == true) {
          return -1;
        } else if (b['isMain'] == true) {
          return 1;
        } else {
          return 0;
        }
      });

      setState(() {
        _boards = boards;
        _filterBoards();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching boards: $e')),
      );
    }
  }

  void _filterBoards() {
    setState(() {
      _filteredBoards = _boards.where((board) {
        bool matchesSearch =
        board['name'].toLowerCase().contains(_searchQuery.toLowerCase());
        bool matchesLanguage =
            _selectedLanguage == null || board['language'] == _selectedLanguage;
        bool matchesDimensions = _selectedDimensions == null ||
            '${board['rows']}x${board['columns']}' == _selectedDimensions;
        bool matchesCategory =
            _selectedCategory == null || board['category'] == _selectedCategory;
        bool isActivityBoard = board['isActivityBoard'] ?? false;
        return matchesSearch &&
            matchesLanguage &&
            matchesDimensions &&
            matchesCategory;
      }).toList();
    });
  }

  Future<void> _setMainBoard(int index) async {
    final board = _filteredBoards[index];

    if (board['isDefault']) {
      await _duplicateAndHideDefaultBoard(index, board['name'],
          setAsMain: true);
    } else {
      final newMainBoardID = board['id'];

      final batch = FirebaseFirestore.instance.batch();

      QuerySnapshot userBoards = await FirebaseFirestore.instance
          .collection('board')
          .where('ownerID', isEqualTo: widget.userID)
          .get();
      for (var doc in userBoards.docs) {
        batch.update(doc.reference, {'isMain': false});
      }

      batch.update(
          FirebaseFirestore.instance.collection('board').doc(newMainBoardID),
          {'isMain': true});

      await batch.commit();
      setState(() {
        _fetchBoards();
      });
    }
  }

  Future<void> _showEditDialog(int index) async {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _categoryController = TextEditingController();
    final TextEditingController _rowsController = TextEditingController();
    final TextEditingController _columnsController = TextEditingController();
    String? _selectedLanguage;
    const List<String> _languages = ['Filipino', 'English'];
    final board = _filteredBoards[index];
    final boardID = board['id'];
    final boardDoc =
    await FirebaseFirestore.instance.collection('board').doc(boardID).get();
    final boardData = boardDoc.data();

    if (board['isDefault']) {
      await _duplicateAndHideDefaultBoard(index, board['name'], edit: true);
    } else {
      if (boardData != null) {
        _nameController.text = boardData['name'];
        _categoryController.text = boardData['category'];
        _rowsController.text = boardData['rows'].toString();
        _columnsController.text = boardData['columns'].toString();
        _selectedLanguage = boardData['language'];
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: GText('Edit Board'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _nameController,
                      decoration:
                      const InputDecoration(labelText: 'Board Name'),
                    ),
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    TextField(
                      controller: _rowsController,
                      decoration: const InputDecoration(labelText: 'Rows'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    TextField(
                      controller: _columnsController,
                      decoration: const InputDecoration(labelText: 'Columns'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: GText('Language',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Column(
                      children: _languages.map((language) {
                        return RadioListTile<String>(
                          title: GText(language),
                          value: language,
                          groupValue: _selectedLanguage,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: GText('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: GText('Save'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _editBoard(
                        index,
                        _nameController.text,
                        _categoryController.text,
                        int.parse(_rowsController.text),
                        int.parse(_columnsController.text),
                        _selectedLanguage,
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  void _editBoard(int index, String newName, String newCategory, int newRows,
      int newColumns, String? newLanguage) async {
    final boardID = _filteredBoards[index]['id'];
    try {
      await FirebaseFirestore.instance.collection('board').doc(boardID).update({
        'name': newName,
        'category': newCategory,
        'rows': newRows,
        'columns': newColumns,
        'language': newLanguage,
      });
      setState(() {
        _fetchBoards();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: GText('Board edited successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Failed to edit board: $e')),
      );
    }
  }

  void _duplicateBoard(int index) async {
    final board = _filteredBoards[index];

    if (board['isDefault']) {
      await _duplicateAndHideDefaultBoard(index, board['name']);
    } else {
      final boardID = board['id'];
      final boardDoc = await FirebaseFirestore.instance
          .collection('board')
          .doc(boardID)
          .get();
      final boardData = boardDoc.data();

      if (boardData != null) {
        int newID = await _getNextDocumentID();
        try {
          await FirebaseFirestore.instance
              .collection('board')
              .doc(newID.toString())
              .set({
            'name': '${boardData['name']} (Copy)',
            'ownerID': widget.userID,
            'category': boardData['category'],
            'isMain': false,
            'rows': boardData['rows'],
            'columns': boardData['columns'],
            'language': boardData['language'],
            'dateCreated': boardData['dateCreated'],
          });

          final wordsCollection = boardDoc.reference.collection('words');
          final newWordsCollection = FirebaseFirestore.instance
              .collection('board')
              .doc(newID.toString())
              .collection('words');
          final wordsSnapshot = await wordsCollection.get();
          for (var wordDoc in wordsSnapshot.docs) {
            await newWordsCollection.doc(wordDoc.id).set(wordDoc.data());
          }

          setState(() {
            _fetchBoards();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: GText('Board duplicated successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: GText('Failed to duplicate board: $e')),
          );
        }
      }
    }
  }

  void _deleteBoard(int index) {
    final board = _filteredBoards[index];
    if (board['isMain']) {
      _showMainBoardDeleteDialog();
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: GText('Confirm Delete'),
            content: GText('Are you sure you want to delete this board?'),
            actions: <Widget>[
              TextButton(
                child: GText('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: GText('Delete'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final boardID = board['id'];

                  if (board['isDefault']) {
                    await _hideDefaultBoard(boardID);
                  } else {
                    await _deleteNonDefaultBoard(boardID);
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _hideDefaultBoard(String boardID) async {
    try {
      await FirebaseFirestore.instance.collection('board').doc(boardID).update({
        'hiddenBy': FieldValue.arrayUnion([widget.userID])
      });
      setState(() {
        _fetchBoards();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: GText('Board hidden successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: GText('Failed to hide board: $e')),
        );
      }
    }
  }

  Future<void> _deleteNonDefaultBoard(String boardID) async {
    try {
      await FirebaseFirestore.instance
          .collection('board')
          .doc(boardID)
          .delete();
      setState(() {
        _fetchBoards();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: GText('Board deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: GText('Failed to delete board: $e')),
        );
      }
    }
  }

  void _showMainBoardDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GText('Cannot Delete Main Board'),
          content: GText(
              'To delete this board, please set a different board as the main board.'),
          actions: <Widget>[
            TextButton(
              child: GText('Exit'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _duplicateAndHideDefaultBoard(int index, String boardName,
      {bool setAsMain = false, bool edit = false, bool delete = false}) async {
    final boardID = _filteredBoards[index]['id'];
    final boardDoc =
    await FirebaseFirestore.instance.collection('board').doc(boardID).get();
    final boardData = boardDoc.data();

    if (boardData != null) {
      int newID = await _getNextDocumentID();
      try {
        await FirebaseFirestore.instance
            .collection('board')
            .doc(newID.toString())
            .set({
          'name': '$boardName (Copy)',
          'ownerID': widget.userID,
          'category': boardData['category'],
          'isMain': setAsMain,
          'rows': boardData['rows'],
          'columns': boardData['columns'],
          'language': boardData['language'],
          'dateCreated': boardData['dateCreated'],
        });

        final wordsCollection = boardDoc.reference.collection('words');
        final newWordsCollection = FirebaseFirestore.instance
            .collection('board')
            .doc(newID.toString())
            .collection('words');
        final wordsSnapshot = await wordsCollection.get();
        for (var wordDoc in wordsSnapshot.docs) {
          await newWordsCollection.doc(wordDoc.id).set(wordDoc.data());
        }

        await FirebaseFirestore.instance
            .collection('board')
            .doc(boardID)
            .update({
          'hiddenBy': FieldValue.arrayUnion([widget.userID])
        });

        if (edit) {
          _showEditDialog(index);
        } else if (delete) {
          _deleteBoard(index);
        }
        setState(() {
          _fetchBoards();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: GText('Board duplicated and hidden successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: GText('Failed to duplicate and hide board: $e')),
        );
      }
    }
  }

  Future<int> _getNextDocumentID() async {
    QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('board').get();
    List<int> ids = querySnapshot.docs.map((doc) => int.parse(doc.id)).toList();
    return ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1;
  }

  void _confirmSetMainBoard(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GText('Set as Main Board'),
          content: GText(
              'Are you sure you want to set this board as the main board?'),
          actions: <Widget>[
            TextButton(
              child: GText('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: GText('Set as Main'),
              onPressed: () {
                Navigator.of(context).pop();
                _setMainBoard(index);
              },
            ),
          ],
        );
      },
    );
  }

  void refreshBoards() {
    _fetchBoards();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterBoards();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GText('Language'),
                  DropdownButton<String>(
                    hint: GText('Language'),
                    value: _selectedLanguage,
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value;
                        _filterBoards();
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: null, child: GText('All')),
                      DropdownMenuItem(
                          value: 'Filipino', child: GText('Filipino')),
                      DropdownMenuItem(
                          value: 'English', child: GText('English')),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GText('Category'),
                  DropdownButton<String>(
                    hint: GText('Category'),
                    value: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _filterBoards();
                      });
                    },
                    items: [
                      const DropdownMenuItem(value: null, child: GText('All')),
                      ..._boards.map((board) => board['category']).toSet().map(
                              (category) => DropdownMenuItem(
                              value: category, child: GText(category))),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GText('Dimensions'),
                  DropdownButton<String>(
                    hint: GText('Dimensions'),
                    value: _selectedDimensions,
                    onChanged: (value) {
                      setState(() {
                        _selectedDimensions = value;
                        _filterBoards();
                      });
                    },
                    items: [
                      const DropdownMenuItem(value: null, child: GText('All')),
                      ..._boards
                          .map(
                              (board) => '${board['rows']}x${board['columns']}')
                          .toSet()
                          .map((dimensions) => DropdownMenuItem(
                          value: dimensions, child: GText(dimensions))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SlidableAutoCloseBehavior(
            child: ListView.builder(
              itemCount: _filteredBoards.length,
              itemBuilder: (context, index) {
                final board = _filteredBoards[index];
                final languageTag = board['isDefault']
                    ? 'Language: ${board['language']} Default Board'
                    : 'Language: ${board['language']} Board';
                final dimensionsTag = '${board['rows']}x${board['columns']}';

                return Container(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey.shade300
                            : Colors.grey.shade900),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Slidable(
                      key: ValueKey(board['id']),
                      startActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _duplicateBoard(index),
                            borderRadius: BorderRadius.circular(12),
                            backgroundColor: const Color(0xFF21B7CA),
                            foregroundColor: Colors.white,
                            icon: Icons.copy,
                            label: 'Duplicate',
                          ),
                          if (!board['isDefault'] && !board['isMain'])
                            SlidableAction(
                              onPressed: (_) => _confirmSetMainBoard(index),
                              borderRadius: BorderRadius.circular(12),
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              icon: Icons.star,
                              label: 'Set as Main',
                            ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          if (!board['isDefault'])
                            SlidableAction(
                              onPressed: (_) => _showEditDialog(index),
                              borderRadius: BorderRadius.circular(12),
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                          SlidableAction(
                            onPressed: (_) => _deleteBoard(index),
                            borderRadius: BorderRadius.circular(12),
                            backgroundColor: const Color(0xFFFE4A49),
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        leading: const Icon(Icons.dashboard),
                        title: Row(
                          children: [
                            Text(board['name']),
                            /*const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: board['isActivityBoard']
                                    ? Colors.orange.shade200
                                    : Colors.blue.shade200,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: GText(
                                board['isActivityBoard']
                                    ? 'Activity Board'
                                    : 'Communication Board',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),*/
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade200,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: GText(dimensionsTag,
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GText(
                              languageTag,
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey),
                            ),
                            GText(
                              'Category: ${board['category']}',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey),
                            ),
                            if (!board['isDefault'])
                              GText(
                                'Date Created: ${board['dateCreated']}',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: board['isMain']
                            ? const Icon(Icons.star, color: Colors.yellow)
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommBoard_View(
                                boardID: board['id'],
                                userID: widget.userID,
                              ),
                            ),
                          ).then((_) {
                            setState(() {
                              _fetchBoards();
                            });
                          });
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}