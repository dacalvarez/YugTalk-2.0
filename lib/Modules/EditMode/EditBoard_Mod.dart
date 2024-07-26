import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gtext/gtext.dart';
import '/Screens/EditSymbol_Screen.dart';

class EditBoard_Mod extends StatefulWidget {
  final String boardID;
  final String userID;
  final Function() refreshParent;

  const EditBoard_Mod(
      {Key? key,
      required this.boardID,
      required this.userID,
      required this.refreshParent})
      : super(key: key);

  @override
  _EditBoard_ModState createState() => _EditBoard_ModState();
}

class _EditBoard_ModState extends State<EditBoard_Mod> {
  int? rows;
  int? columns;

  @override
  void initState() {
    super.initState();
    _fetchBoardDetails();
  }

  Future<void> _fetchBoardDetails() async {
    try {
      DocumentSnapshot boardSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .get();

      if (boardSnapshot.exists) {
        var boardData = boardSnapshot.data() as Map<String, dynamic>;
        setState(() {
          rows = boardData['rows'];
          columns = boardData['columns'];
        });
      }
    } catch (e) {
      print("Error fetching board details: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSymbols() async {
    try {
      QuerySnapshot symbolsSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .collection('words')
          .orderBy(FieldPath.documentId)
          .get();

      return symbolsSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          data['id'] = doc.id;
          data['wordName'] = data['wordName'] ?? '';
          data['wordImage'] = data['wordImage'] ?? '';
          data['wordCategory'] = data['wordCategory'] ?? '';
          data['isLinked'] =
              data.containsKey('isLinked') ? data['isLinked'] : null;
        }
        return data ??
            {
              'id': doc.id,
              'wordName': '',
              'wordImage': '',
              'wordCategory': '',
              'isLinked': null
            };
      }).toList();
    } catch (e) {
      print("Error fetching symbols: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchSymbols(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: GText('Error loading symbols: ${snapshot.error}'));
        } else if (rows == null || columns == null) {
          return Center(child: GText('Loading board details...'));
        } else {
          final symbols = snapshot.data ?? [];
          final totalCells = rows! * columns!;
          final orderedSymbols = symbols.toList();

          // Fill remaining cells with empty maps to make them transparent
          while (orderedSymbols.length < totalCells) {
            orderedSymbols.add({'id': null});
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              double maxContainerWidth = constraints.maxWidth;
              double maxContainerHeight = constraints.maxHeight;
              double cellSize =
                  ((maxContainerWidth - (columns! - 1) * 8.0 - 10) / columns!)
                      .clamp(0.0,
                          (maxContainerHeight - (rows! - 1) * 8.0 - 10) / rows!)
                      .toDouble();

              double containerWidth =
                  cellSize * columns! + (columns! - 1) * 8.0 + 10;
              double containerHeight =
                  cellSize * rows! + (rows! - 1) * 8.0 + 10;

              return Center(
                child: Container(
                  width: containerWidth,
                  height: containerHeight,
                  padding: const EdgeInsets.all(5), // Thinner padding
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns!,
                      childAspectRatio: 1.0, // Ensure cells are square
                      crossAxisSpacing: 8.0, // Spacing between columns
                      mainAxisSpacing: 8.0, // Spacing between rows
                    ),
                    itemCount: totalCells,
                    itemBuilder: (context, index) {
                      final symbol = orderedSymbols[index];
                      return GestureDetector(
                        onTap: () {
                          if (symbol['id'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditSymbol(
                                  boardId: widget.boardID,
                                  symbolId: symbol['id'],
                                  userId: widget.userID,
                                  refreshParent: widget.refreshParent,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _buildSymbolContainer(symbol, cellSize),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Color _getTextColorForCategory(String category) {
    return category.toLowerCase() == 'determiners'
        ? Colors.white
        : Colors.black;
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'nouns':
        return const Color(0xffffb33f);
      case 'pronouns':
        return const Color(0xffffe682);
      case 'verbs':
        return const Color(0xff9ee281);
      case 'adjectives':
        return const Color(0xff69c8ff);
      case 'prepositions':
        return const Color(0xffff8cd2);
      case 'social words':
        return const Color(0xffff8cd2);
      case 'questions':
        return const Color(0xffa77dff);
      case 'negations':
        return const Color(0xffff5150);
      case 'important words':
        return const Color(0xffff5150);
      case 'adverbs':
        return const Color(0xffc19b84);
      case 'conjunctions':
        return const Color(0xffffffff);
      case 'determiners':
        return const Color(0xff464646);
      default:
        return Colors.grey;
    }
  }

  Widget _buildSymbolContainer(Map<String, dynamic> data, double cellSize) {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool showImageOnly = constraints.maxHeight < 100;
          double imageSize = showImageOnly
              ? constraints.maxHeight * 0.7
              : constraints.maxHeight * 0.5;
          double? fontSize = showImageOnly ? 0 : 16;
          Color textColor =
              _getTextColorForCategory(data['wordCategory'] ?? '');

          return Card(
            color: _getColorForCategory(data['wordCategory'] ?? ''),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2,
            margin: const EdgeInsets.all(3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImage(data['wordImage'] ?? '', imageSize),
                if (!showImageOnly)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            data['wordName'] ?? '',
                            style:
                                TextStyle(fontSize: fontSize, color: textColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (data['isLinked'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(
                              Icons.grid_view_rounded,
                              size: fontSize,
                              color: Colors.black,
                            ),
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

  Widget _buildImage(String? imageUrl, double maxHeight) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container();
    }

    bool isSvg = imageUrl.toLowerCase().endsWith('.svg');
    if (isSvg) {
      try {
        return SvgPicture.network(
          imageUrl,
          placeholderBuilder: (context) => const CircularProgressIndicator(),
          fit: BoxFit.contain,
          height: maxHeight,
        );
      } catch (e) {
        print("Error loading SVG: $e");
        return _buildErrorIndicator(maxHeight);
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        height: maxHeight,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image: $error");
          return _buildErrorIndicator(maxHeight);
        },
      );
    }
  }

  Widget _buildErrorIndicator(double maxHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, color: Colors.red, size: maxHeight * 0.3),
        if (maxHeight > 100)
          GText(
            'Error',
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }
}
