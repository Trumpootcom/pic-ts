import 'history_command.dart';

class HistorySetRoster extends HistoryCommand {
  final int index;
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  static const commandName = 'set_roster';

  HistorySetRoster({
    required this.index,
    required this.key,
    required this.oldValue,
    required this.newValue,
  });

  factory HistorySetRoster.fromJson(Map<String, dynamic> json) {
    return HistorySetRoster(
      index: json['index'] as int,
      key: json['key'] as String,
      oldValue: json['old'],
      newValue: json['new'],
    );
  }

  @override
  String get cmd => commandName;

  @override
  void apply(Map<String, dynamic> projectData) {
    final roster = List<Map<String, dynamic>>.from(
      (projectData['roster'] as List<dynamic>? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );

    roster[index][key] = newValue;
    projectData['roster'] = roster;
  }

  @override
  void undo(Map<String, dynamic> projectData) {
    final roster = List<Map<String, dynamic>>.from(
      (projectData['roster'] as List<dynamic>? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );

    roster[index][key] = oldValue;
    projectData['roster'] = roster;
  }

  @override
  String shortDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    final label = historyFieldLabel(schema: rosterSchema, key: key);

    if (key == 'fullName') {
      return 'Student ${index + 1} Name';
    }

    if (key == 'profilePicture') {
      return 'Student ${index + 1} Photo';
    }

    return 'Student ${index + 1} $label';
  }

  @override
  String redoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    final label = historyFieldLabel(schema: rosterSchema, key: key);

    return 'Change Roster ${index + 1} $label from ${historyValueText(oldValue)} to ${historyValueText(newValue)}';
  }

  @override
  String undoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    final label = historyFieldLabel(schema: rosterSchema, key: key);

    return 'Change Roster ${index + 1} $label from ${historyValueText(newValue)} to ${historyValueText(oldValue)}';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'cmd': cmd,
      'index': index,
      'key': key,
      'old': oldValue,
      'new': newValue,
    };
  }
}
