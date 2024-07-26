import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gtext/gtext.dart';
import 'package:intl/intl.dart';
import '../../../Widgets/Drawer_Widget.dart';
import 'ActivityForms.dart';
import 'CreateBriganceForm_Widget.dart';
import 'CreatePLS5Form_Widget.dart';
import 'package:searchable_listview/searchable_listview.dart';
import 'package:collection/collection.dart';

class ActivityForms_Mod extends StatefulWidget {
  const ActivityForms_Mod({super.key});

  @override
  _ActivityFormsModState createState() => _ActivityFormsModState();
}

class _ActivityFormsModState extends State<ActivityForms_Mod>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String selectedType = 'All';
  String selectedStatus = 'All';
  String selectedAge = 'All';
  String selectedPediatricName = 'All';

  final String _searchQuery = '';
  final ValueNotifier<String> searchQueryNotifier = ValueNotifier<String>('');
  List<ActivityForms> _activityForms = [];
  final List<String> formTypes = ['All', 'PLS-5', 'Brigance'];
  final List<String> formStatuses = [
    'All',
    'To Do',
    'In Progress',
    'Successful'
  ];
  final List<String> formAges = [
    'All',
    '3 years old',
    '4 years old',
    '5 years old'
  ];
  List<String> pediatricNames = ['All'];
  late Set<String> _therapistNames = {'All'};
  late StreamSubscription<QuerySnapshot> _pls5Subscription;
  late StreamSubscription<QuerySnapshot> _briganceSubscription;
  List<ActivityForms> _pls5Forms = [];
  List<ActivityForms> _briganceForms = [];

  @override
  void initState() {
    super.initState();
    _startListeningToActivityForms();
  }

  void _startListeningToActivityForms() {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      return;
    }

    final userQuery = FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: userEmail);

    userQuery.snapshots().listen((userSnapshot) {
      if (userSnapshot.docs.isNotEmpty) {
        final userId = userSnapshot.docs.first.id;

        final pls5Query = FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('PLS5Form');

        final briganceQuery = FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('BriganceForm');

        _pls5Subscription = pls5Query.snapshots().listen((snapshot) {
          _processSnapshot(snapshot, 'PLS-5');
          _updateTherapistNames(_pls5Forms);
        });

        _briganceSubscription = briganceQuery.snapshots().listen((snapshot) {
          _processSnapshot(snapshot, 'Brigance');
          _updateTherapistNames(_briganceForms);
        });
      }
    });
  }

  void _updateTherapistNames(List<ActivityForms> forms) {
    for (final form in forms) {
      final therapist = form.therapist;
      if (therapist.isNotEmpty) {
        _therapistNames.add(therapist);
      }
    }
    _updatePediatricNames();
  }

  void _updatePediatricNames() {
    setState(() {
      pediatricNames = _therapistNames.toList();
    });
  }

  List<ActivityForms> _processFormsForDisplay(List<ActivityForms> allForms) {
    // Group forms by patient name and form type
    final groupedForms = groupBy(
        allForms, (ActivityForms form) => '${form.name}|${form.formType}');

    // For each patient and form type, get the most recent form and calculate created/modified dates
    return groupedForms.entries.map((entry) {
      final patientForms = entry.value;
      patientForms.sort((a, b) =>
          (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));

      final mostRecentForm = patientForms.first;
      final oldestDate = patientForms
          .map((f) => f.date)
          .whereType<DateTime>()
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final newestDate = patientForms
          .map((f) => f.date)
          .whereType<DateTime>()
          .reduce((a, b) => a.isAfter(b) ? a : b);

      return ActivityForms(
        formType: mostRecentForm.formType,
        activityFormName: '${mostRecentForm.name} - ${mostRecentForm.formType}',
        activityBoards: mostRecentForm.activityBoards,
        age: mostRecentForm.age,
        date: mostRecentForm.date ?? DateTime.now(),
        dateCreated: oldestDate,
        formStatus: mostRecentForm.formStatus,
        gender: mostRecentForm.gender,
        name: mostRecentForm.name,
        nextSteps: mostRecentForm.nextSteps,
        pls5OtherComments: mostRecentForm.pls5OtherComments,
        pls5Rows: mostRecentForm.pls5Rows,
        therapist: mostRecentForm.therapist,
        dateModified: newestDate,
        pls5AuditoryComprehensionSummary:
        mostRecentForm.pls5AuditoryComprehensionSummary,
        pls5ExpressiveCommunicationSummary:
        mostRecentForm.pls5ExpressiveCommunicationSummary,
        pls5TotalLanguageScoreSummary:
        mostRecentForm.pls5TotalLanguageScoreSummary,
        isFavorite: mostRecentForm.isFavorite,
        otherComments: mostRecentForm.otherComments,
        briganceRows: mostRecentForm.briganceRows,
      );
    }).toList();
  }

  Future<void> _processSnapshot(QuerySnapshot snapshot, String formType) async {
    final forms = <ActivityForms>[];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final form = _mapDocumentToActivityForm(data, formType);
        print("Mapped form: $form");
        forms.add(form);
      }
    }

    setState(() {
      if (formType == 'PLS-5') {
        _pls5Forms = forms;
      } else if (formType == 'Brigance') {
        _briganceForms = forms;
      }
      _activityForms =
          _processFormsForDisplay([..._pls5Forms, ..._briganceForms]);
    });
  }

  ActivityForms _mapDocumentToActivityForm(
      Map<String, dynamic> data, String formType) {
    final name = data['name'] ?? '';
    final bool isFavorite = data['isFavorite'] ?? false;

    final activityBoardValue = data['activity_board_dropdown'];
    List<String> activityBoards = [];
    if (activityBoardValue != null &&
        activityBoardValue is String &&
        activityBoardValue.isNotEmpty) {
      activityBoards = [activityBoardValue];
    }

    DateTime date;
    if (data['date'] != null) {
      if (data['date'] is Timestamp) {
        date = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is DateTime) {
        date = data['date'] as DateTime;
      } else {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    if (formType == 'PLS-5') {
      List<Map<String, String>> pls5Rows = [];
      final pls5RowsData = data['pls5Rows'];
      if (pls5RowsData is List) {
        pls5Rows = pls5RowsData.map((row) {
          if (row is Map) {
            return row.map(
                    (key, value) => MapEntry(key.toString(), value.toString()));
          } else {
            return <String, String>{};
          }
        }).toList();
      }

      return ActivityForms(
        formType: formType,
        activityFormName: data['activityFormName'] ?? '',
        activityBoards: activityBoards,
        age: int.tryParse(data['age'] ?? '0') ?? 0,
        date: date,
        dateCreated: date,
        formStatus: data['formStatus'] ?? '',
        gender: data['gender'] ?? '',
        name: name,
        nextSteps: data['next_steps'] ?? '',
        pls5OtherComments: data['other_comments'] ?? '',
        pls5Rows: pls5Rows,
        therapist: data['therapist'] ?? '',
        dateModified: date,
        pls5AuditoryComprehensionSummary:
        data['auditory_comprehension_summary'],
        pls5ExpressiveCommunicationSummary:
        data['expressive_communication_summary'],
        pls5TotalLanguageScoreSummary: data['total_language_score_summary'],
        isFavorite: isFavorite,
        isActivityBoard: data['isActivityBoard'] ?? false,
      );
    } else {
      List<Map<String, String>> briganceRows = [];
      final briganceRowsData = data['briganceRows'];
      if (briganceRowsData is List) {
        briganceRows = briganceRowsData.map((row) {
          if (row is Map) {
            return row.map(
                    (key, value) => MapEntry(key.toString(), value.toString()));
          } else {
            return <String, String>{};
          }
        }).toList();
      }

      return ActivityForms(
        formType: formType,
        activityFormName: data['activityFormName'] ?? '',
        activityBoards: activityBoards,
        age: int.tryParse(data['age'] ?? '0') ?? 0,
        date: date,
        dateCreated: date,
        formStatus: data['formStatus'] ?? '',
        gender: data['gender'] ?? '',
        name: name,
        nextSteps: data['next_steps'] ?? '',
        otherComments: data['other_comments'] ?? '',
        briganceRows: briganceRows,
        therapist: data['therapist'] ?? '',
        dateModified: date,
        isFavorite: isFavorite,
        isActivityBoard: data['isActivityBoard'] ?? false,
      );
    }
  }

  @override
  void dispose() {
    _pls5Subscription.cancel();
    _briganceSubscription.cancel();
    super.dispose();
  }

  Future<void> _deleteForm(ActivityForms item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email;

      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final userId = userDoc.docs.first.id;

        bool shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: GText('Confirm Deletion'),
            content: GText(
                'Are you sure you want to delete all ${item.formType} forms for ${item.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: GText('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: GText('Delete'),
              ),
            ],
          ),
        ) ??
            false;

        if (shouldDelete) {
          await _deleteFormsForPatient(
              userId,
              item.formType == 'PLS-5' ? 'PLS5Form' : 'BriganceForm',
              item.name);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: GText(
                    'All ${item.formType} forms for ${item.name} deleted successfully')),
          );

          setState(() {
            _activityForms.removeWhere((form) =>
            form.name == item.name && form.formType == item.formType);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Error deleting form: $e')),
      );
    }
  }

  Future<void> _deleteFormsForPatient(
      String userId, String collectionName, String patientName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection(collectionName)
        .where('name', isEqualTo: patientName)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color =
    isDarkMode ? const Color.fromRGBO(19, 18, 19, 1.0) : Colors.grey[200];

    return Scaffold(
      drawer: const DrawerWidget(),
      body: Column(
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GText(
                    'Create Activity Form',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:
                      Theme.of(context).textTheme.bodyLarge?.fontSize ??
                          20.0,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePLS5Form_Widget(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.fontSize ??
                            16.0,
                      ),
                    ),
                    child: GText('PLS-5'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateBriganceForm_Widget(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.fontSize ??
                            16.0,
                      ),
                    ),
                    child: GText('Brigance'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: _buildDropdownButtons(context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildActivityFormsList(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFormsList(BuildContext context) {
    List<ActivityForms> filteredForms = _activityForms.where((item) {
      final matchesType =
          selectedType == 'All' || item.formType == selectedType;
      final matchesStatus =
          selectedStatus == 'All' || item.formStatus == selectedStatus;
      final matchesAge =
          selectedAge == 'All' || '${item.age} years old' == selectedAge;
      final matchesPediatricName = selectedPediatricName == 'All' ||
          (item.formType == 'PLS-5' &&
              item.therapist == selectedPediatricName) ||
          (item.formType == 'Brigance' &&
              item.therapist == selectedPediatricName);
      final matchesSearchQuery = item.activityFormName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchesType &&
          matchesStatus &&
          matchesAge &&
          matchesPediatricName &&
          matchesSearchQuery;
    }).toList();

    filteredForms.sort((a, b) => b.isFavorite ? 1 : 0);

    return SearchableList<ActivityForms>(
      initialList: filteredForms,
      seperatorBuilder: (context, index) => const Divider(),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: Theme.of(context).textTheme.displaySmall?.fontSize ?? 16.0,
      ),
      itemBuilder: (item) {
        return _activityFormItem(item);
      },
      emptyWidget: const _EmptyView(),
      inputDecoration: InputDecoration(
        labelText: "Search Activity Forms",
        hintText: "Search forms...",
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.deepPurple,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      filter: (query) {
        List<ActivityForms> filteredForms = [];
        for (var form in _activityForms) {
          if (form.activityFormName
              .toLowerCase()
              .contains(query.toLowerCase())) {
            filteredForms.add(form);
          }
        }
        return filteredForms;
      },
    );
  }

  Widget _buildDropdownButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownButton(
            label: 'Type',
            items: formTypes,
            value: selectedType,
            onChanged: (value) {
              setState(() {
                selectedType = value!;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDropdownButton(
            label: 'Status',
            items: formStatuses,
            value: selectedStatus,
            onChanged: (value) {
              setState(() {
                selectedStatus = value!;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDropdownButton(
            label: 'Age',
            items: formAges,
            value: selectedAge,
            onChanged: (value) {
              setState(() {
                selectedAge = value!;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDropdownButton(
            label: 'Pediatric Name',
            items: pediatricNames,
            value: selectedPediatricName,
            onChanged: (value) {
              setState(() {
                selectedPediatricName = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownButton({
    required String label,
    required List<String> items,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    assert(items.contains(value));

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: GText(value),
        );
      }).toList(),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _activityFormItem(ActivityForms item) {
    if (item.isActivityBoard) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade200,
          borderRadius: BorderRadius.circular(5),
        ),
        child: GText(
          'Activity Board',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    Color typeColor = Colors.grey;
    Color statusColor = Colors.grey;
    Color ageColor = Colors.grey;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color =
    isDarkMode ? const Color.fromRGBO(19, 18, 19, 1.0) : Colors.grey[200];

    if (item.formType == 'PLS-5') {
      typeColor = const Color.fromARGB(255, 217, 0, 255);
    } else if (item.formType == 'Brigance') {
      typeColor = const Color.fromARGB(255, 93, 0, 255);
    }

    if (item.formStatus == 'To Do') {
      statusColor = Colors.blue;
    } else if (item.formStatus == 'In Progress') {
      statusColor = const Color.fromARGB(255, 255, 145, 0);
    } else if (item.formStatus == 'Successful') {
      statusColor = Colors.green;
    }

    if (item.age == 3) {
      ageColor = const Color.fromARGB(255, 25, 0, 255);
    } else if (item.age == 4) {
      ageColor = const Color.fromARGB(255, 78, 69, 255);
    } else if (item.age == 5) {
      ageColor = const Color.fromARGB(255, 0, 98, 255);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Slidable(
        key: ValueKey(item.activityFormName),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                _editForm(item);
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) async {
                _deleteForm(item);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.assignment,
              color: Colors.deepPurple,
            ),
            title: GText(
              '${item.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTag(
                      text: item.formType,
                      color: typeColor,
                    ),
                    const SizedBox(width: 8),
                    _buildTag(
                      text: item.formStatus,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    _buildTag(
                      text: '${item.age} years old',
                      color: ageColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.activityBoards.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'Activity Board: ${item.activityBoards.first}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    else
                      _buildTag(
                        text: 'No board',
                        color: Colors.grey,
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 8),
                GText('Pediatric Name: ${item.name}'),
                const SizedBox(height: 4),
                GText('Therapist Name: ${item.therapist}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GText(
                        'Created: ${DateFormat.yMMMd().format(item.dateCreated)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GText(
                        'Modified: ${DateFormat.yMMMd().format(item.dateModified)}'),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                item.isFavorite ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () async {
                setState(() {
                  item.isFavorite = !item.isFavorite;
                  activityFormsData.remove(item);
                  activityFormsData.insert(0, item);
                });

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final userEmail = user?.email;

                  final userDoc = await FirebaseFirestore.instance
                      .collection('user')
                      .where('email', isEqualTo: userEmail)
                      .limit(1)
                      .get();

                  if (userDoc.docs.isNotEmpty) {
                    final userId = userDoc.docs.first.id;
                    final collectionName =
                    item.formType == 'PLS-5' ? 'PLS5Form' : 'BriganceForm';

                    final documentSnapshot = await FirebaseFirestore.instance
                        .collection('user')
                        .doc(userId)
                        .collection(collectionName)
                        .where('date', isEqualTo: item.date)
                        .get();

                    if (documentSnapshot.docs.isNotEmpty) {
                      String documentId = documentSnapshot.docs.first.id;
                      await FirebaseFirestore.instance
                          .collection('user')
                          .doc(userId)
                          .collection(collectionName)
                          .doc(documentId)
                          .update({'isFavorite': item.isFavorite});
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: GText('Error updating form: $e')),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _editForm(ActivityForms item) {
    Widget formWidget;

    if (item.formType == 'PLS-5') {
      formWidget = CreatePLS5Form_Widget(
        initialData: item,
      );
    } else if (item.formType == 'Brigance') {
      formWidget = CreateBriganceForm_Widget(
        initialData: item,
      );
    } else {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => formWidget,
      ),
    );
  }

  Widget _buildTag({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: GText(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            color: Colors.red,
          ),
          GText('No data found.'),
        ],
      ),
    );
  }
}