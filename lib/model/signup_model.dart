import 'dart:convert';

class SignupModel {
  final String uid;
  final String username;
  final String email;

  SignupModel({
    required this.uid,
    required this.username,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
    };
  }

  factory SignupModel.fromMap(Map<String, dynamic> map) {
    return SignupModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
