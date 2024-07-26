import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gtext/gtext.dart';
import 'package:just_audio/just_audio.dart';
import '../PopupForm/PopupForm_Mod.dart';
import 'package:translator/translator.dart';
import 'dart:collection';

class BoardDisplay_Mod extends StatefulWidget {
  final String boardID;
  final Function(Map<String, String>) onSymbolSelected;
  final List<Map<String, String>> selectedSymbols;
  final String language;
  final bool incrementUsageCount;
  final bool translate;

  const BoardDisplay_Mod({
    Key? key,
    required this.boardID,
    required this.onSymbolSelected,
    required this.selectedSymbols,
    required this.language,
    required this.incrementUsageCount,
    required this.translate,
  }) : super(key: key);

  @override
  _BoardDisplay_ModState createState() => _BoardDisplay_ModState();
}

class _BoardDisplay_ModState extends State<BoardDisplay_Mod> {
  int? rows;
  int? columns;
  bool isLoading = true;
  List<Map<String, dynamic>> symbols = [];
  final FlutterTts flutterTts = FlutterTts();
  late final AudioPlayer audioPlayer;
  final translator = GoogleTranslator();
  bool isSpeakingOrPlaying = false;
  Queue<String> speechQueue = Queue<String>();
  DateTime? lastTapTime;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _initializeTts();
    _fetchBoardDetails();
  }

  @override
  void dispose() {
    flutterTts.stop();
    audioPlayer.dispose();
    speechQueue.clear();
    super.dispose();
  }

  void _initializeTts() async {
    flutterTts.setCompletionHandler(() async {
      if (speechQueue.isNotEmpty) {
        String nextPhrase = speechQueue.removeFirst();
        if (_isMobileDevice()) {
          await Future.delayed(Duration(milliseconds: 300));
        }
        await flutterTts.speak(nextPhrase);
      } else {
        if (mounted) {
          setState(() {
            isSpeakingOrPlaying = false;
          });
        }
      }
    });

    flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          isSpeakingOrPlaying = false;
        });
      }
    });

    if (_isMobileDevice()) {
      await flutterTts.setSpeechRate(0.4);
      await flutterTts.setPitch(1.0);
    } else {
      await flutterTts.setSpeechRate(0.75);
      await flutterTts.setPitch(1.2);
    }

    await _setInitialTtsVoice();
  }

  Future<void> _setInitialTtsVoice() async {
    final voice = widget.language == 'English'
        ? {'name': 'en-US-locale', 'locale': 'en-US'}
        : {'name': 'in-ID-dfz-network', 'locale': 'id-ID'};
    await _setVoice(voice);
  }

  Future<void> _setTtsVoice() async {
    final voice = widget.translate
        ? (widget.language == 'Filipino'
            ? {'name': 'en-US-locale', 'locale': 'en-US'}
            : {'name': 'in-ID-dfz-network', 'locale': 'id-ID'})
        : (widget.language == 'English'
            ? {'name': 'in-ID-dfz-network', 'locale': 'id-ID'}
            : {'name': 'en-US-locale', 'locale': 'en-US'});
    await _setVoice(voice);
  }

  Future<void> _setVoice(Map<String, String> voice) async {
    await flutterTts.setVoice({"name": voice["name"]!, "locale": voice["locale"]!});
  }

  Future<void> _fetchBoardDetails() async {
    try {
      DocumentSnapshot boardSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .get();

      if (boardSnapshot.exists) {
        var boardData = boardSnapshot.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            rows = boardData['rows'];
            columns = boardData['columns'];
          });
        }
        _fetchSymbols();
      } else {
        setDefaultDimensions();
      }
    } catch (e) {
      setDefaultDimensions();
    }
  }

  void setDefaultDimensions() {
    if (mounted) {
      setState(() {
        rows = 3;
        columns = 5;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSymbols() async {
    try {
      QuerySnapshot symbolsSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .collection('words')
          .orderBy(FieldPath.documentId)
          .get();

      List<Map<String, dynamic>> fetchedSymbols = symbolsSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (widget.translate) {
        for (var symbol in fetchedSymbols) {
          if (symbol['wordName'] != null) {
            symbol['translatedWordName'] = await _translateText(symbol['wordName']);
          }
        }
      }

      if (mounted) {
        setState(() {
          symbols = fetchedSymbols;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  Future<void> _incrementUsageCount(String boardID, String symbolID) async {
    if (!widget.incrementUsageCount) return;

    try {
      DocumentReference symbolRef = FirebaseFirestore.instance
          .collection('board')
          .doc(boardID)
          .collection('words')
          .doc(symbolID);

      await symbolRef.update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      _showSnackBar('Error incrementing usage count: $e');
    }
  }

  Future<String> _translateText(String text) async {
    try {
      if (widget.language == 'Filipino') {
        var translation = await translator.translate(text, from: 'tl', to: 'en');
        return translation.text;
      } else {
        var translation = await translator.translate(text, from: 'en', to: 'tl');
        return translation.text;
      }
    } catch (e) {
      throw Exception('Translation failed: $e');
    }
  }
  void _playAudio(String url) async {
    try {
      if (mounted) {
        setState(() {
          isSpeakingOrPlaying = true;
        });
      }
      await audioPlayer.setUrl(url);
      await audioPlayer.play();
      audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              isSpeakingOrPlaying = false;
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isSpeakingOrPlaying = false;
        });
      }
    }
  }

  void _speak(String text) async {
    await flutterTts.stop();
    speechQueue.clear();

    if (mounted) {
      setState(() {
        isSpeakingOrPlaying = true;
      });
    }

    if (_isMobileDevice()) {
      List<String> words = text.split(' ');
      for (String word in words) {
        await flutterTts.speak(word);
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } else {
      await flutterTts.speak(text);
    }
  }

  bool _isMobileDevice() {
    return kIsWeb
        ? false
        : (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
  }

  void _playSymbolAudio(Map<String, dynamic> symbol) async {
    await audioPlayer.stop();
    await flutterTts.stop();

    String? audioUrl = symbol['wordAudio'];
    String text = symbol['translatedWordName'] ?? symbol['wordName'] ?? '';

    if (audioUrl != null && audioUrl.isNotEmpty) {
      _playAudio(audioUrl);
    } else {
      if (_isMobileDevice()) {
        speechQueue.add(text);
        if (!isSpeakingOrPlaying) {
          _speak(speechQueue.removeFirst());
        }
      } else {
        _speak(text);
      }
    }
  }

  void _handleTap(Map<String, dynamic> symbol) async {

    if (symbol['id'] == null) {
      return;
    }

    DateTime now = DateTime.now();
    int minTapInterval = _isMobileDevice() ? 500 : 100;
    if (lastTapTime != null && now.difference(lastTapTime!).inMilliseconds < minTapInterval) {
      return;
    }
    lastTapTime = now;

    if (isSpeakingOrPlaying) return;

    if (symbol.containsKey('isLinked') && symbol['isLinked'] != null) {
      DocumentReference linkedBoardRef = symbol['isLinked'] as DocumentReference;
      DocumentSnapshot linkedBoardSnapshot = await linkedBoardRef.get();
      if (linkedBoardSnapshot.exists) {
        widget.onSymbolSelected({
          'isLinked': 'true',
          'linkedBoardID': linkedBoardRef.id,
        });
      }
    } else {
      if (widget.selectedSymbols.isEmpty ||
          widget.selectedSymbols.last['id'] != symbol['id']) {
        String word = symbol['translatedWordName'] ?? symbol['wordName'] ?? '';

        widget.selectedSymbols.add({
          'symbol': symbol['symbol'] ?? '',
          'word': word,
          'wordAudio': symbol['wordAudio'] ?? '',
          'symbolImage': symbol['wordImage'] ?? '',
          'id': symbol['id'] ?? '',
          'language': widget.language,
        });
        widget.onSymbolSelected({
          'symbol': symbol['symbol'] ?? '',
          'word': word,
          'wordAudio': symbol['wordAudio'] ?? '',
          'symbolImage': symbol['wordImage'] ?? '',
          'id': symbol['id'] ?? '',
          'language': widget.language,
        });
      }
      _playSymbolAudio(symbol);
      await _incrementUsageCount(widget.boardID, symbol['id']);
      if (mounted) {
        setState(() {
          isSpeakingOrPlaying = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant BoardDisplay_Mod oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.translate != widget.translate) {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
      _fetchSymbols();
      _setTtsVoice();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (symbols.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GText(
            'No symbols found. To add symbols, go to edit mode.',
            textAlign: TextAlign.center,
            style: TextStyle(
              //fontSize: 18,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      );
    }

    final totalCells = rows! * columns!;
    final orderedSymbols = symbols.toList();

    while (orderedSymbols.length < totalCells) {
      orderedSymbols.add({'id': null});
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxContainerWidth = constraints.maxWidth;
        double maxContainerHeight = constraints.maxHeight;
        double cellSize = ((maxContainerWidth - (columns! - 1) * 8.0 - 10) / columns!).clamp(0.0, (maxContainerHeight - (rows! - 1) * 8.0 - 10) / rows!).toDouble();

        double containerWidth = cellSize * columns! + (columns! - 1) * 8.0 + 10;
        double containerHeight = cellSize * rows! + (rows! - 1) * 8.0 + 10;

        return Center(
          child: Container(
            width: containerWidth,
            height: containerHeight,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns!,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                final symbol = orderedSymbols[index];
                return GestureDetector(
                  onTap: symbol['id'] != null ? () => _handleTap(symbol) : null,
                  onLongPress: symbol['id'] != null ? () async {
                    await _incrementUsageCount(widget.boardID, symbol['id']);
                    showPopupFormMod(context, widget.boardID, symbol['id']);
                  } : null,
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DragTarget<String>(
                      onAcceptWithDetails: (receivedID) {
                        // Handle symbol drag and drop if needed
                      },
                      builder: (context, candidateData, rejectedData) {
                        if (symbol['id'] == null) {
                          return Container(color: Colors.transparent);
                        } else {
                          return _buildSymbolContainer(symbol, cellSize);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymbolContainer(Map<String, dynamic> data, double cellSize) {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool showImageOnly = constraints.maxHeight < 100;
          double imageSize = showImageOnly ? constraints.maxHeight * 0.7 : constraints.maxHeight * 0.5;
          double? fontSize = showImageOnly ? 0 : 16;
          String wordName = widget.translate ? data['translatedWordName'] ?? data['wordName'] ?? '' : data['wordName'] ?? '';
          Color textColor = _getTextColorForCategory(data['wordCategory'] ?? '');

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
                _buildImage(data['wordImage'], imageSize),
                if (!showImageOnly)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          wordName,
                          style: TextStyle(
                              fontSize: fontSize,
                              color: textColor
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (data.containsKey('isLinked') && data['isLinked'] != null)
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: maxHeight * 0.3),
          if (maxHeight > 100)
            const GText(
              'Error',
              style: TextStyle(color: Colors.red),
            ),
        ],
      );
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
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: maxHeight * 0.3),
            if (maxHeight > 100)
              const GText(
                'Error',
                style: TextStyle(color: Colors.red),
              ),
          ],
        );
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        height: maxHeight,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: maxHeight * 0.3),
              if (maxHeight > 100)
                const GText(
                  'Error',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          );
        },
      );
    }
  }

Color _getTextColorForCategory(String category) {
    return category.toLowerCase() == 'determiners' ? Colors.white : Colors.black;
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GText(message),
      ),
    );
  }
}

void showPopupFormMod(BuildContext context, String boardID, String symbolID) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PopupFormMod(boardID: boardID, symbolID: symbolID);
    },
  );
}
