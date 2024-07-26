import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gtext/gtext.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class SearchSymbol extends StatefulWidget {
  final Function(String) onSymbolSelected;

  const SearchSymbol({Key? key, required this.onSymbolSelected}) : super(key: key);

  @override
  _SearchSymbolState createState() => _SearchSymbolState();
}

class _SearchSymbolState extends State<SearchSymbol> {
  final TextEditingController searchController = TextEditingController();
  final List<dynamic> searchResults = [];
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  String accessToken = '';
  bool showWarning = false;
  bool isLoading = false;
  Timer? _debounce;
  final Map<String, List<dynamic>> _searchCache = {}; // Cache for search results

  @override
  void initState() {
    super.initState();
    fetchAccessTokenFromFirestore();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (searchController.text.isNotEmpty) {
        fetchSymbols(searchController.text);
      } else {
        setState(() {
          searchResults.clear();
        });
      }
    });
  }

  Future<void> fetchAccessTokenFromFirestore() async {
    setState(() {
      isLoading = true;
    });

    try {
      final tokenDoc = await FirebaseFirestore.instance
          .collection('openSymbols')
          .doc('Token')
          .get();

      if (tokenDoc.exists) {
        accessToken = tokenDoc['accessToken'];

        // Save the token to secure storage
        await secureStorage.write(key: 'accessToken', value: accessToken);

        setState(() {
          showWarning = false;
        });
      } else {
        showWarningSnackbar('Failed to fetch access token from Firestore.');
      }
    } catch (e) {
      showWarningSnackbar('Error fetching access token from Firestore: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchSymbols(String query) async {
    if (_searchCache.containsKey(query)) {
      setState(() {
        searchResults
          ..clear()
          ..addAll(_searchCache[query]!);
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final responseEnglish = await http.get(
        Uri.parse('https://www.opensymbols.org/api/v2/symbols?q=$query&locale=en&safe=1&access_token=$accessToken'),
      );

      final responseTagalog = await http.get(
        Uri.parse('https://www.opensymbols.org/api/v2/symbols?q=$query&locale=tl&safe=1&access_token=$accessToken'),
      );

      if (responseEnglish.statusCode == 200 && responseTagalog.statusCode == 200) {
        final List<dynamic> englishSymbols = json.decode(responseEnglish.body);
        final List<dynamic> tagalogSymbols = json.decode(responseTagalog.body);
        final combinedSymbols = [...englishSymbols, ...tagalogSymbols];
        final filteredSymbols = combinedSymbols.where((symbol) {
          final imageUrl = symbol['image_url'] as String;
          return !imageUrl.endsWith('.svg'); // Filter out SVG links
        }).toList();
        setState(() {
          searchResults
            ..clear()
            ..addAll(filteredSymbols.take(50).toList()); // Increase limit to 50
        });
        _searchCache[query] = filteredSymbols.take(50).toList(); // Cache the results
      } else if (responseEnglish.statusCode == 401 || responseTagalog.statusCode == 401) {
        // Access token expired, fetch a new one and retry
        await fetchAccessTokenFromFirestore();
        fetchSymbols(query);
      } else {
        print('Failed to fetch symbols: ${responseEnglish.statusCode} and ${responseTagalog.statusCode}');
      }
    } catch (e) {
      print('Error fetching symbols: $e');
      showWarningSnackbar('Error fetching symbols. Please try again later.');
    }

    setState(() {
      isLoading = false;
    });
  }

  void showWarningSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GText(message),
      ),
    );
  }

  void showConfirmationDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GText('Confirm Symbol'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImage(imageUrl),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: GText('Cancel'),
            ),
            TextButton(
              onPressed: () {
                widget.onSymbolSelected(imageUrl);
                Navigator.of(context).pop();
                //Navigator.of(context).pop(); // Close the search dialog
              },
              child: GText('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage(String imageUrl) {
    return Image.network(
      imageUrl,
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const Expanded(
                  child: Center(
                    child: GText(
                      'Search Symbol',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Placeholder to balance the back arrow
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.black, width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search image',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : searchResults.isEmpty
                      ? const Center(
                          child: GText(
                            'Search results will appear here.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            var symbol = searchResults[index];
                            return ListTile(
                              leading: _buildImage(symbol['image_url']),
                              title: Text(symbol['name']),
                              onTap: () {
                                showConfirmationDialog(symbol['image_url']);
                              },
                            );
                          },
                        ),
            ),
            if (showWarning)
              GText(
                'Warning: Access token may not be valid.',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

void showSearchSymbolDialog(BuildContext context, Function(String) onSymbolSelected) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SearchSymbol(onSymbolSelected: onSymbolSelected);
    },
    barrierDismissible: false, // Prevents pop-up from closing when pressing outside
  );
}
