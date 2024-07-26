import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import '../Widgets/AddBoard_Widget.dart';
import '../Modules/EditMode/BoardsList_Mod.dart';

class EditMode extends StatefulWidget {
  final String userID;
  const EditMode({Key? key, required this.userID}) : super(key: key);

  @override
  State<EditMode> createState() => _EditModeState();
}

class _EditModeState extends State<EditMode> {
  final GlobalKey<BoardsListWidgetState> _boardsListKey = GlobalKey<BoardsListWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GText('Edit Mode'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: BoardsListWidget(
                  key: _boardsListKey,
                  userID: widget.userID,
                  showActivityBoards: false,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: AddBoardWidget(
                isActivityBoard: false,
                userID: widget.userID,
                onBoardAdded: () {
                  _boardsListKey.currentState?.refreshBoards();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}