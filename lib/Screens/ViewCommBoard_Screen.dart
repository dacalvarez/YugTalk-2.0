import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gtext/gtext.dart';
import '../Modules/CommBoard/CommBoard_Mod.dart';
import './EditCommBoard_Screen.dart';
import '../Modules/CommBoard/MoreOptions_Mod.dart';

class CommBoard_View extends StatefulWidget {
  final String boardID;
  final String userID;
  final bool showBackButton;

  const CommBoard_View({
    Key? key,
    required this.boardID,
    required this.userID,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  _CommBoard_ViewState createState() => _CommBoard_ViewState();
}

class _CommBoard_ViewState extends State<CommBoard_View> {
  String boardName = 'Communication Board';
  bool isLoading = true;
  bool incrementUsageCount = true;
  bool translate = false;
  String? currentLanguage;

  @override
  void initState() {
    super.initState();
    _fetchBoardName();
  }

  Future<void> _fetchBoardName() async {
    try {
      DocumentSnapshot boardDoc = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .get();

      if (boardDoc.exists) {
        setState(() {
          boardName = boardDoc['name'];
          currentLanguage = boardDoc['language'];
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

  Future<void> _refreshBoard() async {
    setState(() {
      isLoading = true;
    });
    await _fetchBoardName();
  }

  void _showMoreOptions() {
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(boardName),
          centerTitle: true,
          leading: widget.showBackButton
              ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
              : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 8.0), // Padding on top and bottom
              child: ElevatedButton(
                onPressed: () async {
                  bool? result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CommBoard_Edit(
                        boardID: widget.boardID,
                        userID: widget.userID,
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
                    side: const BorderSide(
                        color: Colors.black, width: 2), // Adding outline
                  ),
                ),
                child: GText('Edit'),
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 8.0), // Padding on top and bottom
              child: ElevatedButton(
                onPressed: _showMoreOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                        color: Colors.black, width: 2), // Adding outline
                  ),
                ),
                child: GText('Options'),
              ),
            ),
            const Padding(padding: EdgeInsets.only(right: 10)),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CommBoard_Mod(
          boardID: widget.boardID,
          isEditMode: true,
          incrementUsageCount: incrementUsageCount,
          translate: translate,
        ),
      ),
    );
  }
}