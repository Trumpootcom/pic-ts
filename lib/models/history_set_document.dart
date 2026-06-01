import 'history_command.dart';

class HistorySetDocument extends HistoryCommand {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  static const commandName = 'set_document';

  HistorySetDocument({
    required this.key,
    required this.oldValue,
    required this.newValue,
  });

  factory HistorySetDocument.fromJson(Map<String, dynamic> json) {
    return HistorySetDocument(
      key: json['key'] as String,
      oldValue: json['old'],
      newValue: json['new'],
    );
  }

  @override
  String get cmd => commandName;

  @override
  void apply(Map<String, dynamic> projectData) {
    final documentData = Map<String, dynamic>.from(
      projectData['documentData'] as Map? ?? {},
    );

    documentData[key] = newValue;
    projectData['documentData'] = documentData;
  }

  @override
  void undo(Map<String, dynamic> projectData) {
    final documentData = Map<String, dynamic>.from(
      projectData['documentData'] as Map? ?? {},
    );

    documentData[key] = oldValue;
    projectData['documentData'] = documentData;
  }

  @override
  String shortDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return historyFieldLabel(schema: documentSchema, key: key);
  }


  @override
  String redoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    final label = historyFieldLabel(schema: documentSchema, key: key);

    return 'Change $label from ${historyValueText(oldValue)} to ${historyValueText(newValue)}';
  }

  @override
  String undoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    final label = historyFieldLabel(schema: documentSchema, key: key);

    return 'Change $label from ${historyValueText(newValue)} to ${historyValueText(oldValue)}';
  }

  @override
  Map<String, dynamic> toJson() {
    return {'cmd': cmd, 'key': key, 'old': oldValue, 'new': newValue};
  }
}
