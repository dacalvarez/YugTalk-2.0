import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../Activity Forms/ActivityForms.dart';
import '../Activity Forms/CreateBriganceForm_Widget.dart';
import '../Activity Forms/CreatePLS5Form_Widget.dart';
import 'package:intl/intl.dart';

class StatsActGraphs_Widget extends StatefulWidget {
  const StatsActGraphs_Widget({super.key, required List<ActivityForms> activityForms});

  @override
  _StatsActGraphs_WidgetState createState() => _StatsActGraphs_WidgetState();
}

class _StatsActGraphs_WidgetState extends State<StatsActGraphs_Widget> {
  String _selectedStatus = 'All Statuses';
  String _selectedFormType = 'All Types';
  String _searchQuery = '';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  List<ActivityForms> _filteredForms = [];
  late TooltipBehavior _tooltipBehavior;
  int? _selectedIndex;
  String _popupSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
    _fetchAllFormsFromFirestore().then((forms) {
      setState(() {
        _filteredForms = forms;
      });
    });
  }

  Future<List<ActivityForms>> _fetchAllFormsFromFirestore({
    String? searchQuery,
    String? formType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    final userDoc = await FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      final userId = userDoc.docs.first.id;
      List<ActivityForms> forms = [];

      if (formType == null || formType == 'All Types' || formType == 'PLS-5') {
        final pls5Snapshot = await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('PLS5Form')
            .get();

        forms.addAll(_processForms(pls5Snapshot, 'PLS-5'));
      }

      if (formType == null || formType == 'All Types' || formType == 'Brigance') {
        final briganceSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('BriganceForm')
            .get();

        forms.addAll(_processForms(briganceSnapshot, 'Brigance'));
      }

      forms = forms.where((form) {
        bool matchesSearch = searchQuery == null || searchQuery.isEmpty ||
            form.activityFormName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            form.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            form.therapist.toLowerCase().contains(searchQuery.toLowerCase());

        bool matchesStatus = status == null || status == 'All Statuses' || form.formStatus == status;

        bool matchesDateRange = (startDate == null || form.dateCreated.isAfter(startDate)) &&
            (endDate == null || form.dateCreated.isBefore(endDate.add(const Duration(days: 1))));

        return matchesSearch && matchesStatus && matchesDateRange;
      }).toList();

      return forms;
    } else {
      return [];
    }
  }

  List<ActivityForms> _processForms(QuerySnapshot snapshot, String formType) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final name = data['name'] ?? '';
      final activityBoardsValue = data['activity_board_dropdown'];
      final activityBoards = activityBoardsValue is String
          ? activityBoardsValue.split(',')
          : activityBoardsValue?.toString().split(',') ?? [];

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
        final pls5RowsData = data['pls5Rows'];
        List<Map<String, String>> pls5Rows = [];
        if (pls5RowsData is List) {
          pls5Rows = pls5RowsData.map((row) {
            if (row is Map) {
              return row.map((key, value) => MapEntry(key.toString(), value.toString()));
            } else {
              return <String, String>{};
            }
          }).toList();
        }

        return ActivityForms(
          formType: 'PLS-5',
          activityFormName: data['activityFormName'] ?? '',
          activityBoards: activityBoards,
          age: int.tryParse(data['age'] ?? '0') ?? 0,
          date: date,
          pls5AuditoryComprehensionSummary: data['auditory_comprehension_summary'],
          dateCreated: date,
          pls5ExpressiveCommunicationSummary: data['expressive_communication_summary'],
          formStatus: data['formStatus'] ?? '',
          gender: data['gender'] ?? '',
          name: name,
          nextSteps: data['next_steps'] ?? '',
          pls5OtherComments: data['other_comments'] ?? '',
          pls5Rows: pls5Rows,
          therapist: data['therapist'] ?? '',
          pls5TotalLanguageScoreSummary: data['total_language_score_summary'],
          dateModified: date,
        );
      } else if (formType == 'Brigance') {
        final briganceRowsData = data['briganceRows'];
        List<Map<String, String>> briganceRows = [];
        if (briganceRowsData is List) {
          briganceRows = briganceRowsData.map((row) {
            if (row is Map) {
              return row.map((key, value) => MapEntry(key.toString(), value.toString()));
            } else {
              return <String, String>{};
            }
          }).toList();
        }

        return ActivityForms(
          formType: 'Brigance',
          activityFormName: data['activityFormName'] ?? '',
          activityBoards: activityBoards,
          age: int.tryParse(data['age'] ?? '0') ?? 0,
          briganceRows: briganceRows,
          date: date,
          dateCreated: date,
          formStatus: data['formStatus'] ?? '',
          gender: data['gender'] ?? '',
          name: name,
          nextSteps: data['next_steps'] ?? '',
          otherComments: data['other_comments'] ?? '',
          therapist: data['therapist'] ?? '',
          dateModified: date,
        );
      } else {
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
          therapist: data['therapist'] ?? '',
          dateModified: date,
        );
      }
    }).toList();
  }

  Future<Map<String, int>> _fetchFormCountsByStatusFromFirestore({
    String? formType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    final forms = await _fetchAllFormsFromFirestore(searchQuery: searchQuery);
    final filteredForms = _applyFilters(forms, formType, status, startDate, endDate);
    final statusCounts = <String, int>{};

    for (final form in filteredForms) {
      final status = form.formStatus;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return statusCounts;
  }

  List<ActivityForms> _applyFilters(
      List<ActivityForms> forms,
      String? formType,
      String? status,
      DateTime? startDate,
      DateTime? endDate,
      ) {
    return forms.where((form) {
      bool isValidFormType = formType == null || formType == 'All Types' || form.formType == formType;
      bool isValidStatus = status == null || status == 'All Statuses' || form.formStatus == status;
      bool isValidDateRange = (startDate == null || form.dateCreated.isAfter(startDate)) &&
          (endDate == null || form.dateCreated.isBefore(endDate));

      return isValidFormType && isValidStatus && isValidDateRange;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GText('Activity Forms Statistics'),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = null;
            _popupSearchQuery = '';
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildContainerWithTitle(
                    title: 'Form Type',
                    child: DropdownButton<String>(
                      value: _selectedFormType,
                      onChanged: (value) {
                        setState(() {
                          _selectedFormType = value!;
                        });
                      },
                      items: [
                        const DropdownMenuItem(
                          value: 'All Types',
                          child: GText('All Types'),
                        ),
                        ..._getFormTypes().map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: GText(type),
                          );
                        }),
                      ],
                    ),
                  ),
                  _buildContainerWithTitle(
                    title: 'Date Range',
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectStartDate(context),
                          child: GText(_selectedStartDate != null
                              ? 'Start Date: ${_selectedStartDate!.toString().split(' ')[0]}'
                              : 'Start Date'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _selectEndDate(context),
                          child: GText(_selectedEndDate != null
                              ? 'End Date: ${_selectedEndDate!.toString().split(' ')[0]}'
                              : 'End Date'),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _resetSelections(),
                        ),
                      ],
                    ),
                  ),
                  _buildContainerWithTitle(
                    title: 'Status',
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                      items: [
                        const DropdownMenuItem(
                          value: 'All Statuses',
                          child: GText('All Statuses'),
                        ),
                        ..._getFormStatuses().map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: GText(status),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<Map<String, int>>(
                  future: _fetchFormCountsByStatusFromFirestore(
                    formType: _selectedFormType == 'All Types' ? null : _selectedFormType,
                    status: _selectedStatus == 'All Statuses' ? null : _selectedStatus,
                    startDate: _selectedStartDate,
                    endDate: _selectedEndDate,
                    searchQuery: _searchQuery.isNotEmpty ? _searchQuery.toLowerCase() : null,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: GText('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: GText('No forms found.'));
                    } else {
                      Map<String, int> statusCounts = snapshot.data!;
                      List<PieSeriesData> pieData = statusCounts.entries
                          .map((entry) => PieSeriesData(entry.key, entry.value))
                          .toList();

                      int totalCount = pieData.fold(0, (sum, data) => sum + data.y);

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = null;
                                _popupSearchQuery = '';
                              });
                            },
                            child: _buildPieChart(pieData),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GText(
                                  'Total',
                                  style: TextStyle(
                                    //fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GText(
                                  '$totalCount',
                                  style: const TextStyle(
                                    //fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey),
      ),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Search Activity Forms',
          hintText: 'Enter activity form name',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildContainerWithTitle({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GText(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildPieChart(List<PieSeriesData> pieData) {
    return SfCircularChart(
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        position: LegendPosition.bottom,
        //textStyle: TextStyle(fontSize: 14),
      ),
      tooltipBehavior: _tooltipBehavior,
      series: <CircularSeries>[
        DoughnutSeries<PieSeriesData, String>(
          dataSource: pieData,
          xValueMapper: (PieSeriesData data, _) => data.x,
          yValueMapper: (PieSeriesData data, _) => data.y,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(
              //fontSize: 14,
              color: Colors.white,
            ),
          ),
          innerRadius: '70%',
          radius: '80%',
          enableTooltip: true,
          explode: true,
          explodeIndex: _selectedIndex,
          onPointTap: (ChartPointDetails details) {
            if (details.pointIndex != null) {
              String status = pieData[details.pointIndex!].x;
              _showDetailsDialog(context, status);
            }
          },
        ),
      ],
    );
  }

  void _showDetailsDialog(BuildContext context, String status) {
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
                        //hintStyle: TextStyle(fontSize: 14.0),
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
                child: FutureBuilder<List<ActivityForms>>(
                  future: _fetchAllFormsFromFirestore(
                    searchQuery: (_searchQuery + ' ' + _popupSearchQuery).toLowerCase().trim(),
                    formType: _selectedFormType == 'All Types' ? null : _selectedFormType,
                    status: status,
                    startDate: _selectedStartDate,
                    endDate: _selectedEndDate,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: GText('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: GText('No forms found.'));
                    } else {
                      List<ActivityForms> forms = snapshot.data!;
                      List<ActivityForms> filteredForms = forms
                          .where((form) => form.formStatus == status)
                          .toList();
                      final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredForms.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            ActivityForms form = filteredForms[index];
                            return ListTile(
                              title: GText(form.activityFormName),
                              subtitle: GText(
                                'Type: ${form.formType}\n'
                                    'Status: ${form.formStatus}\n'
                                    'Name: ${form.name}\n'
                                    'Age: ${form.age}\n'
                                    'Gender: ${form.gender}\n'
                                    'Therapist: ${form.therapist}\n'
                                    'Date Created: ${dateFormat.format(form.dateCreated)}\n',
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                _navigateToForm(context, form);
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
                      _selectedIndex = null;
                      _popupSearchQuery = '';
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _selectedIndex = null;
      });
    });
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

  void _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  void _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  void _resetSelections() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  List<String> _getFormTypes() {
    return _filteredForms.map((form) => form.formType).toSet().toList();
  }

  List<String> _getFormStatuses() {
    return _filteredForms.map((form) => form.formStatus).toSet().toList();
  }
}

class PieSeriesData {
  final String x;
  final int y;

  PieSeriesData(this.x, this.y);
}
