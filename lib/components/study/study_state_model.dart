import 'package:flutter/material.dart';

class StudyStateModel extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  String _scrollSessionId = '';
  String get scrollSessionId => _scrollSessionId;

  void setIndex(int index) {
    _index = index;
    notifyListeners();
  }

  void setScrollSessionId(String sessionId) {
    _scrollSessionId = sessionId;
    notifyListeners();
  }
}
