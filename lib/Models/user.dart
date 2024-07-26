class User {
  final String userID;
  final String fullName;
  final int age;
  final String guardianName;
  final String guardianNo;
  final String email;
  final String password;
  final bool isAdmin;

  User({
    required this.userID,
    required this.fullName,
    required this.age,
    required this.guardianName,
    required this.guardianNo,
    required this.email,
    required this.password,
    required this.isAdmin,
  });

  // Factory method to create a User object from a map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userID: map['userID'],
      fullName: map['fullName'],
      age: map['age'],
      guardianName: map['guardianName'],
      guardianNo: map['guardianNo'],
      email: map['email'],
      password: map['password'],
      isAdmin: map['isAdmin'],
    );
  }

  // Method to convert a User object to a map
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'fullName': fullName,
      'age': age,
      'guardianName': guardianName,
      'guardianNo': guardianNo,
      'email': email,
      'password': password,
      'isAdmin': isAdmin,
    };
  }
}
