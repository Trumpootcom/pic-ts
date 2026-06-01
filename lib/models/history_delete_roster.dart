import 'history_command.dart';

class HistoryDeleteRoster extends HistoryCommand {
  final int index;
  final Map<String, dynamic> row;
  static const commandName = 'delete_roster';

  HistoryDeleteRoster({
    required this.index,
    required this.row,
  });

  factory HistoryDeleteRoster.fromJson(Map<String, dynamic> json) {
    return HistoryDeleteRoster(
      index: json['index'] as int,
      row: Map<String, dynamic>.from(json['row'] as Map),
    );
  }

  @override
  String get cmd => commandName;

  @override
  void apply(Map<String, dynamic> projectData) {
    final roster = _rosterFromProject(projectData);

    if (index < 0 || index >= roster.length) {
      return;
    }

    roster.removeAt(index);
    projectData['roster'] = roster;
  }

  @override
  void undo(Map<String, dynamic> projectData) {
    final roster = _rosterFromProject(projectData);
    final insertIndex = index.clamp(0, roster.length).toInt();

    roster.insert(insertIndex, Map<String, dynamic>.from(row));
    projectData['roster'] = roster;
  }

  @override
  String shortDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return 'Delete $_rosterLabel';
  }

  @override
  String redoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return 'Delete $_rosterLabel';
  }

  @override
  String undoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    final fullName = row['fullName']?.toString().trim() ?? '';

    if (fullName.isEmpty) {
      return 'Restore $_rosterLabel';
    }

    return 'Restore $_rosterLabel: $fullName';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'cmd': cmd,
      'index': index,
      'row': row,
    };
  }

  String get _rosterLabel => 'Roster ${index + 1}';
}

List<Map<String, dynamic>> _rosterFromProject(Map<String, dynamic> projectData) {
  return List<Map<String, dynamic>>.from(
    (projectData['roster'] as List<dynamic>? ?? []).map(
      (e) => Map<String, dynamic>.from(e as Map),
    ),
  );
}
