import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import '../Modules/CommBoard/CommBoard_Mod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Modules/CommBoard/MoreOptions_Mod.dart';

class LinkedBoardDisplay extends StatefulWidget {
  final String boardID;
  final VoidCallback onBack;
  final bool isEditMode;

  const LinkedBoardDisplay({
    Key? key,
    required this.boardID,
    required this.onBack,
    required this.isEditMode,
  }) : super(key: key);

  @override
  _LinkedBoardDisplayState createState() => _LinkedBoardDisplayState();
}

class _LinkedBoardDisplayState extends State<LinkedBoardDisplay> {
  String? boardName;
  bool isLoading = true;
  bool incrementUsageCount = true;
  bool translate = false;
  String currentLanguage = 'en-US'; // Default language

  final String puzzleQuestion = 'What is 6 x 5?';
  final String puzzleAnswer = '30';

  @override
  void initState() {
    super.initState();
    _fetchBoardName();
  }

  Future<void> _fetchBoardName() async {
    try {
      DocumentSnapshot boardSnapshot = await FirebaseFirestore.instance.collection('board').doc(widget.boardID).get();
      if (boardSnapshot.exists) {
        var boardData = boardSnapshot.data() as Map<String, dynamic>;
        setState(() {
          boardName = boardData['name'] ?? 'Linked Board';
          currentLanguage = boardData['language'] ?? 'en-US';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          boardName = 'Linked Board';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Error fetching board name: $e')),
      );
    }
  }

  void _showPuzzleDialog(Function onSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents the dialog from being dismissed by tapping outside
      builder: (context) {
        final TextEditingController answerController = TextEditingController();
        return AlertDialog(
          title: GText('Solve the Puzzle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              GText(puzzleQuestion),
              const SizedBox(height: 20),
              TextField(
                controller: answerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Enter your answer'),
              ),
              const SizedBox(height: 20),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog when Cancel is pressed
              },
              child: GText('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (answerController.text == puzzleAnswer) {
                  Navigator.of(context).pop();
                  onSuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: GText('Puzzle solved successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: GText('Incorrect answer, please try again.')),
                  );
                }
              },
              child: GText('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showMoreOptions() {
    _showPuzzleDialog(() {
      showDialog(
        context: context,
        builder: (context) => MoreOptions(
          translate: translate,
          incrementUsageCount: incrementUsageCount,
          currentLanguage: currentLanguage,
        ),
      ).then((result) {
        if (result != null) {
          setState(() {
            translate = result['translate'];
            incrementUsageCount = result['incrementUsageCount'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: GText('No changes were made.')),
          );
        }
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: GText('Error displaying options: $e')),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: GText('Loading...'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GText(boardName ?? 'Linked Board'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
          const Padding(padding: EdgeInsets.only(right: 10)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: CommBoard_Mod(
          boardID: widget.boardID,
          isEditMode: widget.isEditMode,
          incrementUsageCount: incrementUsageCount,
          translate: translate,
        ),
      ),
    );
  }
}
