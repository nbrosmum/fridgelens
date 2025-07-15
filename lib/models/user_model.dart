class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  String? phoneNumber;
  String? dateOfBirth;
  List<String> friends; // List of friend UIDs

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.dateOfBirth,
    this.friends = const [], // Default to empty list
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phoneNumber: map['phoneNumber'],
      dateOfBirth: map['dateOfBirth'],
      friends: List<String>.from(map['friends'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'friends': friends,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
