import 'history_command.dart';

class HistoryInsertRoster extends HistoryCommand {
  final int index;
  final int displayNumber;
  final Map<String, dynamic> row;
  static const commandName = 'insert_roster';

  HistoryInsertRoster({
    required this.index,
    required this.displayNumber,
    required this.row,
  });

  factory HistoryInsertRoster.fromJson(Map<String, dynamic> json) {
    return HistoryInsertRoster(
      index: json['index'] as int,
      displayNumber: json['displayNumber'] as int? ?? (json['index'] as int) + 1,
      row: Map<String, dynamic>.from(json['row'] as Map),
    );
  }

  @override
  String get cmd => commandName;

  @override
  void apply(Map<String, dynamic> projectData) {
    final roster = _rosterFromProject(projectData);
    final insertIndex = index.clamp(0, roster.length).toInt();

    roster.insert(insertIndex, historyTrimTrailingWhitespaceMap(row));
    projectData['roster'] = roster;
  }

  @override
  void undo(Map<String, dynamic> projectData) {
    final roster = _rosterFromProject(projectData);

    if (index < 0 || index >= roster.length) {
      return;
    }

    roster.removeAt(index);
    projectData['roster'] = roster;
  }

  @override
  String shortDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return 'Add $_rosterLabel';
  }

  @override
  String redoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return 'Add $_rosterLabel';
  }

  @override
  String undoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return 'Remove $_rosterLabel';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'cmd': cmd,
      'index': index,
      'displayNumber': displayNumber,
      'row': row,
    };
  }

  String get _rosterLabel => 'Roster $displayNumber';
}

List<Map<String, dynamic>> _rosterFromProject(Map<String, dynamic> projectData) {
  return List<Map<String, dynamic>>.from(
    (projectData['roster'] as List<dynamic>? ?? []).map(
      (e) => Map<String, dynamic>.from(e as Map),
    ),
  );
}
