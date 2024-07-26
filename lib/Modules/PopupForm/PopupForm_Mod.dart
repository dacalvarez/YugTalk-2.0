import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gtext/gtext.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

class PopupFormMod extends StatefulWidget {
  final String boardID;
  final String symbolID;

  const PopupFormMod({Key? key, required this.boardID, required this.symbolID}) : super(key: key);

  @override
  _PopupFormModState createState() => _PopupFormModState();
}

class _PopupFormModState extends State<PopupFormMod> {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  VideoPlayerController? _videoPlayerController;
  String wordName = '';
  String wordDesc = '';
  String wordAudio = '';
  String wordVideo = '';
  String wordImage = '';
  double _volume = 1.0;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _fetchWordData();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _fetchWordData() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .collection('words')
          .doc(widget.symbolID)
          .get();

      if (documentSnapshot.exists) {
        setState(() {
          wordName = documentSnapshot['wordName'];
          wordDesc = documentSnapshot['wordDesc'];
          wordAudio = documentSnapshot['wordAudio'];
          wordVideo = documentSnapshot['wordVideo'];
          wordImage = documentSnapshot['wordImage'];

          if (wordVideo.isNotEmpty) {
            _videoPlayerController = VideoPlayerController.network(wordVideo)
              ..initialize().then((_) {
                setState(() {});
              }).catchError((_) {
                setState(() {
                  _videoPlayerController = null;
                });
              })
              ..addListener(() {
                if (_videoPlayerController!.value.position ==
                    _videoPlayerController!.value.duration) {
                  setState(() {});
                }
              });
          }
        });
      }
    } catch (e) {
      print('Error fetching word data: $e');
    }
  }

  Future<void> _playAudio() async {
    if (wordAudio.isNotEmpty) {
      try {
        await audioPlayer.setUrl(wordAudio);
        audioPlayer.play();
      } catch (e) {
        await flutterTts.speak(wordName);
      }
    } else {
      await flutterTts.speak(wordName);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.grey.shade300;
    Color borderColor = isDarkMode ? Colors.white : Colors.black;
    Color innerBackgroundColor = isDarkMode ? Colors.black54 : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      backgroundColor: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.80,
          height: MediaQuery.of(context).size.height * 0.80,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      height: MediaQuery.of(context).size.height * 0.35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                            ? Colors.black
                            : innerBackgroundColor,
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: _videoPlayerController != null &&
                          _videoPlayerController!.value.isInitialized
                          ? Stack(
                        children: [
                          GestureDetector(
                            child: VideoPlayer(_videoPlayerController!),
                          ),
                          _buildControls(),
                        ],
                      )
                          : Center(
                        child: GText(
                          'No video data',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.17,
                        width: MediaQuery.of(context).size.height * 0.17,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: innerBackgroundColor,
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: wordImage.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            wordImage,
                            fit: BoxFit.cover,
                            headers: const {
                              "Content-Type": "image/jpeg",
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Center(
                                child: Text(
                                  'Error loading image',
                                  style: TextStyle(color: textColor),
                                ),
                              );
                            },
                          ),
                        )
                            : Center(
                          child: GText(
                            'Symbol Container',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.17,
                        width: MediaQuery.of(context).size.height * 0.17,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: innerBackgroundColor,
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.volume_up, color: textColor, size: 55),
                          onPressed: _playAudio,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.25,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: innerBackgroundColor,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wordName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: GText(
                          wordDesc.isNotEmpty ? wordDesc : 'No description for this symbol',
                          style: TextStyle(
                            fontStyle: wordDesc.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    bool isVideoFinished = _videoPlayerController!.value.position == _videoPlayerController!.value.duration;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          VideoProgressIndicator(_videoPlayerController!, allowScrubbing: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isVideoFinished ? Icons.replay : (_videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isVideoFinished) {
                          _videoPlayerController!.seekTo(Duration.zero);
                          _videoPlayerController!.play();
                        } else {
                          _videoPlayerController!.value.isPlaying
                              ? _videoPlayerController!.pause()
                              : _videoPlayerController!.play();
                        }
                      });
                    },
                  ),
                  const Icon(
                    Icons.volume_up,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 100, // Shorten the slider
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          _volume = value;
                          _videoPlayerController!.setVolume(_volume);
                        });
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: PopupMenuButton<double>(
                  initialValue: _playbackSpeed,
                  onSelected: (speed) {
                    setState(() {
                      _playbackSpeed = speed;
                      _videoPlayerController!.setPlaybackSpeed(speed);
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 0.5,
                      child: GText("0.5x"),
                    ),
                    const PopupMenuItem(
                      value: 0.75,
                      child: GText("0.75x"),
                    ),
                    const PopupMenuItem(
                      value: 1.0,
                      child: GText("1.0x (Normal)"),
                    ),
                    const PopupMenuItem(
                      value: 1.25,
                      child: GText("1.25x"),
                    ),
                    const PopupMenuItem(
                      value: 1.5,
                      child: GText("1.5x"),
                    ),
                  ],
                  child: const Icon(
                    Icons.speed,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
