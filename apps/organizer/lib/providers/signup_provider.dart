import 'package:flutter/foundation.dart';

class SignUpProvider extends ChangeNotifier {
  String name = '';
  String orgName = '';
  String email = '';
  String password = '';
  String type = '';
  String contact = '';
  String location = '';
  String bio = '';

  void updateStep1({
    required String name,
    required String orgName,
    required String email,
    required String password,
  }) {
    this.name = name;
    this.orgName = orgName;
    this.email = email;
    this.password = password;
    notifyListeners();
  }

  void updateStep2({required String type, required String contact, required String location}) {
    this.type = type;
    this.contact = contact;
    this.location = location;
    notifyListeners();
  }

  void updateStep3({required String bio}) {
    this.bio = bio;
    notifyListeners();
  }
}
