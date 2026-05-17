import 'package:flutter/foundation.dart';

class MusicianSignUpProvider extends ChangeNotifier {
  String email = '';
  String password = '';
  
  // Profile Data
  String fullName = '';
  String bio = '';
  List<String> genres = [];
  List<String> instruments = [];
  int feeRange = 1000;
  int yearsOfExperience = 0;
  String location = '';
  String website = '';
  Map<String, dynamic> portfolio = {
    'images': [],
    'videos': [],
    'audioTracks': [],
  };

  void updateCredentials(String email, String password) {
    this.email = email;
    this.password = password;
    notifyListeners();
  }

  void updateProfile(Map<String, dynamic> data) {
    fullName = data['fullName'] ?? fullName;
    bio = data['bio'] ?? bio;
    genres = List<String>.from(data['genres'] ?? genres);
    instruments = List<String>.from(data['instruments'] ?? instruments);
    feeRange = data['feeRange'] ?? feeRange;
    yearsOfExperience = data['yearsOfExperience'] ?? yearsOfExperience;
    location = data['location'] ?? location;
    website = data['website'] ?? website;
    portfolio = Map<String, dynamic>.from(data['portfolio'] ?? portfolio);
    notifyListeners();
  }
}
