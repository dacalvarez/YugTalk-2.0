//this is lex'
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yugtalk/Widgets/Drawer_Widget.dart';
import '../Modules/Activity Mode/ActivityMode_Mod.dart';
import '../Modules/Activity Mode/Statistics/WordUsage.dart';
import 'MeMode_Screen.dart';
import 'EditMode_Screen.dart';

class Home_Mod extends StatefulWidget {
  const Home_Mod({Key? key}) : super(key: key);
  static const routeName = '/home';

  @override
  _Home_ModState createState() => _Home_ModState();
}

class _Home_ModState extends State<Home_Mod>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController editModePasswordController =
  TextEditingController();
  final TextEditingController activityModePasswordController =
  TextEditingController();
  bool _passwordVisible = false;
  List<WordUsage> wordUsages = generateDummyData();
  int _wordCount = 0;
  int _boardCount = 0;
  int _locationCount = 0;
  late String userID;
  bool _isMounted = false;
  StreamSubscription<QuerySnapshot>? _boardSubscription;
  Map<String, StreamSubscription<QuerySnapshot>> _wordSubscriptions = {};
  StreamSubscription<DocumentSnapshot>? _userSettingsSubscription;
  StreamSubscription<QuerySnapshot>? _pls5Subscription;
  StreamSubscription<QuerySnapshot>? _briganceSubscription;
  Map<String, Set<String>> _boardWords = {};
  List<QueryDocumentSnapshot> _filteredBoards = [];
  List<Map<String, dynamic>> _mostUsedWords = [];
  List<Map<String, dynamic>> _leastUsedWords = [];
  int _mostUsedWordsCount = 0;
  int _leastUsedWordsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      userID = user.email!;
    }
    _fetchData();
    _isMounted = true;
    _fetchWordUsageData();
  }

  @override
  void dispose() {
    _isMounted = false;
    _boardSubscription?.cancel();
    _wordSubscriptions.values.forEach((subscription) => subscription.cancel());
    _userSettingsSubscription?.cancel();
    _pls5Subscription?.cancel();
    _briganceSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _fetchData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    // Fetch board and word counts
    final boardQuery = FirebaseFirestore.instance.collection('board');
    _boardSubscription = boardQuery.snapshots().listen((boardSnapshot) {
      _updateBoardCount(boardSnapshot.docs, user.email!);
    });

    // Fetch location count
    final userSettingsRef =
    FirebaseFirestore.instance.collection('userSettings').doc(user.email);
    _userSettingsSubscription = userSettingsRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _updateLocationCount(snapshot.data());
      }
    });

    // Fetch activity count
    _fetchActivityCount(user.email!);
  }

  Future<void> _fetchWordUsageData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    QuerySnapshot boardSnapshot = await FirebaseFirestore.instance
        .collection('board')
        .where('ownerID', isEqualTo: user.email)
        .where('isActivityBoard', isEqualTo: false)
        .get();

    Map<String, Map<String, dynamic>> wordMap = {};

    for (var boardDoc in boardSnapshot.docs) {
      String boardId = boardDoc.id;
      String boardName = boardDoc['name'];

      QuerySnapshot wordsSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(boardId)
          .collection('words')
          .get();

      for (var wordDoc in wordsSnapshot.docs) {
        Map<String, dynamic> wordData = wordDoc.data() as Map<String, dynamic>;
        String wordName = wordData['wordName'];
        int usageCount = wordData['usageCount'] ?? 0;

        if (!wordMap.containsKey(wordName)) {
          wordMap[wordName] = {
            'wordName': wordName,
            'wordCategory': wordData['wordCategory'],
            'boardFrequencies': {},
            'totalUsage': 0,
          };
        }

        wordMap[wordName]!['boardFrequencies'][boardName] = usageCount;
        wordMap[wordName]!['totalUsage'] += usageCount;
      }
    }

    List<Map<String, dynamic>> allWords = wordMap.values.toList();
    allWords.sort((a, b) => b['totalUsage'].compareTo(a['totalUsage']));

    if (mounted) {
      setState(() {
        _mostUsedWords = allWords
            .where((word) => (word['totalUsage'] as int? ?? 0) >= 10)
            .toList();
        _leastUsedWords = allWords
            .where((word) => (word['totalUsage'] as int? ?? 0) < 10)
            .toList();
        _mostUsedWordsCount = _mostUsedWords.length;
        _leastUsedWordsCount = _leastUsedWords.length;
      });
    }
  }

  void _updateBoardCount(
      List<QueryDocumentSnapshot> boardDocs, String userEmail) {
    int boardCount = 0;
    List<QueryDocumentSnapshot> filteredBoards = [];

    _wordSubscriptions.values.forEach((subscription) => subscription.cancel());
    _wordSubscriptions.clear();
    _boardWords.clear();

    for (var boardDoc in boardDocs) {
      final boardData = boardDoc.data() as Map<String, dynamic>?;
      if (boardData != null &&
          boardData['ownerID'] == userEmail &&
          boardData['isActivityBoard'] != true) {
        boardCount++;
        filteredBoards.add(boardDoc);

        final wordsSubscription = boardDoc.reference
            .collection('words')
            .snapshots()
            .listen((wordsSnapshot) {
          _updateBoardWords(boardDoc.id, wordsSnapshot.docs);
        });

        _wordSubscriptions[boardDoc.id] = wordsSubscription;
      }
    }
    _updateCounts(boardCount: boardCount);
    setState(() {
      _filteredBoards = filteredBoards;
    });
  }

  /*void _updateBoardCount(
      List<QueryDocumentSnapshot> boardDocs, String userEmail) {
    int boardCount = 0;

    _wordSubscriptions.values.forEach((subscription) => subscription.cancel());
    _wordSubscriptions.clear();
    _boardWords.clear();

    for (var boardDoc in boardDocs) {
      boardDoc.reference.snapshots().listen((docSnapshot) {
        if (docSnapshot.exists) {
          final boardData = docSnapshot.data() as Map<String, dynamic>?;
          if (boardData != null &&
              boardData['ownerID'] == userEmail &&
              boardData['isActivityBoard'] != true) {
            boardCount++;

            final wordsSubscription = docSnapshot.reference
                .collection('words')
                .snapshots()
                .listen((wordsSnapshot) {
              _updateBoardWords(docSnapshot.id, wordsSnapshot.docs);
            });

            _wordSubscriptions[docSnapshot.id] = wordsSubscription;
          }
        }
        _updateCounts(boardCount: boardCount);
      });
    }
  }*/

  void _updateBoardWords(String boardId, List<QueryDocumentSnapshot> wordDocs) {
    Set<String> currentBoardWords = Set<String>();

    for (var wordDoc in wordDocs) {
      final wordData = wordDoc.data() as Map<String, dynamic>?;
      if (wordData != null && wordData['wordName'] != null) {
        currentBoardWords.add(wordData['wordName'].toString().toLowerCase());
      }
    }

    _boardWords[boardId] = currentBoardWords;
    _updateUniqueWordCount();
  }

  void _updateUniqueWordCount() {
    Set<String> allUniqueWords = Set<String>();
    for (var boardWords in _boardWords.values) {
      allUniqueWords.addAll(boardWords);
    }
    _updateCounts(wordCount: allUniqueWords.length);
  }

  void _updateLocationCount(Map<String, dynamic>? data) {
    if (data == null) return;

    final userLocations = data['userLocations'] as Map<String, dynamic>?;
    if (userLocations == null) return;

    int totalLocations = 0;
    userLocations.forEach((key, value) {
      String decodedValue = utf8.decode(base64.decode(value));
      List<dynamic> decodedJson = jsonDecode(decodedValue);
      totalLocations += decodedJson.length;
    });

    _updateCounts(locationCount: totalLocations);
  }

  void _fetchActivityCount(String userEmail) {
    FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get()
        .then((userDoc) {
      if (userDoc.docs.isNotEmpty) {
        final userId = userDoc.docs.first.id;
        final pls5FormRef = FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('PLS5Form');
        final briganceFormRef = FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('BriganceForm');

        _pls5Subscription =
            pls5FormRef.snapshots().listen((_) => _updateActivityCount(userId));
        _briganceSubscription = briganceFormRef
            .snapshots()
            .listen((_) => _updateActivityCount(userId));
      }
    });
  }

  void _updateActivityCount(String userId) async {
    if (!_isMounted) return;

    final pls5Count = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('PLS5Form')
        .count()
        .get();

    final briganceCount = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('BriganceForm')
        .count()
        .get();

    int totalActivityCount =
        (pls5Count.count ?? 0) + (briganceCount.count ?? 0);
    _updateCounts(activityCount: totalActivityCount);
  }

  void _updateCounts(
      {int? boardCount,
        int? wordCount,
        int? locationCount,
        int? activityCount}) {
    if (_isMounted) {
      setState(() {
        if (boardCount != null) _boardCount = boardCount;
        if (wordCount != null) _wordCount = wordCount;
        if (locationCount != null) _locationCount = locationCount;
        //if (activityCount != null) _activityCount = activityCount;
      });
    }
  }

  Future<void> _authenticate(BuildContext context) async {
    final String password = _tabController.index == 1
        ? editModePasswordController.text.trim()
        : activityModePasswordController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: GText('Please fill in the Password field first.')),
      );
      return;
    }

    try {
      String hashedPassword = hashPassword(password);

      QuerySnapshot<Map<String, dynamic>> slpSnapshot = await FirebaseFirestore
          .instance
          .collection('SLP')
          .where('password', isEqualTo: hashedPassword)
          .get();

      QuerySnapshot<Map<String, dynamic>> guardianSnapshot =
      await FirebaseFirestore.instance
          .collection('guardian')
          .where('password', isEqualTo: hashedPassword)
          .get();

      String userType;
      if (slpSnapshot.docs.isNotEmpty) {
        userType = 'SLP';
      } else if (guardianSnapshot.docs.isNotEmpty) {
        userType = 'guardian';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: GText('Invalid password.')),
        );
        return;
      }

      switch (_tabController.index) {
        case 0:
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => MeMode(userID: userID)));
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditMode(userID: userID)),
          );
          break;
        case 2:
          if (userType == 'SLP') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ActivityMode_Mod()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: GText('You do not have access to Activity Mode.')),
            );
          }
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Error: ${e.toString()}')),
      );
    }
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GText('Welcome to YugTalk!'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              tabs: [
                Tab(child: _buildTabContent('Me Mode', Icons.person)),
                Tab(child: _buildTabContent('Edit Mode', Icons.edit)),
                Tab(child: _buildTabContent('Activity Mode', Icons.extension)),
              ],
            ),
          ),
        ),
      ),
      drawer: const DrawerWidget(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeModeContent(),
          _buildEditModeContent(),
          _buildActivityModeContent(),
        ],
      ),
    );
  }

  Widget _buildTabContent(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          GText(
            label,
            style: TextStyle(
                fontSize:
                Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18.0,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMeModeContent() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/me_mode.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: GText('Start Communication'),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MeMode(userID: userID)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Center(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard('Words', Icons.text_fields, _wordCount,
                        subtitle: 'Total unique words'),
                    _buildStatCard('Boards', Icons.developer_board, _boardCount,
                        subtitle: 'Total boards'),
                    _buildStatCard('Most Used Words', Icons.trending_up,
                        _mostUsedWordsCount,
                        subtitle: 'Used 10+ times'),
                    _buildStatCard('Least Used Words', Icons.trending_down,
                        _leastUsedWordsCount,
                        subtitle: 'Used <10 times'),
                    _buildStatCard(
                        'Locations', Icons.location_on, _locationCount,
                        subtitle: 'Unique locations'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, int count,
      {String? subtitle}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showDetailsDialog(context, title, count),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(isDarkMode ? 0.3 : 0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.deepPurple),
            const SizedBox(height: 8),
            GText(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                //fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null)
              GText(
                subtitle,
                style: TextStyle(
                  //fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 4),
            GText(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                //fontSize: 20,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, String title, int count) {
    List<dynamic> items = [];
    switch (title) {
      case 'Words':
        items = [..._mostUsedWords, ..._leastUsedWords];
        break;
      case 'Boards':
        items = _filteredBoards
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        break;
      case 'Most Used Words':
        items = _mostUsedWords;
        break;
      case 'Least Used Words':
        items = _leastUsedWords;
        break;
      case 'Locations':
        _fetchLocationsData().then((locations) {
          setState(() {
            items = locations;
          });
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return GeneralStatsDialog(title: title, items: items);
            },
          );
        });
        return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GeneralStatsDialog(title: title, items: items);
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLocationsData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return [];

    DocumentSnapshot userSettingsSnapshot = await FirebaseFirestore.instance
        .collection('userSettings')
        .doc(user.email)
        .get();

    if (!userSettingsSnapshot.exists) return [];

    Map<String, dynamic> data = userSettingsSnapshot.data() as Map<String, dynamic>;
    Map<String, dynamic> userLocations = data['userLocations'] ?? {};

    List<Map<String, dynamic>> locations = [];
    userLocations.forEach((key, value) {
      String decodedValue = utf8.decode(base64.decode(value));
      List<dynamic> decodedJson = jsonDecode(decodedValue);
      for (var location in decodedJson) {
        locations.add({
          'address': location['address'],
          'type': key,
          'latitude': location['latitude'],
          'longitude': location['longitude'],
        });
      }
    });
    return locations;
  }

  Widget _buildPasswordContent(String mode, TextEditingController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/${mode.toLowerCase().replaceAll(' ', '_')}.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple
                            .withOpacity(isDarkMode ? 0.3 : 0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GText(
                        'Enter Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(controller),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _authenticate(context),
                        child: GText('Enter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditModeContent() {
    return _buildPasswordContent('Edit Mode', editModePasswordController);
  }

  Widget _buildActivityModeContent() {
    return _buildPasswordContent(
        'Activity Mode', activityModePasswordController);
  }

  Widget _buildPasswordField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon:
          Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
      ),
      obscureText: !_passwordVisible,
    );
  }
}

class WordUsageDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> words;

  const WordUsageDialog({Key? key, required this.title, required this.words})
      : super(key: key);

  @override
  _WordUsageDialogState createState() => _WordUsageDialogState();
}

class _WordUsageDialogState extends State<WordUsageDialog> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredWords = [];
  String? _selectedCategory;
  String? _selectedBoard;

  @override
  void initState() {
    super.initState();
    _filteredWords = widget.words;
  }

  void _filterWords() {
    setState(() {
      _filteredWords = widget.words.where((word) {
        bool matchesSearch = (word['wordName']
            ?.toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ??
            false) ||
            (word['wordCategory']
                ?.toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
                false);

        bool matchesCategory = _selectedCategory == null ||
            _selectedCategory == 'All' ||
            word['wordCategory'] == _selectedCategory;

        bool matchesBoard = _selectedBoard == null ||
            _selectedBoard == 'All' ||
            ((word['boardFrequencies'] as Map<dynamic, dynamic>?)
                ?.containsKey(_selectedBoard) ??
                false);

        return matchesSearch && matchesCategory && matchesBoard;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Set<String> categories = {
      'All',
      ...widget.words
          .map((w) => w['wordCategory'] as String? ?? 'Unknown')
          .where((c) => c != null)
    };
    Set<String> boards = {
      'All',
      ...widget.words.expand((w) {
        var boardFreqs = w['boardFrequencies'] as Map<dynamic, dynamic>?;
        return boardFreqs?.keys.map((k) => k.toString()) ?? <String>[];
      })
    };

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GText(widget.title,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _filterWords();
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    hint: GText('Category'),
                    items: categories.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: GText(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                        _filterWords();
                      });
                    },
                  ),
                  SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedBoard,
                    hint: GText('Board'),
                    items: boards.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: GText(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBoard = newValue;
                        _filterWords();
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: _filteredWords.isEmpty
                    ? Center(child: GText('No data available'))
                    : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowHeight: 56,
                      dataRowMinHeight: 52,
                      columns: const [
                        DataColumn(
                            label: GText('Word',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: GText('Category',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: GText('Boards & Frequencies',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: GText('Total Usage',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold))),
                      ],
                      rows: _filteredWords.map((word) {
                        List<String> boardFrequencies =
                            (word['boardFrequencies']
                            as Map<dynamic, dynamic>?)
                                ?.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .toList() ??
                                [];
                        return DataRow(
                          cells: [
                            DataCell(GText(word['wordName'] ?? '')),
                            DataCell(GText(word['wordCategory'] ?? '')),
                            DataCell(GText(boardFrequencies.join('\n'))),
                            DataCell(GText(
                                word['totalUsage']?.toString() ?? '0')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GeneralStatsDialog extends StatefulWidget {
  final String title;
  final List<dynamic> items;

  const GeneralStatsDialog({Key? key, required this.title, required this.items})
      : super(key: key);

  @override
  _GeneralStatsDialogState createState() => _GeneralStatsDialogState();
}

class _GeneralStatsDialogState extends State<GeneralStatsDialog> {
  String _popupSearchQuery = '';
  String? _selectedFilter;
  List<dynamic> _filteredItems = [];
  int _currentSortColumn = 0;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  void _filterItems() {
    setState(() {
      _filteredItems = widget.items.where((item) {
        bool matchesSearch = false;
        bool matchesFilter = true;

        if (widget.title == 'Words' ||
            widget.title == 'Most Used Words' ||
            widget.title == 'Least Used Words') {
          matchesSearch = item['wordName']
              .toString()
              .toLowerCase()
              .contains(_popupSearchQuery.toLowerCase());
          matchesFilter = _selectedFilter == null ||
              _selectedFilter == 'All' ||
              item['wordCategory'] == _selectedFilter;
        } else if (widget.title == 'Boards') {
          matchesSearch = item['name']
              .toString()
              .toLowerCase()
              .contains(_popupSearchQuery.toLowerCase());
          matchesFilter = _selectedFilter == null ||
              _selectedFilter == 'All' ||
              item['category'] == _selectedFilter;
        } else if (widget.title == 'Locations') {
          matchesSearch = item['address']
              .toString()
              .toLowerCase()
              .contains(_popupSearchQuery.toLowerCase());
          matchesFilter = _selectedFilter == null ||
              _selectedFilter == 'All' ||
              item['type'] == _selectedFilter;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _sort<T>(Comparable<T> Function(dynamic item) getField, int columnIndex,
      bool ascending) {
    _filteredItems.sort((a, b) {
      if (!ascending) {
        final dynamic c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    setState(() {
      _currentSortColumn = columnIndex;
      _isAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    Set<String> filterOptions = {'All'};
    if (widget.title == 'Words' ||
        widget.title == 'Most Used Words' ||
        widget.title == 'Least Used Words') {
      filterOptions.addAll(widget.items
          .map((item) => item['wordCategory'] as String? ?? 'Unknown')
          .toSet());
    } else if (widget.title == 'Boards') {
      filterOptions.addAll(widget.items
          .map((item) => item['category'] as String? ?? 'Uncategorized')
          .toSet());
    } else if (widget.title == 'Locations') {
      filterOptions
          .addAll(widget.items.map((item) => item['type'] as String).toSet());
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GText(
              widget.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _popupSearchQuery = value;
                        _filterItems();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFilter,
                  hint: GText(widget.title == 'Locations'
                      ? 'Location Type'
                      : 'Category'),
                  items: filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: GText(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFilter = newValue;
                      _filterItems();
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  columns: _getColumns(),
                  source: _DataSource(context, _filteredItems, widget.title),
                  rowsPerPage: 10,
                  sortColumnIndex: _currentSortColumn,
                  sortAscending: _isAscending,
                  dataRowMaxHeight: (_DataSource(context, _filteredItems, widget.title).rowHeight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _getColumns() {
    if (widget.title == 'Words' ||
        widget.title == 'Most Used Words' ||
        widget.title == 'Least Used Words') {
      return [
        DataColumn(
          label: GText('Word', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (columnIndex, ascending) =>
              _sort<String>((item) => item['wordName'], columnIndex, ascending),
        ),
        DataColumn(
          label:
          GText('Category', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (columnIndex, ascending) => _sort<String>(
                  (item) => item['wordCategory'], columnIndex, ascending),
        ),
        DataColumn(
          label: GText('Boards & Frequencies',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: GText('Total Usage',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (columnIndex, ascending) =>
              _sort<num>((item) => item['totalUsage'], columnIndex, ascending),
        ),
      ];
    } else if (widget.title == 'Boards') {
      return [
        DataColumn(
          label: GText('Board', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (columnIndex, ascending) =>
              _sort<String>((item) => item['name'], columnIndex, ascending),
        ),
        DataColumn(
          label:
          GText('Category', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (columnIndex, ascending) =>
              _sort<String>((item) => item['category'], columnIndex, ascending),
        ),
      ];
    } else if (widget.title == 'Locations') {
      return [
        DataColumn(
          label: Container(
            width: 600,
            child: GText('Address', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          onSort: (columnIndex, ascending) =>
              _sort<String>((item) => item['address'], columnIndex, ascending),
        ),
        DataColumn(
          label: GText('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: (columnIndex, ascending) =>
              _sort<String>((item) => item['type'], columnIndex, ascending),
        ),
      ];
    }
    return [];
  }
}

class _DataSource extends DataTableSource {
  final BuildContext context;
  final List<dynamic> _data;
  final String title;

  _DataSource(this.context, this._data, this.title);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final item = _data[index];
    if (title == 'Words' || title == 'Most Used Words' || title == 'Least Used Words') {
      return DataRow(
        cells: [
          DataCell(Text(item['wordName'] ?? '')),
          DataCell(GText(item['wordCategory'] ?? '')),
          DataCell(
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(_formatBoardFrequencies(item['boardFrequencies'])),
            ),
          ),
          DataCell(Text(item['totalUsage']?.toString() ?? '0')),
        ],
      );
    } else if (title == 'Boards') {
      return DataRow(
        cells: [
          DataCell(Text(item['name'] ?? '')),
          DataCell(GText(item['category'] ?? 'Uncategorized')),
        ],
      );
    } else if (title == 'Locations') {
      return DataRow(
        cells: [
          DataCell(
            SizedBox(
              width: 600, // Match the width set in _getColumns
              child: Text(
                item['address'] ?? '',
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 3, // Adjust this value to show more or fewer lines
              ),
            ),
          ),
          DataCell(GText(item['type'] ?? '')),
        ],
      );
    }
    return DataRow(cells: [DataCell(Text(''))]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;

  double get rowHeight => title == 'Locations' ? 100.0 : 50.0;

  String _formatBoardFrequencies(Map<dynamic, dynamic>? boardFrequencies) {
    if (boardFrequencies == null) return '';
    return boardFrequencies.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}