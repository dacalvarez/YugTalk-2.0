import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gtext/gtext.dart';

class LinkBoardMod extends StatelessWidget {
  final bool isLinked;
  final String? linkedBoard;
  final void Function(bool, String?) onLinkChanged;
  final String userId;
  final String currentBoardId;

  const LinkBoardMod({
    required this.isLinked,
    required this.linkedBoard,
    required this.onLinkChanged,
    required this.userId,
    required this.currentBoardId,
  });

  Future<String?> _getBoardName(String? boardId) async {
    if (boardId == null) return null;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('board').doc(boardId).get();
    return doc.exists ? doc['name'] : null;
  }

  void _selectBoard(BuildContext context) async {
    final boards = await FirebaseFirestore.instance
        .collection('board')
        .where('ownerID', isEqualTo: userId)
        .get();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: GText('Select Board'),
          content: Container(
            width: double.minPositive,
            child: boards.docs.isEmpty
                ? const Center(child: GText('No boards available'))
                : ListView(
                    shrinkWrap: true,
                    children: boards.docs
                        .where((doc) => doc.id != currentBoardId)
                        .map((doc) {
                          return ListTile(
                            title: Text(doc['name']),
                            onTap: () {
                              onLinkChanged(true, doc.id);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onLinkChanged(false, null);
              },
              child: GText('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getBoardName(linkedBoard),
      builder: (context, snapshot) {
        String? boardName = snapshot.data;
        return SwitchListTile(
          title: GText(isLinked && boardName != null ? 'Linked to Board ($boardName)' : 'Link to Board'),
          value: isLinked,
          onChanged: (value) {
            if (value) {
              _selectBoard(context);
            } else {
              onLinkChanged(false, null);
            }
          },
        );
      },
    );
  }
}
