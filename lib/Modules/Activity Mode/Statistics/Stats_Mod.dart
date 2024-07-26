import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import 'StatsActGraphs_Widget.dart';
import 'StatsWrdGraphs_Widget.dart';
import 'WordUsage.dart';
import '../Activity Forms/ActivityForms.dart';
import '../Activity Forms/CreateBriganceForm_Widget.dart';
import '../Activity Forms/CreatePLS5Form_Widget.dart';
import 'package:intl/intl.dart';

class Stats_Mod extends StatelessWidget {
  const Stats_Mod({super.key});

  @override
  Widget build(BuildContext context) {
    List<WordUsage> wordUsages = generateDummyData();
    List<ActivityForms> activityForms = activityFormsData;

    int mostUsedCount = wordUsages.where((w) => w.isMostUsed).length;
    int leastUsedCount = wordUsages.length - mostUsedCount;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GeneralStats(wordUsages: wordUsages, activityForms: activityForms),
            const SizedBox(height: 15),
            MostUsedWordsStats(),
            const SizedBox(height: 25),
            ActivitiesStats(activityForms: activityForms),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}

class LocationFrequency {
  final String location;
  final int frequency;

  LocationFrequency({required this.location, required this.frequency});
}

class MostUsedWordsStats extends StatefulWidget {
  const MostUsedWordsStats({Key? key}) : super(key: key);

  @override
  _MostUsedWordsStatsState createState() => _MostUsedWordsStatsState();
}

class _MostUsedWordsStatsState extends State<MostUsedWordsStats> {
  List<Map<String, dynamic>> _mostUsedWords = [];
  List<Map<String, dynamic>> _leastUsedWords = [];
  int _mostUsedWordsCount = 0;
  int _leastUsedWordsCount = 0;
  bool _isLoading = true;
  String _selectedCategory = 'All Categories';
  String _selectedLocation = 'All Locations';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchWordUsageData();
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
      String boardName = boardDoc['name'] as String? ?? 'Unnamed Board';

      QuerySnapshot wordsSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(boardId)
          .collection('words')
          .get();

