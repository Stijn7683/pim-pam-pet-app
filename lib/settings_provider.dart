import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool soundEnabled = true;
  bool sortScores = true;

  void setSettings(bool? sound, bool? sorting) {
    soundEnabled = sound ?? soundEnabled;
    sortScores = sorting ?? sortScores;
    notifyListeners();
  }
}