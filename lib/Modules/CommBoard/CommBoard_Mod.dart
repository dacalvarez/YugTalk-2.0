import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './SymbolPlayer_Mod.dart';
import './BoardDisplay_Mod.dart';
import '/Screens/LinkedBoard_Screen.dart';

class CommBoard_Mod extends StatefulWidget {
  final String boardID;
  final bool isEditMode;
  final bool incrementUsageCount;
  final bool translate;

  const CommBoard_Mod({
    Key? key,
    required this.boardID,
    required this.isEditMode,
    required this.incrementUsageCount,
    required this.translate,
  }) : super(key: key);

  @override
  _CommBoard_ModState createState() => _CommBoard_ModState();
}

class _CommBoard_ModState extends State<CommBoard_Mod> {
  List<Map<String, String>> selectedSymbols = [];
  late String currentBoardID;
  String? language;

  @override
  void initState() {
    super.initState();
    currentBoardID = widget.boardID;
    fetchBoardLanguage(currentBoardID);
  }

  Future<void> fetchBoardLanguage(String boardID) async {
    try {
      // Fetch board language
      DocumentSnapshot boardSnapshot = await FirebaseFirestore.instance.collection('board').doc(boardID).get();
      if (boardSnapshot.exists) {
        setState(() {
          language = boardSnapshot.get('language');
        });
      }

      // Find and delete documents with 'placeholder' or '0' in words sub-collection
      QuerySnapshot wordsSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(boardID)
          .collection('words')
          .where(FieldPath.documentId, whereIn: ['placeholder', '0'])
          .get();

      for (DocumentSnapshot doc in wordsSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('board')
            .doc(boardID)
            .collection('words')
            .doc(doc.id)
            .delete();
      }
    } catch (e) {
      print('Error fetching board language: $e');
    }
  }
  
  void onSymbolSelected(Map<String, String> symbolData) {
    if (symbolData.containsKey('isLinked') && symbolData['isLinked'] == 'true') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LinkedBoardDisplay(
            boardID: symbolData['linkedBoardID']!,
            onBack: () {
              Navigator.pop(context);
            },
            isEditMode: widget.isEditMode,
          ),
        ),
      );
    } else {
      setState(() {
        if (!selectedSymbols.any((element) => element['symbol'] == symbolData['symbol'])) {
          selectedSymbols.add(symbolData);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          SymbolPlayer_Mod(
            selectedSymbols: selectedSymbols,
            language: language ?? 'English',
            translate: widget.translate,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BoardDisplay_Mod(
              boardID: currentBoardID,
              onSymbolSelected: onSymbolSelected,
              selectedSymbols: selectedSymbols,
              language: language ?? 'English',
              incrementUsageCount: widget.incrementUsageCount,
              translate: widget.translate,
            ),
          ),
        ],
      ),
    );
  }
}
