// lib/features/auth/controllers/autosuggestion_controller.dart
import 'package:flutter/material.dart';

class AutosuggestionController extends TextEditingController {
  TextStyle _suggestionStyle;
  String _suggestion;

  set suggestionStyle(TextStyle style) {
    if (_suggestionStyle != style) {
      _suggestionStyle = style;
      notifyListeners();
    }
  }

  set suggestion(String s) {
    if (_suggestion != s) {
      _suggestion = s;
      notifyListeners();
    }
  }

  AutosuggestionController({
    super.text,
    required TextStyle initialSuggestionStyle,
    required String initialSuggestion,
  }) : _suggestionStyle = initialSuggestionStyle,
       _suggestion = initialSuggestion;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_suggestion.isEmpty || text.isEmpty || !text.contains('@')) {
      return TextSpan(text: text, style: style);
    }

    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(text: text),

        TextSpan(text: _suggestion, style: _suggestionStyle),
      ],
    );
  }
}