      for (var wordDoc in wordsSnapshot.docs) {
        Map<String, dynamic> wordData = wordDoc.data() as Map<String, dynamic>;

        // Skip placeholder words
        if (wordDoc.id == 'placeholder' || wordData['initialized'] == true) {
          continue;
        }

        String wordName = wordData['wordName'] as String? ?? 'Unnamed Word';
        String wordCategory =
            wordData['wordCategory'] as String? ?? 'Uncategorized';
        int usageCount = wordData['usageCount'] as int? ?? 0;

        if (!wordMap.containsKey(wordName)) {
          wordMap[wordName] = {
            'wordName': wordName,
            'wordCategory': wordCategory,
            'boardFrequencies': {},
            'totalUsage': 0,
          };
        }

        wordMap[wordName]!['boardFrequencies'][boardName] = usageCount;
        wordMap[wordName]!['totalUsage'] =
            (wordMap[wordName]!['totalUsage'] as int) + usageCount;
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

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoIconButton(
                        count: _mostUsedWords.length.toString(),
                        onPressed: () {
                          _showWordsDialog(context, _mostUsedWords);
                        },
                        title: 'Most Used Words',
                        textColor: textColor,
                      ),
                      _buildInfoIconButton(
                        count: _leastUsedWords.length.toString(),
                        onPressed: () {
                          _showWordsDialog(context, _leastUsedWords);
                        },
                        title: 'Least Used Words',
                        textColor: textColor,
                      ),
                    ],
                  ),
          ),
          const Positioned(
            top: 0,
            right: 0,
            child: IconButton(
                icon: Icon(Icons.bar_chart),
                onPressed:
                    null /*() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsWrdGraphs_Widget(
                      wordUsages: widget.wordUsages,
                    ),
                  ),
                );
              },*/
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoIconButton({
    required String count,
    required VoidCallback onPressed,
    required String title,
    required Color textColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GText(
          count,
          style: TextStyle(
            //fontSize: 24.0, // Adjusted font size
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GText(
              title,
              style: TextStyle(
                //fontSize: 14.0,
                color: textColor,
              ),
            ),
            const SizedBox(
              width: 4.0,
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: onPressed,
            ),
          ],
        ),
      ],
    );
  }

  void _showWordsDialog(
      BuildContext context, List<Map<String, dynamic>> words) {
    List<Map<String, dynamic>> filteredWords = List.from(words);
    String _popupSearchQuery = '';
    String _selectedCategory = 'All Categories';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search word...',
                      ),
                      onChanged: (query) {
                        setState(() {
                          _popupSearchQuery = query.toLowerCase();
                          _filterWords(filteredWords, _popupSearchQuery,
                              _selectedCategory);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                        _filterWords(filteredWords, _popupSearchQuery,
                            _selectedCategory);
                      });
                    },
                    items: _buildCategoryDropdownItems(words),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Word')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Boards & Frequencies')),
                      DataColumn(label: Text('Total Usage')),
                    ],
                    rows: filteredWords
                        .map((word) => DataRow(
                              cells: [
                                DataCell(Text(word['wordName'] as String)),
                                DataCell(Text(word['wordCategory'] as String)),
                                DataCell(Text(_formatBoardFrequencies(
                                    word['boardFrequencies']
                                        as Map<String, dynamic>))),
                                DataCell(Text(word['totalUsage'].toString())),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _filterWords(
      List<Map<String, dynamic>> words, String query, String category) {
    words = _mostUsedWords.where((word) {
      bool matchesSearch =
          word['wordName'].toString().toLowerCase().contains(query);
      bool matchesCategory =
          category == 'All Categories' || word['wordCategory'] == category;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String _formatBoardFrequencies(Map<String, dynamic> boardFrequencies) {
    return boardFrequencies.entries
        .map((e) => "${e.key}: ${e.value}")
        .join(", ");
  }

  List<DropdownMenuItem<String>> _buildCategoryDropdownItems(
      List<Map<String, dynamic>> words) {
    Set<String> categories =
        words.map((word) => word['wordCategory'] as String).toSet();
    List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(
          value: 'All Categories', child: Text('All Categories')),
    ];
    items.addAll(categories.map((category) =>
        DropdownMenuItem(value: category, child: Text(category))));
    return items;
  }

  List<DropdownMenuItem<String>> _buildLocationDropdownItems(
      List<WordUsage> words) {
    Set<String> locations = words
        .expand(
            (word) => word.datesOfUsage.expand((usage) => usage.values.expand(
                  (locationFrequencies) => locationFrequencies
                      .map((lf) => lf.location.toString().split('.').last),
                )))
        .toSet();
    List<DropdownMenuItem<String>> items = [];
    items.add(const DropdownMenuItem(
      value: 'All Locations',
      child: GText('All Locations'),
    ));
    items.addAll(locations.map((location) {
      return DropdownMenuItem(
        value: location,
        child: GText(location),
      );
    }).toList());
    return items;
  }

  Widget buildSortableHeader(
      String label, int columnIndex, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Row(
        children: [
          GText(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Icon(
            _sortColumnIndex == columnIndex
                ? (_sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                : null,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterMostUsedWords() {
    return _mostUsedWords;
  }

  List<Map<String, dynamic>> _filterLeastUsedWords() {
    return _leastUsedWords;
  }
}

class ActivitiesStats extends StatefulWidget {
  final List<ActivityForms> activityForms;

  const ActivitiesStats({super.key, required this.activityForms});

  @override
  _ActivitiesStatsState createState() => _ActivitiesStatsState();
}

class _ActivitiesStatsState extends State<ActivitiesStats> {
  String _popupSearchQuery = '';
  int _toDoCount = 0;
  int _inProgressCount = 0;
  int _successfulCount = 0;
  StreamSubscription<QuerySnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _pls5Subscription;
  StreamSubscription<QuerySnapshot>? _briganceSubscription;
  int _pls5ToDoCount = 0;
  int _pls5InProgressCount = 0;
  int _pls5SuccessfulCount = 0;
  int _briganceToDoCount = 0;
  int _briganceInProgressCount = 0;
  int _briganceSuccessfulCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _pls5Subscription?.cancel();
    _briganceSubscription?.cancel();
    super.dispose();
  }

  void _fetchData() {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      return;
    }

    final userQuery = FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: userEmail);

    _userSubscription?.cancel();
    _userSubscription = userQuery.snapshots().listen((userSnapshot) {
      if (userSnapshot.docs.isNotEmpty) {
        final userId = userSnapshot.docs.first.id;
        _fetchFormCounts(userId);
      }
    });
  }

  void _fetchFormCounts(String userId) {
    final pls5FormRef = FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('PLS5Form');
    final briganceFormRef = FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('BriganceForm');

    _pls5Subscription?.cancel();
    _briganceSubscription?.cancel();

    _pls5Subscription = pls5FormRef.snapshots().listen((snapshot) {
      _processSnapshot(snapshot, 'PLS-5');
    });

    _briganceSubscription = briganceFormRef.snapshots().listen((snapshot) {
      _processSnapshot(snapshot, 'Brigance');
    });
  }

  void _processSnapshot(QuerySnapshot snapshot, String formType) {
    int toDoCount = 0;
    int inProgressCount = 0;
    int successfulCount = 0;

    for (final doc in snapshot.docs) {
      final formStatus = doc['formStatus'];
      if (formStatus == 'To Do') {
        toDoCount++;
      } else if (formStatus == 'In Progress') {
        inProgressCount++;
      } else if (formStatus == 'Successful') {
        successfulCount++;
      }
    }

    if (mounted) {
      setState(() {
        if (formType == 'PLS-5') {
          _pls5ToDoCount = toDoCount;
          _pls5InProgressCount = inProgressCount;
          _pls5SuccessfulCount = successfulCount;
        } else if (formType == 'Brigance') {
          _briganceToDoCount = toDoCount;
          _briganceInProgressCount = inProgressCount;
          _briganceSuccessfulCount = successfulCount;
        }

        _toDoCount = _pls5ToDoCount + _briganceToDoCount;
        _inProgressCount = _pls5InProgressCount + _briganceInProgressCount;
        _successfulCount = _pls5SuccessfulCount + _briganceSuccessfulCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusContainer('To Do', _toDoCount, context, textColor),
                _buildStatusContainer(
                    'In Progress', _inProgressCount, context, textColor),
                _buildStatusContainer(
                    'Successful', _successfulCount, context, textColor),
              ],
            ),
          ),
          const Positioned(
            top: 0,
            right: 0,
            child: IconButton(
                icon: Icon(Icons.bar_chart),
                onPressed:
                    null /*() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsActGraphs_Widget(
                      activityForms: widget.activityForms,
                    ),
                  ),
                );
              },*/
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContainer(
      String status, int count, BuildContext context, Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GText(
          count.toString(),
          style: TextStyle(
            //fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GText(
              status,
              style: TextStyle(
                //fontSize: 14.0,
                color: textColor,
              ),
            ),
            const SizedBox(
              width: 4.0,
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                List<ActivityForms> filteredForms = widget.activityForms
                    .where((form) => form.formStatus == status)
                    .toList();
                _showDetailsDialog(context, status, filteredForms);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showDetailsDialog(
      BuildContext context, String status, List<ActivityForms> activityForms) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search forms...',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _popupSearchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchFormsFromFirestore(status),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: GText('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: GText('No forms found.'));
                    } else {
                      List<Map<String, dynamic>> forms = snapshot.data!;
                      List<Map<String, dynamic>> filteredForms = forms
                          .where((form) => form['activityFormName']
                              .toLowerCase()
                              .contains(_popupSearchQuery.toLowerCase()))
                          .toList();
                      final DateFormat dateFormat =
                          DateFormat('yyyy-MM-dd HH:mm');

                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredForms.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            Map<String, dynamic> form = filteredForms[index];
                            DateTime? date;
                            if (form['date'] is Timestamp) {
                              date = form['date'].toDate();
                            } else if (form['date'] is String) {
                              date = dateFormat.parse(form['date']);
                            } else {
                              date = null;
                            }
                            return ListTile(
                              title: Text(
                                form['activityFormName'],
                              ),
                              subtitle: GText(
                                'Type: ${form['formType']}\n'
                                'Name: ${form['name']}\n'
                                'Date Created: ${date != null ? dateFormat.format(date) : 'N/A'}\n',
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                _navigateToForm(
                                    context, ActivityForms.fromMap(form));
                              },
                            );
                          },
                        ),
                      );
                    }
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: GText('Exit'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _popupSearchQuery = ''; // Reset the search query
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFormsFromFirestore(
      String status) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    final userDoc = await FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      final userId = userDoc.docs.first.id;

      final List<Map<String, dynamic>> forms = [];
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      final briganceSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('BriganceForm')
          .where('formStatus', isEqualTo: status)
          .get();

      for (final doc in briganceSnapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? '';

        final activityBoardsValue = data['activity_board_dropdown'];
        final activityBoards = activityBoardsValue is String
            ? activityBoardsValue
            : activityBoardsValue?.toString() ?? '';

        DateTime date = data['date'] != null && data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : DateTime.now();

        forms.add({
          'formType': 'Brigance',
          'activityFormName': data['activityFormName'] ?? '',
          'activity_board_dropdown': activityBoards,
          'age': int.tryParse(data['age'] ?? '0') ?? 0,
          'briganceRows': data['briganceRows'] ?? [],
          'date': dateFormat.format(date),
          'formStatus': data['formStatus'],
          'gender': data['gender'] ?? '',
          'name': name ?? '',
          'next_steps': data['next_steps'] ?? '',
          'other_comments': data['other_comments'] ?? '',
          'therapist': data['therapist'] ?? '',
        });
      }

      final pls5Snapshot = await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('PLS5Form')
          .where('formStatus', isEqualTo: status)
          .get();

      for (final doc in pls5Snapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? '';

        final activityBoardsValue = data['activity_board_dropdown'];
        final activityBoards = activityBoardsValue is String
            ? activityBoardsValue
            : activityBoardsValue?.toString() ?? '';

        DateTime date = data['date'] != null && data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : DateTime.now();

        forms.add({
          'formType': 'PLS-5',
          'activityFormName': data['activityFormName'] ?? '',
          'activity_board_dropdown': activityBoards,
          'age': int.tryParse(data['age'] ?? '0') ?? 0,
          'auditory_comprehension_summary':
              data['auditory_comprehension_summary'],
          'date': dateFormat.format(date),
          'expressive_communication_summary':
              data['expressive_communication_summary'],
          'formStatus': data['formStatus'] ?? '',
          'gender': data['gender'] ?? '',
          'name': name,
          'next_steps': data['next_steps'] ?? '',
          'other_comments': data['other_comments'] ?? '',
          'pls5Rows': data['pls5Rows'] ?? [],
          'therapist': data['therapist'] ?? '',
          'total_language_score_summary': data['total_language_score_summary'],
        });
      }

      return forms;
    } else {
      return [];
    }
  }

  void _navigateToForm(BuildContext context, ActivityForms form) {
    if (form.formType == 'PLS-5') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePLS5Form_Widget(initialData: form),
        ),
      );
    } else if (form.formType == 'Brigance') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateBriganceForm_Widget(initialData: form),
        ),
      );
    }
  }
}

class GeneralStats extends StatefulWidget {
  const GeneralStats({
    Key? key,
    required this.wordUsages,
    required this.activityForms,
  }) : super(key: key);

  final List<WordUsage> wordUsages;
  final List<ActivityForms> activityForms;

  @override
  _GeneralStatsState createState() => _GeneralStatsState();
}

class _GeneralStatsState extends State<GeneralStats> {
  int _boardCount = 0;
  int _wordCount = 0;
  int _locationCount = 0;
  int _activityCount = 0;

  StreamSubscription<QuerySnapshot>? _boardSubscription;
  Map<String, StreamSubscription<QuerySnapshot>> _wordSubscriptions = {};
  StreamSubscription<DocumentSnapshot>? _userSettingsSubscription;
  StreamSubscription<QuerySnapshot>? _pls5Subscription;
  StreamSubscription<QuerySnapshot>? _briganceSubscription;
  Map<String, Set<String>> _boardWords = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _boardSubscription?.cancel();
    _wordSubscriptions.values.forEach((subscription) => subscription.cancel());
    _userSettingsSubscription?.cancel();
    _pls5Subscription?.cancel();
    _briganceSubscription?.cancel();
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

  void _updateBoardCount(
      List<QueryDocumentSnapshot> boardDocs, String userEmail) {
    int boardCount = 0;

    _wordSubscriptions.values.forEach((subscription) => subscription.cancel());
    _wordSubscriptions.clear();
    _boardWords.clear();

    for (var boardDoc in boardDocs) {
      boardDoc.reference.snapshots().listen((docSnapshot) {
        if (docSnapshot.exists) {
          final boardData = docSnapshot.data() as Map<String, dynamic>?;
          if (boardData != null && boardData['ownerID'] == userEmail) {
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
  }

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
    _safeSetState(() {
      if (boardCount != null) _boardCount = boardCount;
      if (wordCount != null) _wordCount = wordCount;
      if (locationCount != null) _locationCount = locationCount;
      if (activityCount != null) _activityCount = activityCount;
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Container(
        margin: const EdgeInsets.only(top: 20.0),
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 3,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          children: [
            _buildGeneralStatContainer(
                context, 'Words', _wordCount.toString(), textColor),
            _buildGeneralStatContainer(
                context, 'Boards', _boardCount.toString(), textColor),
            _buildGeneralStatContainer(
                context, 'Locations', _locationCount.toString(), textColor),
            _buildGeneralStatContainer(
                context, 'Activities', _activityCount.toString(), textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralStatContainer(
      BuildContext context, String title, String count, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GText(
            count,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GText(title),
              const SizedBox(width: 4.0),
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {
                  _showGeneralStatsDialog(context, title);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGeneralStatsDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GeneralStatsDialog(title: title);
      },
    );
  }
}

class GeneralStatsDialog extends StatefulWidget {
  final String title;

  const GeneralStatsDialog({Key? key, required this.title}) : super(key: key);

  @override
  _GeneralStatsDialogState createState() => _GeneralStatsDialogState();
}

class _GeneralStatsDialogState extends State<GeneralStatsDialog> {
  String _popupSearchQuery = '';
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> filteredItems = [];
  List<Map<String, dynamic>> allItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  String _decryptData(String encryptedData) {
    List<int> bytes = base64Url.decode(encryptedData);
    return utf8.decode(bytes);
  }

  @override
  void didUpdateWidget(covariant GeneralStatsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _loadItems();
    }
  }

  // Add a caching mechanism
  Future<void> _loadItems() async {
    setState(() {
      isLoading = true; // Set loading to true when starting to load items
    });

    if (widget.title == 'Words') {
      List<Map<String, dynamic>> wordData = await _fetchWordUsages();
      setState(() {
        allItems = wordData
            .map((word) => {
                  'address': word['wordName'] as String,
                  'count': word['count'].toString(),
                  'category': word['wordCategory'] as String,
                })
            .toList()
            .cast<Map<String, String>>();
        filteredItems = allItems;
      });
    } else if (widget.title == 'Boards') {
      List<Map<String, String>> userBoards = await _fetchUserBoards();
      setState(() {
        allItems = userBoards;
        filteredItems = allItems;
      });
    } else if (widget.title == 'Locations') {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.email != null) {
          // Fetch userSettings to get userLocations
          final userSettingsDoc = await FirebaseFirestore.instance
              .collection('userSettings')
              .doc(user.email)
              .get();

          final userLocations =
              userSettingsDoc.data()?['userLocations'] as Map<String, dynamic>?;

          if (userLocations != null) {
            // Fetch currentLocation data
            final currentLocationDoc = await FirebaseFirestore.instance
                .collection('currentLocation')
                .doc(user.email)
                .get();

            final currentLocationData = currentLocationDoc.data();

            List<Map<String, dynamic>> locationData = [];

            userLocations.forEach((locationType, encodedLocations) {
              String decodedValue =
                  utf8.decode(base64.decode(encodedLocations));
              List<dynamic> decodedJson = jsonDecode(decodedValue);

              for (var location in decodedJson) {
                String address = location['address'];

                // Decrypt and parse the corresponding currentLocation data
                String? encryptedData = currentLocationData?[locationType];
                Map<String, dynamic> locationStats = {};

                if (encryptedData != null) {
                  String decryptedJson = _decryptData(encryptedData);
                  locationStats = json.decode(decryptedJson);
                }

                Map<String, dynamic> item = {
                  'type': locationType,
                  'address': address,
                  'counter': locationStats['counter'] ?? 0,
                  'startTime':
                      _formatDateTime(locationStats['startTime'] ?? 'N/A'),
                  'endTime': _formatDateTime(locationStats['endTime'] ?? 'N/A'),
                  'duration': locationStats['duration'] ?? 'N/A',
                };
                locationData.add(item);
              }
            });

            setState(() {
              allItems = locationData;
              filteredItems = locationData;
            });
          }
        }
      } catch (e) {
        print('Error fetching location data: $e');
      }
    } else if (widget.title == 'Activities') {
      List<Map<String, String>> userForms = await _fetchUserForms();
      setState(() {
        allItems = userForms;
        filteredItems = allItems;
      });
    } else {
      setState(() {
        filteredItems = _filterItems();
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<List<Map<String, String>>> _fetchUserBoards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      return [];
    }

    try {
      final boardsSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .where('ownerID', isEqualTo: user.email)
          .get();

      List<Map<String, String>> boards = [];
      for (var doc in boardsSnapshot.docs) {
        String boardName = 'Unnamed Board';

        // Fetch the 'name' field from the board document
        final boardData = doc.data();
        if (boardData.containsKey('name') && boardData['name'] != null) {
          boardName = boardData['name'] as String;
        }

        boards.add({
          'id': doc.id,
          'address': boardName,
          'type': 'Board',
        });
      }

      return boards;
    } catch (e) {
      print('Error fetching user boards: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _fetchUserForms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      return [];
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        return [];
      }

      final userId = userDoc.docs.first.id;
      List<Map<String, String>> forms = [];

      // Fetch PLS5Forms
      final pls5QuerySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('PLS5Form')
          .get();

      for (var doc in pls5QuerySnapshot.docs) {
        forms.add({
          'type': 'PLS-5',
          'address': doc.data()['activityFormName'] ?? 'Unnamed PLS-5 Form',
          'id': doc.id,
          'status': doc.data()['formStatus'] ?? 'Unknown',
        });
      }

      // Fetch BriganceForms
      final briganceQuerySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('BriganceForm')
          .get();

      for (var doc in briganceQuerySnapshot.docs) {
        forms.add({
          'type': 'Brigance',
          'address': doc.data()['activityFormName'] ?? 'Unnamed Brigance Form',
          'id': doc.id,
          'status': doc.data()['formStatus'] ?? 'Unknown',
        });
      }

      return forms;
    } catch (e) {
      print('Error fetching user forms: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWordUsages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      return [];
    }

    try {
      Map<String, Map<String, dynamic>> wordInfo = {};

      // Fetch all boards owned by the current user
      final boardsSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .where('ownerID', isEqualTo: user.email)
          .get();

      for (var boardDoc in boardsSnapshot.docs) {
        final wordsCollection = boardDoc.reference.collection('words');
        final wordsSnapshot = await wordsCollection.get();

        for (var wordDoc in wordsSnapshot.docs) {
          String wordId = wordDoc.id;
          String wordName = wordDoc.data()['wordName'] ?? 'Unknown';
          String wordCategory =
              wordDoc.data()['wordCategory'] ?? 'Uncategorized';

          if (!wordInfo.containsKey(wordId)) {
            wordInfo[wordId] = {
              'wordName': wordName,
              'wordCategory': wordCategory,
              'count': 0
            };
          }
          wordInfo[wordId]!['count'] = (wordInfo[wordId]!['count'] as int) + 1;
        }
      }

      // Convert the word info to the format we need
      List<Map<String, dynamic>> wordData = wordInfo.entries
          .map((entry) => {
                'word': entry.key,
                'wordName': entry.value['wordName'],
                'wordCategory': entry.value['wordCategory'],
                'count': entry.value['count'],
              })
          .toList();

      // Sort the words by count in descending order
      wordData.sort((a, b) => b['count'].compareTo(a['count']));

      return wordData;
    } catch (e) {
      print('Error fetching word usages: $e');
      return [];
    }
  }

  void _filterItemsByCategory(String category) {
    setState(() {
      if (category == 'All') {
        filteredItems = allItems
            .where((item) => item['address']!
                .toLowerCase()
                .contains(_popupSearchQuery.toLowerCase()))
            .toList();
      } else {
        filteredItems = allItems
            .where((item) =>
                item['type'] == category &&
                item['address']!
                    .toLowerCase()
                    .contains(_popupSearchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  List<Map<String, dynamic>> _filterItems() {
    List<Map<String, dynamic>> items;
    switch (widget.title) {
      case 'Words':
      case 'Boards':
      case 'Locations':
      case 'Activities':
        items = allItems;
        break;
      default:
        items = [];
    }

    return items
        .where((item) => item['address']
            .toString()
            .toLowerCase()
            .contains(_popupSearchQuery.toLowerCase()))
        .toList();
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime? dateTime;
    try {
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.tryParse(timestamp);
      } else if (timestamp is int) {
        // Handle Unix timestamp in milliseconds
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    if (dateTime == null) return 'Invalid Date';

    return "${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  Widget _buildFilterDropdown() {
    List<String> filterOptions;
    String filterLabel;

    switch (widget.title) {
      case 'Words':
        filterOptions = ['All'] +
            allItems.map((item) => item['category'] as String).toSet().toList();
        filterLabel = 'Category: ';
        break;
      case 'Locations':
        filterOptions = ['All', 'Home', 'School', 'Clinic'];
        filterLabel = 'Location Type: ';
        break;
      case 'Activities':
        filterOptions = ['All', 'PLS-5', 'Brigance'];
        filterLabel = 'Form Type: ';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GText(
          filterLabel,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: _selectedFilter,
          items: filterOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: GText(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedFilter = newValue!;
              if (widget.title == 'Words') {
                filteredItems = _filterItems()
                    .where((item) =>
                        _selectedFilter == 'All' ||
                        item['category'] == _selectedFilter)
                    .toList();
              } else if (widget.title == 'Activities') {
                filteredItems = _filterItems()
                    .where((item) =>
                        _selectedFilter == 'All' ||
                        item['type'] == _selectedFilter)
                    .toList();
              } else {
                _filterItemsByCategory(_selectedFilter);
              }
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Filtered items: $filteredItems');
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _popupSearchQuery = value;
                          filteredItems = _filterItems();
                          if (widget.title == 'Locations') {
                            _filterItemsByCategory(_selectedFilter);
                          }
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFilterDropdown(),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Display loading indicator
                  : widget.title == 'Locations' && filteredItems.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return ListTile(
                              title: Text(
                                  item['address'] ?? item['type'] ?? 'Unknown'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item['counter'] != null)
                                    Text(
                                        'Times visited: ${item['counter'] ?? '0'}'),
                                  if (item['startTime'] != null)
                                    Text(
                                        'Last visit start: ${item['startTime'] ?? 'N/A'}'),
                                  if (item['endTime'] != null)
                                    Text(
                                        'Last visit end: ${item['endTime'] ?? 'N/A'}'),
                                  if (item['duration'] != null)
                                    Text(
                                        'Last visit duration: ${item['duration'] ?? 'N/A'} seconds'),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
