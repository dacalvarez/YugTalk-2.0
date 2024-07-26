import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'WordUsage.dart'; // Import the WordUsage class and categories list

class StatsWrdGraphs_Widget extends StatefulWidget {
  final List<WordUsage> wordUsages;

  const StatsWrdGraphs_Widget({super.key, required this.wordUsages});

  @override
  // ignore: library_private_types_in_public_api
  _StatsWrdGraphs_WidgetState createState() => _StatsWrdGraphs_WidgetState();
}

enum ChartType { column }

enum SortType { alphabetical, mostUsedToLeastUsed, leastUsedToMostUsed, none }

SortType _currentSortType = SortType.none;

class _StatsWrdGraphs_WidgetState extends State<StatsWrdGraphs_Widget> {
  String _filterText = '';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedCategory; // Selected category from dropdown
  final Set<Location> _selectedLocations = <Location>{};
  int _minFrequency = 0;
  int _maxFrequency = 1000; // Set the maximum frequency initially
  late List<WordUsage> _originalWordUsages;

  // Initialize the original order list in the initState method
  @override
  void initState() {
    super.initState();
// Set column chart as default
    _originalWordUsages = List<WordUsage>.from(widget.wordUsages);
    _sortByAlphabeticalOrder(); // Apply alphabetical sorting by default
  }

