import 'package:flutter/foundation.dart';

class MusicianSignUpProvider extends ChangeNotifier {
  String email = '';
  String password = '';
  
  // Profile Data
  String fullName = '';
  String bio = '';
  String primaryGenre = '';
  List<String> subgenres = [];
  List<String> genres = [];
  List<String> instruments = [];
  int hourlyRate = 50;
  int feeRange = 50;
  int yearsOfExperience = 0;
  String primaryCity = '';
  String primaryState = '';
  String primaryZip = '';
  String secondaryCity = '';
  String secondaryState = '';
  String secondaryZip = '';
  int travelRadius = 50;
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
    primaryGenre = data['primaryGenre'] ?? primaryGenre;
    subgenres = List<String>.from(data['subgenres'] ?? subgenres);
    genres = List<String>.from(data['genres'] ?? genres);
    instruments = List<String>.from(data['instruments'] ?? instruments);
    hourlyRate = data['hourlyRate'] ?? hourlyRate;
    feeRange = data['feeRange'] ?? feeRange;
    yearsOfExperience = data['yearsOfExperience'] ?? yearsOfExperience;
    primaryCity = data['primaryCity'] ?? primaryCity;
    primaryState = data['primaryState'] ?? primaryState;
    primaryZip = data['primaryZip'] ?? primaryZip;
    secondaryCity = data['secondaryCity'] ?? secondaryCity;
    secondaryState = data['secondaryState'] ?? secondaryState;
    secondaryZip = data['secondaryZip'] ?? secondaryZip;
    travelRadius = data['travelRadius'] ?? travelRadius;
    location = data['location'] ?? location;
    website = data['website'] ?? website;
    portfolio = Map<String, dynamic>.from(data['portfolio'] ?? portfolio);
    notifyListeners();
  }
}
