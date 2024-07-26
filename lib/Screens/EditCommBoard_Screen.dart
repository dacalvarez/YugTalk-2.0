import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gtext/gtext.dart';
import '../Modules/EditMode/EditBoard_Mod.dart';
import './AddSymbol_Screen.dart';

class CommBoard_Edit extends StatefulWidget {
  final String boardID;
  final String userID;
  final Function() refreshParent;

  const CommBoard_Edit({Key? key, required this.boardID, required this.userID, required this.refreshParent}) : super(key: key);

  @override
  _CommBoard_EditState createState() => _CommBoard_EditState();
}

class _CommBoard_EditState extends State<CommBoard_Edit> {
  String boardName = "Communication Board";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBoardName();
  }

  Future<void> _fetchBoardName() async {
    try {
      DocumentSnapshot boardSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .get();

      if (boardSnapshot.exists) {
        var boardData = boardSnapshot.data() as Map<String, dynamic>;
        setState(() {
          boardName = boardData['name'] ?? "Communication Board";
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _refreshBoard() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(boardName),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.refreshParent(); // Refresh the parent view
            Navigator.of(context).pop(true); // Return true to indicate changes were made
          },
        ),
        actions: [
          if (MediaQuery.of(context).size.width > 600)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: ElevatedButton(
                onPressed: () async {
                  bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddSymbol(
                        boardId: widget.boardID,
                        userId: widget.userID,
                        refreshParent: _refreshBoard,
                      ),
                    ),
                  );
                  if (result == true) {
                    _refreshBoard();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: GText('Add Symbol'),
              ),
            ),
          if (MediaQuery.of(context).size.width <= 600)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSymbol(
                      boardId: widget.boardID,
                      userId: widget.userID,
                      refreshParent: _refreshBoard,
                    ),
                  ),
                );
                if (result == true) {
                  _refreshBoard();
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20), // Added padding to top and bottom
        child: Column(
          children: [
            Expanded(
              child: EditBoard_Mod(boardID: widget.boardID, userID: widget.userID, refreshParent: _refreshBoard),
            ),
          ],
        ),
      ),
    );
  }
}
