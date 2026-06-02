import 'history_delete_roster.dart';
import 'history_insert_roster.dart';
import 'history_set_document.dart';
import 'history_set_roster.dart';

abstract class HistoryCommand {
  String get cmd;

  void apply(Map<String, dynamic> projectData);
  void undo(Map<String, dynamic> projectData);

  String shortDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  });
  
  String undoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  });

  String redoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  });

  Map<String, dynamic> toJson();

  static HistoryCommand fromJson(Map<String, dynamic> json) {
    final cmd = json['cmd'] as String?;

    switch (cmd) {
      case HistorySetDocument.commandName:
        return HistorySetDocument.fromJson(json);

      case HistorySetRoster.commandName:
        return HistorySetRoster.fromJson(json);

      case HistoryInsertRoster.commandName:
        return HistoryInsertRoster.fromJson(json);

      case HistoryDeleteRoster.commandName:
        return HistoryDeleteRoster.fromJson(json);

      default:
        throw Exception('Unknown history command: $cmd');
    }
  }
}

String historyFieldLabel({required List<dynamic> schema, required String key}) {
  for (final field in schema) {
    if (field is! Map) continue;

    if (field['key'] == key) {
      return field['label']?.toString() ?? key;
    }
  }

  return key;
}

dynamic historyFieldDefault({
  required List<dynamic> schema,
  required String key,
}) {
  for (final field in schema) {
    if (field is! Map) continue;

    if (field['key'] == key) {
      return field['default'];
    }
  }

  return null;
}

String historyValueText(dynamic value) {
  if (value == null) return 'blank';
  final text = value.toString();
  if (text.isEmpty) return 'blank';
  return '"$text"';
}
