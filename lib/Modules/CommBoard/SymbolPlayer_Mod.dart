import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gtext/gtext.dart';

class SymbolPlayer_Mod extends StatefulWidget {
  final List<Map<String, String>> selectedSymbols;
  final String language; // 'Filipino' or 'English'
  final bool translate;

  const SymbolPlayer_Mod({
    Key? key,
    required this.selectedSymbols,
    required this.language,
    required this.translate,
  }) : super(key: key);

  @override
  _SymbolPlayer_ModState createState() => _SymbolPlayer_ModState();
}

class _SymbolPlayer_ModState extends State<SymbolPlayer_Mod> {
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  @override
  void didUpdateWidget(covariant SymbolPlayer_Mod oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.translate != widget.translate) {
      _setTtsVoice();
    }
  }

  void _initializeTts() async {
    flutterTts.setStartHandler(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          isSpeaking = true;
        });
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isSpeaking = false;
      });
      _showErrorDialog(msg);
    });

    // Set TTS properties to make the voice less robotic
    flutterTts.setSpeechRate(0.5);
    flutterTts.setPitch(1.2);

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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GText('Error'),
          content: GText(message),
          actions: [
            TextButton(
              child: GText('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GText(message),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _playSymbols() async {
    if (widget.selectedSymbols.isEmpty) {
      _showSnackBar('Please select a symbol');
      return;
    }

    if (isSpeaking) return;

    String combinedText = '';
    for (var symbol in widget.selectedSymbols) {
      combinedText += '${symbol['word'] ?? ''} ';
    }

    await _speak(combinedText.trim());
  }

  Future<void> _speak(String text) async {
    try {
      await flutterTts.speak(text);
    } catch (e) {
      setState(() {
        isSpeaking = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  void _clearQueue() {
    setState(() {
      widget.selectedSymbols.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isQueueEmpty = widget.selectedSymbols.isEmpty;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color iconColor = isDarkMode ? Colors.white : Colors.black;
    Color disabledColor = Colors.grey.withAlpha(100);

    return Material(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: isDarkMode ? Colors.white : Colors.black),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: IconButton(
                icon: Icon(Icons.play_arrow, color: isQueueEmpty ? disabledColor : iconColor),
                iconSize: 32,
                onPressed: isQueueEmpty
                    ? null
                    : () {
                        _playSymbols();
                      },
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.selectedSymbols.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(4.0),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDarkMode ? Colors.white : Colors.black),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: widget.selectedSymbols[index]['symbolImage'] != null
                          ? Image.network(
                              widget.selectedSymbols[index]['symbolImage']!,
                              fit: BoxFit.cover,
                            )
                          : Container(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: GestureDetector(
                onLongPress: isQueueEmpty
                    ? null
                    : () {
                        _clearQueue();
                      },
                child: IconButton(
                  icon: Icon(Icons.backspace, color: isQueueEmpty ? disabledColor : iconColor),
                  iconSize: 32,
                  onPressed: isQueueEmpty
                      ? null
                      : () {
                          setState(() {
                            widget.selectedSymbols.removeLast();
                          });
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
