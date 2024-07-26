enum Location { Home, School, Clinic }

class LocationFrequency {
  final Location location;
  final int frequency;

  LocationFrequency(this.location, this.frequency);
}

class WordUsage {
  final String word;
  final String category;
  final List<Map<DateTime, List<LocationFrequency>>> datesOfUsage;

  var index;

  WordUsage(this.word, this.category, this.datesOfUsage);

  int get dailyFrequency {
    int sum = 0;
    datesOfUsage.forEach((usage) {
      usage.values.forEach((locationFrequencies) {
        locationFrequencies.forEach((locationFrequency) {
          sum += locationFrequency.frequency;
        });
      });
    });
    return sum;
  }

  bool get isMostUsed {
    return dailyFrequency >= 10;
  }

  bool get isLeastUsed {
    return dailyFrequency < 10;
  }
}

List<WordUsage> generateDummyData() {
  List<WordUsage> wordUsages = [
    WordUsage(
      'yes',
      'Affirmation',
      [
        {
          DateTime(2024, 1, 1): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 2),
          ]
        },
        {
          DateTime(2024, 1, 2): [
            LocationFrequency(Location.School, 6),
            LocationFrequency(Location.Clinic, 3),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      'no',
      'Negation',
      [
        {
          DateTime(2024, 1, 3): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 1, 4): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 1, 5): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 5),
          ]
        },
        {
          DateTime(2024, 1, 6): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 1, 7): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 1, 8): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 2),
          ]
        },
        {
          DateTime(2024, 1, 9): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 6),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      'happy',
      'Emotion',
      [
        {
          DateTime(2024, 1, 1): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 1, 2): [
            LocationFrequency(Location.School, 4),
            LocationFrequency(Location.Clinic, 2),
          ]
        },
        {
          DateTime(2024, 1, 3): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 5),
          ]
        },
        {
          DateTime(2024, 1, 4): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 1, 5): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 1, 6): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 6),
          ]
        },
        {
          DateTime(2024, 1, 7): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 4),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      'sad',
      'Emotion',
      [
        {
          DateTime(2024, 1, 1): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 2),
          ]
        },
        {
          DateTime(2024, 1, 2): [
            LocationFrequency(Location.School, 3),
            LocationFrequency(Location.Clinic, 4),
          ]
        },
        {
          DateTime(2024, 1, 3): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 5),
          ]
        },
        {
          DateTime(2024, 1, 4): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 1, 5): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 1, 6): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 2),
          ]
        },
        {
          DateTime(2024, 1, 7): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 6),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      'awkward',
      'Emotion',
      [
        {
          DateTime(2024, 1, 1): [
            LocationFrequency(Location.School, 2),
          ]
        },
        {
          DateTime(2024, 1, 2): [
            LocationFrequency(Location.Clinic, 2),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      'hello',
      'Greeting',
      [
        {
          DateTime(2024, 1, 1): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 1, 2): [
            LocationFrequency(Location.School, 4),
            LocationFrequency(Location.Clinic, 3),
          ]
        },
        {
          DateTime(2024, 1, 3): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 6),
          ]
        },
        {
          DateTime(2024, 1, 4): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 5),
          ]
        },
        {
          DateTime(2024, 1, 5): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 1, 6): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 1, 7): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 2),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      'goodbye',
      'Farewell',
      [
        {
          DateTime(2024, 1, 1): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 1, 2): [
            LocationFrequency(Location.School, 4),
            LocationFrequency(Location.Clinic, 2),
          ]
        },
        {
          DateTime(2024, 1, 3): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 5),
          ]
        },
        {
          DateTime(2024, 1, 4): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 1, 5): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 1, 6): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 6),
          ]
        },
        {
          DateTime(2024, 1, 7): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 70),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      'thank you',
      'Gratitude',
      [
        {
          DateTime(2024, 1, 1): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 1, 2): [
            LocationFrequency(Location.School, 5),
            LocationFrequency(Location.Clinic, 3),
          ]
        },
        {
          DateTime(2024, 1, 3): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 6),
          ]
        },
        {
          DateTime(2024, 1, 4): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 1, 5): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 1, 6): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 2),
          ]
        },
        {
          DateTime(2024, 1, 7): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 5),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      "you're welcome",
      'Gratitude',
      [
        {
          DateTime(2024, 2, 1): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 2, 2): [
            LocationFrequency(Location.School, 5),
            LocationFrequency(Location.Clinic, 3),
          ]
        },
        {
          DateTime(2024, 2, 3): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 6),
          ]
        },
        {
          DateTime(2024, 2, 4): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 2, 5): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 2, 6): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 2),
          ]
        },
        {
          DateTime(2024, 2, 7): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 5),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      "apple",
      'Food',
      [
        {
          DateTime(2024, 2, 1): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 2, 2): [
            LocationFrequency(Location.School, 5),
            LocationFrequency(Location.Clinic, 3),
          ]
        },
        {
          DateTime(2024, 2, 3): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 6),
          ]
        },
        {
          DateTime(2024, 2, 4): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 2, 5): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 2, 6): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 2),
          ]
        },
        {
          DateTime(2024, 2, 7): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 5),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      "banana",
      'Food',
      [
        {
          DateTime(2024, 2, 1): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 2, 2): [
            LocationFrequency(Location.School, 5),
            LocationFrequency(Location.Clinic, 3),
          ]
        },
        {
          DateTime(2024, 2, 3): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 6),
          ]
        },
        {
          DateTime(2024, 2, 4): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 2, 5): [
            LocationFrequency(Location.Home, 4),
            LocationFrequency(Location.School, 3),
          ]
        },
        {
          DateTime(2024, 2, 6): [
            LocationFrequency(Location.Home, 5),
            LocationFrequency(Location.School, 2),
          ]
        },
        {
          DateTime(2024, 2, 7): [
            LocationFrequency(Location.Home, 3),
            LocationFrequency(Location.School, 5),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      "orange",
      'Food',
      [
        {
          DateTime(2024, 2, 1): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 4),
          ]
        },
        {
          DateTime(2024, 3, 1): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 2),
          ]
        },
        // Add more data as needed...
      ],
    ),
    // Add more word usages as needed...
    WordUsage(
      "grapes",
      'Food',
      [
        {
          DateTime(2024, 3, 1): [
            LocationFrequency(Location.Home, 2),
            LocationFrequency(Location.School, 1),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      "orange",
      'Food',
      [
        {
          DateTime(2024, 3, 1): [
            LocationFrequency(Location.Home, 2),
          ]
        },
        // Add more data as needed...
      ],
    ),
    WordUsage(
      "cucumber",
      'Food',
      [
        {
          DateTime(2024, 3, 1): [
            LocationFrequency(Location.Home, 2),
          ]
        },
        // Add more data as needed...
      ],
    ),
  ];

  return wordUsages;
}
