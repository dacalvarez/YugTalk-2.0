import 'package:flutter/material.dart';
import '/Widgets/AddBoard_Widget.dart';
import '/Modules/EditMode/BoardsList_Mod.dart';

class ActivityBoards_Mod extends StatefulWidget {
  final String userID;
  const ActivityBoards_Mod({Key? key, required this.userID}) : super(key: key);

  @override
  State<ActivityBoards_Mod> createState() => _ActivityBoards_ModState();
}

class _ActivityBoards_ModState extends State<ActivityBoards_Mod> {
  final GlobalKey<BoardsListWidgetState> _boardsListKey =
  GlobalKey<BoardsListWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  showOnlyActivityBoards: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: AddBoardWidget(
                isActivityBoard: true,
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