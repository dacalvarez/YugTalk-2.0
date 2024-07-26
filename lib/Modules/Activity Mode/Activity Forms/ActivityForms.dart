import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityForms {
  final String activityFormName;
  final String formType;
  final String formStatus;
  final int age;
  final DateTime dateCreated;
  DateTime dateModified;
  bool isFavorite;
  final List<String> activityBoards;
  final String gender;
  final String therapist;
  final DateTime? date;
  final String name;
  final bool isActivityBoard;

  // Fields for PLS-5 form
  final String pls5AuditoryComprehensionStandardScore;
  final String pls5AuditoryComprehensionPercentileRank;
  final String pls5AuditoryComprehensionDescriptiveRange;
  final String pls5ExpressiveCommunicationStandardScore;
  final String pls5ExpressiveCommunicationPercentileRank;
  final String pls5ExpressiveCommunicationDescriptiveRange;
  final String pls5TotalLanguageScoreStandardScore;
  final String pls5TotalLanguageScorePercentileRank;
  final String pls5TotalLanguageScoreDescriptiveRange;
  final String pls5TotalLanguageScoreSummary;
  final String pls5AuditoryComprehensionSummary;
  final String pls5ExpressiveCommunicationSummary;
  final String pls5OtherComments;

  // Fields for Brigance form
  final List<Map<String, String>> briganceRows;
  final List<Map<String, String>> pls5Rows;
  final String otherComments;
  final String nextSteps;

  ActivityForms({
    required this.activityFormName,
    required this.formType,
    required this.formStatus,
    required this.age,
    required this.dateCreated,
    required this.dateModified,
    required this.activityBoards,
    this.isFavorite = false,
    this.gender = '',
    this.name = '',
    this.therapist = '',
    this.isActivityBoard = false,
    required this.date,
    this.pls5AuditoryComprehensionStandardScore = '',
    this.pls5AuditoryComprehensionPercentileRank = '',
    this.pls5AuditoryComprehensionDescriptiveRange = '',
    this.pls5ExpressiveCommunicationStandardScore = '',
    this.pls5ExpressiveCommunicationPercentileRank = '',
    this.pls5ExpressiveCommunicationDescriptiveRange = '',
    this.pls5TotalLanguageScoreStandardScore = '',
    this.pls5TotalLanguageScorePercentileRank = '',
    this.pls5TotalLanguageScoreDescriptiveRange = '',
    this.pls5TotalLanguageScoreSummary = '',
    this.pls5AuditoryComprehensionSummary = '',
    this.pls5ExpressiveCommunicationSummary = '',
    this.pls5OtherComments = '',
    this.briganceRows = const [],
    this.pls5Rows = const [],
    this.otherComments = '',
    this.nextSteps = '',
  });

  factory ActivityForms.fromMap(Map<String, dynamic> map) {
    final activityBoards = map['activity_board_dropdown'];
    final activityBoardsList = activityBoards is String
        ? [activityBoards]
        : (activityBoards as List<dynamic>?)?.cast<String>() ?? [];

    List<Map<String, String>> convertToListOfMaps(List<dynamic> list) {
      return list.map((item) {
        if (item is Map<dynamic, dynamic>) {
          return item
              .map((key, value) =>
              MapEntry(key.toString(), value?.toString() ?? ''))
              .cast<String, String>();
        } else {
          return <String, String>{};
        }
      }).toList();
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return ActivityForms(
      activityFormName: map['activityFormName'] as String? ?? '',
      formType: map['formType'] as String? ?? '',
      formStatus: map['formStatus'] as String? ?? '',
      name: map['name'] as String? ?? '',
      age: map['age'] as int? ?? 0,
      dateCreated:
      (map['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModified:
      (map['dateModified'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activityBoards: activityBoardsList,
      gender: map['gender'] as String? ?? '',
      therapist: map['therapist'] as String? ?? '',
      date: map['date'] != null
          ? map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : map['date'] is String
          ? dateFormat.parse(map['date'])
          : null
          : null,
      pls5TotalLanguageScoreSummary:
      map['total_language_score_summary'] as String? ?? '',
      pls5AuditoryComprehensionSummary:
      map['auditory_comprehension_summary'] as String? ?? '',
      pls5ExpressiveCommunicationSummary:
      map['expressive_communication_summary'] as String? ?? '',
      pls5OtherComments: map['other_comments'] as String? ?? '',
      briganceRows: convertToListOfMaps(map['briganceRows'] ?? []),
      pls5Rows: convertToListOfMaps(map['pls5Rows'] ?? []),
      otherComments: map['other_comments'] as String? ?? '',
      nextSteps: map['next_steps'] as String? ?? '',
    );
  }
}

List<ActivityForms> activityFormsData = [
  ActivityForms(
    activityFormName: 'PLS-5 Age 3 John Doe',
    formType: 'PLS-5',
    formStatus: 'Successful',
    name: 'John Doe',
    age: 3,
    dateCreated: DateTime(2024, 1, 15),
    dateModified: DateTime(2024, 1, 18),
    activityBoards: ['John Doe (3) Basic Needs Board'],
    isFavorite: true,
    gender: 'Male',
    therapist: 'Dr. Smith',
    date: DateTime(2024, 1, 15),
    pls5AuditoryComprehensionStandardScore: '100',
    pls5AuditoryComprehensionPercentileRank: '90',
    pls5AuditoryComprehensionDescriptiveRange: 'Above Average',
    pls5ExpressiveCommunicationStandardScore: '95',
    pls5ExpressiveCommunicationPercentileRank: '85',
    pls5ExpressiveCommunicationDescriptiveRange: 'Average',
    pls5TotalLanguageScoreStandardScore: '98',
    pls5TotalLanguageScorePercentileRank: '88',
    pls5TotalLanguageScoreDescriptiveRange: 'Above Average',
    pls5TotalLanguageScoreSummary: 'Overall excellent',
    pls5AuditoryComprehensionSummary:
    'John demonstrated auditory comprehension by pointing to letters, identifying colors, understanding negatives in sentences, recognizing action in pictures, following commands without gestural cues, engaging in symbolic play, engaging in pretend play, understanding verbs in context, and identifying things you wear. He did not demonstrate ordering pictures by qualitative concept, understanding of modified nouns, emergent literacy skills, understanding of complex sentences, understanding of quantitative concepts, identifying advanced body parts, identifying shapes, understanding pronouns, understanding spatial concepts, understanding sentences with post-noun elaboration, understanding analogies, making inferences, or understanding use of objects. John\'s standard score of 100 indicates that his receptive language skills are within the average range as compared to same-age peers.',
    pls5ExpressiveCommunicationSummary:
    'John demonstrated expressive communication skills by using plurals, producing multi-word sentences, using a variety of words in spontaneous speech, and naming a variety of pictured objects. He did not demonstrate answering questions about hypothetical events, telling how an object is used, using possessives, answering questions logically, naming described objects, answering what and where questions, or using present progressive. John\'s standard score of 95 indicates that his expressive language skills are within the average range as compared to same-age peers.',
    pls5OtherComments: 'None',
    pls5Rows: [
      {
        'Subsets/Score': 'Auditory Comprehension',
        'Standard Score (#)': '',
        'Percentile Rank (%)': '',
        'Descriptive Range (average/below average)': '',
      },
      {
        'Subsets/Score': 'Expressive Communication',
        'Standard Score (#)': '',
        'Percentile Rank (%)': '',
        'Descriptive Range (average/below average)': '',
      },
      {
        'Subsets/Score': 'Total Language Score',
        'Standard Score (#)': '',
        'Percentile Rank (%)': '',
        'Descriptive Range (average/below average)': '',
      },
    ],
  ),
  ActivityForms(
    activityFormName: 'Brigance Age 4 Jane Smith',
    formType: 'Brigance',
    formStatus: 'In Progress',
    name: 'Jane Smith',
    age: 4,
    dateCreated: DateTime(2024, 2, 20),
    dateModified: DateTime(2024, 2, 25),
    activityBoards: ['Jane Smith (4) Cognitive and Language Development Board'],
    isFavorite: false,
    gender: 'Female',
    therapist: 'Dr. Brown',
    date: DateTime(2024, 2, 20),
    briganceRows: [
      {
        'Domain': 'Academic/Cognitive',
        'Order':
        '1A Knows Personal Information. Knows: 1. First name 2. Last name 3. Age',
        'Duration': 'Stop after 3 incorrect responses in a row',
        'No. Correct * Value': '___ x 2.5',
        'Subtotal Score': '_ / 10',
      },
      {
        'Domain': 'Language Development',
        'Order':
        '2A Identifies Colors. Points to: 1. red 2. blue 3. green 4. yellow 5. orange',
        'Duration': 'Stop after 3 incorrect responses in a row',
        'No. Correct * Value': '___ x 2',
        'Subtotal Score': '_ / 10',
      },
      {
        'Domain': 'Total Score',
        'Order': '',
        'Duration': '',
        'No. Correct * Value': '',
        'Subtotal Score': '',
      },
    ],
    otherComments: 'Needs improvement in color identification',
    nextSteps: 'Practice color identification daily',
  ),
  ActivityForms(
    activityFormName: 'Brigance Age 3 Kenny Smith',
    formType: 'Brigance',
    formStatus: 'To Do',
    name: 'Kenny Smith',
    age: 3,
    dateCreated: DateTime(2024, 5, 18),
    dateModified: DateTime(2024, 5, 20),
    activityBoards: ['Kenny Smith (3) Social Interaction Board'],
    isFavorite: false,
    gender: 'Male',
    therapist: 'Dr. Green',
    date: DateTime(2024, 5, 18),
    briganceRows: [
      {
        'Domain': 'Academic/Cognitive',
        'Order':
        '1A Knows Personal Information. Knows: 1. First name 2. Last name 3. Age',
        'Duration': 'Stop after 3 incorrect responses in a row',
        'No. Correct * Value': '___ x 2.5',
        'Subtotal Score': '_ / 10',
      },
      {
        'Domain': 'Language Development',
        'Order':
        '2A Identifies Colors. Points to: 1. red 2. blue 3. green 4. yellow 5. orange',
        'Duration': 'Stop after 3 incorrect responses in a row',
        'No. Correct * Value': '___ x 2',
        'Subtotal Score': '_ / 10',
      },
      {
        'Domain': 'Total Score',
        'Order': '',
        'Duration': '',
        'No. Correct * Value': '',
        'Subtotal Score': '',
      },
    ],
    otherComments: '',
    nextSteps: '',
  ),
  ActivityForms(
    activityFormName: 'Brigance Age 3 Wendy Pearson',
    formType: 'Brigance',
    formStatus: 'To Do',
    name: 'Wendy Pearson',
    age: 3,
    dateCreated: DateTime(2024, 5, 17),
    dateModified: DateTime(2024, 5, 19),
    activityBoards: ['Wendy Pearson (3) Academic Support Board'],
    isFavorite: false,
    gender: 'Female',
    therapist: 'Dr. Blue',
    date: DateTime(2024, 5, 17),
    briganceRows: [
      {
        'Domain': 'Academic/Cognitive',
        'Order':
        '1A Knows Personal Information. Knows: 1. First name 2. Last name 3. Age',
        'Duration': 'Stop after 3 incorrect responses in a row',
        'No. Correct * Value': '___ x 2.5',
        'Subtotal Score': '_ / 10',
      },
      {
        'Domain': 'Language Development',
        'Order':
        '2A Identifies Colors. Points to: 1. red 2. blue 3. green 4. yellow 5. orange',
        'Duration': 'Stop after 3 incorrect responses in a row',
        'No. Correct * Value': '___ x 2',
        'Subtotal Score': '_ / 10',
      },
      {
        'Domain': 'Total Score',
        'Order': '',
        'Duration': '',
        'No. Correct * Value': '',
        'Subtotal Score': '',
      },
    ],
    otherComments: '',
    nextSteps: '',
  ),
];