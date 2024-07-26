import 'dart:typed_data';

class Word {
  int wordID;
  String wordName;
  String wordDesc;
  Uint8List wordImage;
  String wordAudio;
  String wordVideo;

  Word({
    required this.wordID,
    required this.wordName,
    required this.wordDesc,
    required this.wordImage,
    required this.wordAudio,
    required this.wordVideo,
  });

  Map<String, dynamic> toMap() {
    return {
      'wordID': wordID,
      'wordName': wordName,
      'wordDesc': wordDesc,
      'wordImage': wordImage,
      'wordAudio': wordAudio,
      'wordVideo': wordVideo,
    };
  }
}