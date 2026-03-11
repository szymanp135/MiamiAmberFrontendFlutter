import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortingType {
  byNewest,
  byOldest,
  byMostRated,
  byLeastRated,
  random;

  static SortingType fromString(String s) => switch (s) {
        "byNewest" => byNewest,
        "byOldest" => byOldest,
        "byMostRated" => byMostRated,
        "byLeastRated" => byLeastRated,
        "random" => random,
        _ => byNewest
      };
}

String sortingTypeToString(SortingType arg) => arg.toString().split(".").last;

class SettingsProvider with ChangeNotifier {
  SortingType _sortingType = SortingType.byNewest;

  SortingType get sortingType => _sortingType;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('sortingType') ??
        sortingTypeToString(SortingType.byNewest);
    _sortingType = SortingType.fromString(type);
    notifyListeners();
  }

  Future<void> setSortOrder(SortingType sorting) async {
    _sortingType = sorting;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortingType', sortingTypeToString(sorting));
    notifyListeners();
  }
}