  @override
  Widget build(BuildContext context) {
    Set<String> uniqueWords =
        widget.wordUsages.map((wordUsage) => wordUsage.word).toSet();
    return Scaffold(
      appBar: AppBar(
        title: GText('Word Usage Statistics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Filter Words',
                  hintText: 'Enter a word to filter',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _filterText = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildContainerWithTitle(
                  title: 'Category',
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    hint: GText('Choose category'),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory =
                            _selectedCategory == value ? null : value;
                      });
                    },
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: GText('Category'),
                      ),
                      ...widget.wordUsages
                          .expand((wordUsage) => [wordUsage.category])
                          .toSet()
                          .toList()
                          .map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: GText(category),
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
                      const SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: () => _selectEndDate(context),
                        child: GText(_selectedEndDate != null
                            ? 'End Date: ${_selectedEndDate!.toString().split(' ')[0]}'
                            : 'End Date'),
                      ),
                      const SizedBox(width: 5),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _resetSelections(),
                      ),
                    ],
                  ),
                ),
                _buildContainerWithTitle(
                  title: 'Location Filters',
                  child: Row(
                    children: [
                      _buildFilterButton(Location.Home),
                      const SizedBox(width: 5),
                      _buildFilterButton(Location.School),
                      const SizedBox(width: 5),
                      _buildFilterButton(Location.Clinic),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GText('Minimum: $_minFrequency'),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(
                      _minFrequency.toDouble(),
                      _maxFrequency.toDouble(),
                    ),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels(
                      _minFrequency.toString(),
                      _maxFrequency.toString(),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _minFrequency = values.start.round();
                        _maxFrequency = values.end.round();
                      });
                    },
                  ),
                ),
                GText('Maximum: $_maxFrequency'),
                const SizedBox(
                    width: 20), // Add spacing between the slider and the button
                ElevatedButton(
                  onPressed: () {
                    _showSortOptions(context);
                  },
                  child: GText('Sort'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerWithTitle(
      {required String title, required Widget child}) {
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

  Widget _buildFilterButton(Location location) {
    bool isSelected = _selectedLocations.contains(location);

    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (isSelected) {
            _selectedLocations.remove(location); // Deselect if already selected
          } else {
            _selectedLocations.add(location); // Select if not selected
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
      ),
      child: GText(location.toString().split('.').last),
    );
  }

  int _getFrequency(WordUsage wordUsage) {
    // Calculate daily frequency by summing up the frequencies for each date and location
    int sum = 0;
    for (var dateUsage in wordUsage.datesOfUsage) {
      dateUsage.forEach((date, locationFrequencies) {
        for (var locationFrequency in locationFrequencies) {
          sum += locationFrequency
              .frequency; // Access the frequency property directly
        }
      });
    }
    return sum;
  }

  Widget _buildChart() {
    List<WordUsage> filteredWords = _getFilteredWords();

    // Apply sorting based on the current sort type
    switch (_currentSortType) {
      case SortType.none:
        // No sorting required, proceed with the original order
        break;
      case SortType.alphabetical:
        // Sort alphabetically
        filteredWords.sort((a, b) => a.word.compareTo(b.word));
        break;
      case SortType.mostUsedToLeastUsed:
        // Sort from most used to least used
        filteredWords
            .sort((a, b) => _getFrequency(b).compareTo(_getFrequency(a)));
        break;
      case SortType.leastUsedToMostUsed:
        // Sort from least used to most used
        filteredWords
            .sort((a, b) => _getFrequency(a).compareTo(_getFrequency(b)));
        break;
    }

    // Directly return the column chart
    return _buildColumnChart(filteredWords);
  }

  List<WordUsage> _getFilteredWords() {
    List<WordUsage> filteredWords = widget.wordUsages;

    // Apply filters based on location
    if (_selectedLocations.isNotEmpty) {
      filteredWords = filteredWords.where((word) {
        return word.datesOfUsage.any((usage) {
          return usage.values.any((locationFrequencies) {
            return locationFrequencies.any((locationFrequency) {
              Location recordLocation = locationFrequency.location;
              return _selectedLocations.contains(recordLocation);
            });
          });
        });
      }).toList();
    }

    // Apply filters based on text
    if (_filterText.isNotEmpty) {
      List<String> searchWords =
          _filterText.toLowerCase().split(RegExp(r',\s*|\s+'));
      filteredWords = filteredWords.where((word) {
        return searchWords.any((searchWord) {
          return word.word.toLowerCase().contains(searchWord);
        });
      }).toList();
    }

    // Apply filters based on category
    if (_selectedCategory != null) {
      filteredWords = filteredWords.where((word) {
        return word.category.toLowerCase() == _selectedCategory!.toLowerCase();
      }).toList();
    }

    // Apply filters based on dates if start and end dates are selected
    if (_selectedStartDate != null && _selectedEndDate != null) {
      filteredWords = filteredWords.where((word) {
        return word.datesOfUsage.any((usage) {
          DateTime usageDate = usage.keys.first;
          // Check if the usage date is within the selected date range
          return (usageDate.isAfter(_selectedStartDate!) ||
                  usageDate == _selectedStartDate!) &&
              (usageDate.isBefore(_selectedEndDate!) ||
                  usageDate == _selectedEndDate!);
        });
      }).toList();
    }

    // Apply filters based on frequency range
    filteredWords = filteredWords.where((word) {
      int frequency = _getFrequency(word);
      return frequency >= _minFrequency && frequency <= _maxFrequency;
    }).toList();

    return filteredWords;
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

  Widget _buildColumnChart(List<WordUsage> filteredWords) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width:
            MediaQuery.of(context).size.width, // Use the full available width
        child: SfCartesianChart(
          primaryXAxis: const CategoryAxis(),
          series: <CartesianSeries<WordUsage, String>>[
            ColumnSeries<WordUsage, String>(
              width: 0.8, // Adjust the width of the bars
              dataSource: filteredWords,
              xValueMapper: (WordUsage wordUsage, _) => wordUsage.word,
              yValueMapper: (WordUsage wordUsage, _) =>
                  _getFrequency(wordUsage).toDouble(),
              // Assign colors dynamically based on word usage
              pointColorMapper: (WordUsage wordUsage, _) =>
                  _getBarColor(wordUsage),
              dataLabelSettings: const DataLabelSettings(isVisible: true),
              // Adding tap gesture for each column
              onPointTap: (ChartPointDetails details) {
                if (details.pointIndex != null) {
                  WordUsage wordUsage = filteredWords[details.pointIndex!];
                  _showWordUsageDialog(context, wordUsage);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWordUsageDialog(BuildContext context, WordUsage wordUsage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GText('Word Usage'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Word', wordUsage.word),
              _buildInfoRow('Category', wordUsage.category),
              const SizedBox(height: 8),
              _buildUsageTable(wordUsage.datesOfUsage
                  .cast<Map<DateTime, List<LocationFrequency>>>()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GText(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GText(value),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTable(
      List<Map<DateTime, List<LocationFrequency>>> datesOfUsage) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: GText('Date')),
          DataColumn(label: GText('Location')),
          DataColumn(label: GText('Frequency')),
        ],
        rows: datesOfUsage.expand((usage) {
          return usage.entries.map((entry) {
            final date = entry.key;
            final locationFrequencies = entry.value;

            return DataRow(cells: [
              DataCell(GText(_formatDate(date))),
              DataCell(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: locationFrequencies.map((locationFrequency) {
                  final location = locationFrequency.location;
                  final frequency = locationFrequency.frequency;

                  return GText(
                      '${location.toString().split('.').last}: $frequency');
                }).toList(),
              )),
              DataCell(GText(locationFrequencies
                  .fold<int>(0, (sum, lf) => sum + lf.frequency)
                  .toString())),
            ]);
          });
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_addLeadingZero(date.month)}-${_addLeadingZero(date.day)}';
  }

  String _addLeadingZero(int number) {
    return number.toString().padLeft(2, '0');
  }

  Color _getBarColor(WordUsage wordUsage) {
    // Check if daily frequency is greater than or equal to 5
    if (wordUsage.dailyFrequency >= 10) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: GText('Alphabetical Order'),
              onTap: () {
                if (_currentSortType != SortType.alphabetical) {
                  _sortByAlphabeticalOrder();
                  Navigator.pop(context);
                }
              },
              selected: _currentSortType == SortType.alphabetical,
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: GText('Most Used to Least Used'),
              onTap: () {
                if (_currentSortType != SortType.mostUsedToLeastUsed) {
                  _sortByMostUsedToLeastUsed();
                  Navigator.pop(context);
                }
              },
              selected: _currentSortType == SortType.mostUsedToLeastUsed,
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: GText('Least Used to Most Used'),
              onTap: () {
                if (_currentSortType != SortType.leastUsedToMostUsed) {
                  _sortByLeastUsedToMostUsed();
                  Navigator.pop(context);
                }
              },
              selected: _currentSortType == SortType.leastUsedToMostUsed,
            ),
          ],
        );
      },
    );
  }

  // Modify the other sorting methods to update both the original and current lists
  void _sortByAlphabeticalOrder() {
    setState(() {
      widget.wordUsages.sort((a, b) => a.word.compareTo(b.word));
      _originalWordUsages.clear();
      _originalWordUsages.addAll(widget.wordUsages);
      _currentSortType = SortType.alphabetical;
    });
  }

  void _sortByMostUsedToLeastUsed() {
    setState(() {
      widget.wordUsages
          .sort((a, b) => _getFrequency(b).compareTo(_getFrequency(a)));
      _originalWordUsages.clear();
      _originalWordUsages.addAll(widget.wordUsages);
      _currentSortType = SortType.mostUsedToLeastUsed;
    });
  }

  void _sortByLeastUsedToMostUsed() {
    setState(() {
      widget.wordUsages
          .sort((a, b) => _getFrequency(a).compareTo(_getFrequency(b)));
      _originalWordUsages.clear();
      _originalWordUsages.addAll(widget.wordUsages);
      _currentSortType = SortType.leastUsedToMostUsed;
    });
  }
}
