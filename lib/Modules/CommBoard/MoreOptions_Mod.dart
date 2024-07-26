import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';

class MoreOptions extends StatefulWidget {
  final bool translate;
  final bool incrementUsageCount;
  final String? currentLanguage;

  const MoreOptions({
    Key? key,
    required this.translate,
    required this.incrementUsageCount,
    required this.currentLanguage,
  }) : super(key: key);

  @override
  _MoreOptionsState createState() => _MoreOptionsState();
}

class _MoreOptionsState extends State<MoreOptions> {
  late bool translate;
  late bool incrementUsageCount;

  @override
  void initState() {
    super.initState();
    translate = widget.translate;
    incrementUsageCount = widget.incrementUsageCount;
  }

  String getOppositeLanguage() {
    return widget.currentLanguage == 'English' ? 'Tagalog' : 'English';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final fontSize = Theme.of(context).textTheme.displaySmall?.fontSize;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: SingleChildScrollView( // Wrap with SingleChildScrollView
        child: Container(
          width: 350, // Increase the width of the dialog
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GText(
                'More Options',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildSwitchTile(
                'Switch language to ',
                getOppositeLanguage(),
                translate,
                    (bool value) {
                  setState(() {
                    translate = value;
                  });
                },
                textColor,
                fontSize,
              ),
              _buildSwitchTile(
                'Symbol usage counter: ',
                incrementUsageCount ? 'On' : 'Off',
                incrementUsageCount,
                    (bool value) {
                  setState(() {
                    incrementUsageCount = value;
                  });
                },
                textColor,
                fontSize,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  child: GText('Exit'),
                  onPressed: () {
                    Navigator.of(context).pop({'translate': translate, 'incrementUsageCount': incrementUsageCount});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String value, bool switchValue, Function(bool) onChanged, Color textColor, double? fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                text: title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: fontSize,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Switch(
            value: switchValue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
