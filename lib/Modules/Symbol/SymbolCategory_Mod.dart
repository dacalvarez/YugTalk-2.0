import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';

class SymbolCategory extends StatelessWidget {
  final String currentCategory;
  final ValueChanged<String> onCategoryChanged;

  const SymbolCategory({
    required this.currentCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Nouns',
      'Pronouns',
      'Verbs',
      'Adjectives',
      'Prepositions',
      'Social words',
      'Questions',
      'Negations',
      'Important words',
      'Adverbs',
      'Conjunctions',
      'Determiners',
    ];

    const categoryColors = {
      'Nouns': Color(0xFFFFB33F),
      'Pronouns': Color(0xFFFFE682),
      'Verbs': Color(0xFF9EE281),
      'Adjectives': Color(0xFF69C8FF),
      'Prepositions': Color(0xFFFF8CD2),
      'Social words': Color(0xFFFF8CD2),
      'Questions': Color(0xFFA77DFF),
      'Negations': Color(0xFFFF5150),
      'Important words': Color(0xFFFF5150),
      'Adverbs': Color(0xFFC19B84),
      'Conjunctions': Color(0xFFFFFFFF),
      'Determiners': Color(0xFF464646),
    };

    return AlertDialog(
      title: GText('Select Category'),
      content: Container(
        width: 300,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((category) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2.0),
                decoration: BoxDecoration(
                  color: categoryColors[category],
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.shade600),
                ),
                child: ListTile(
                  title: GText(
                    category,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  trailing: currentCategory == category
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context, category);
                    onCategoryChanged(category);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: GText('Cancel'),
        ),
      ],
    );
  }
}

void showSymbolCategoryDialog(
    BuildContext context, String currentCategory, ValueChanged<String> onCategoryChanged) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (context) => SymbolCategory(
      currentCategory: currentCategory,
      onCategoryChanged: onCategoryChanged,
    ),
  );
}
