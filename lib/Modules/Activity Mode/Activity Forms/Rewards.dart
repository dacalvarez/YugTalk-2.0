// Rewards.dart
class Reward {
  final String name;
  final String imagePath;

  Reward({required this.name, required this.imagePath});
}

final List<Reward> defaultRewards = [
  Reward(name: 'Board Games', imagePath: 'assets/images/board games.png'),
  Reward(name: 'Coloring Book', imagePath: 'assets/images/coloring book.png'),
  Reward(name: 'Craft', imagePath: 'assets/images/craft.png'),
  Reward(name: 'Dance', imagePath: 'assets/images/dance.png'),
  Reward(name: 'Puzzle', imagePath: 'assets/images/puzzle.png'),
  Reward(name: 'Snack', imagePath: 'assets/images/snack.png'),
  Reward(name: 'Toys', imagePath: 'assets/images/toys.png'),
];
