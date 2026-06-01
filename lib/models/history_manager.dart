import '../services/history_storage.dart';
import 'history_command.dart';
import 'history_set_document.dart';
import 'history_set_roster.dart';

class HistoryManager {
  final HistoryStorage storage;

  List<HistoryCommand> _commands = [];
  int _pointer = 0;

  HistoryManager({required this.storage});

  int get pointer => _pointer;
  int get commandCount => _commands.length;

  bool get canUndo => _pointer > 0;
  bool get canRedo => _pointer < _commands.length;

  Future<void> load() async {
    _commands = await storage.loadCommands();
    _pointer = await storage.loadPointer();

    if (_pointer < 0) {
      _pointer = 0;
    }

    if (_pointer > _commands.length) {
      _pointer = _commands.length;
      await storage.savePointer(_pointer);
    }
  }

  Future<void> setDocumentField({
    required Map<String, dynamic> projectData,
    required String key,
    required dynamic newValue,
  }) async {
    final documentData = Map<String, dynamic>.from(
      projectData['documentData'] as Map? ?? {},
    );

    final oldValue = documentData[key];

    if (oldValue == newValue) {
      return;
    }

    await execute(
      command: HistorySetDocument(
        key: key,
        oldValue: oldValue,
        newValue: newValue,
      ),
      projectData: projectData,
    );
  }

  Future<void> setRosterField({
    required Map<String, dynamic> projectData,
    required int index,
    required String key,
    required dynamic newValue,
  }) async {
    final roster = List<Map<String, dynamic>>.from(
      (projectData['roster'] as List<dynamic>? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );

    if (index < 0 || index >= roster.length) {
      return;
    }

    final oldValue = roster[index][key];

    if (oldValue == newValue) {
      return;
    }

    await execute(
      command: HistorySetRoster(
        index: index,
        key: key,
        oldValue: oldValue,
        newValue: newValue,
      ),
      projectData: projectData,
    );
  }

  Future<void> execute({
    required HistoryCommand command,
    required Map<String, dynamic> projectData,
  }) async {
    if (_pointer < _commands.length) {
      _commands = _commands.take(_pointer).toList();
      await storage.saveCommands(_commands);
    }

    command.apply(projectData);

    _commands.add(command);
    _pointer = _commands.length;

    await storage.appendCommand(command);
    await storage.savePointer(_pointer);
  }

  Future<void> undo(Map<String, dynamic> projectData) async {
    if (!canUndo) {
      return;
    }

    final command = _commands[_pointer - 1];

    command.undo(projectData);
    _pointer--;

    await storage.savePointer(_pointer);
  }

  Future<void> redo(Map<String, dynamic> projectData) async {
    if (!canRedo) {
      return;
    }

    final command = _commands[_pointer];

    command.apply(projectData);
    _pointer++;

    await storage.savePointer(_pointer);
  }

  String? undoShortDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return undoCommand?.shortDescription(
      documentSchema: documentSchema,
      rosterSchema: rosterSchema,
    );
  }

  String? redoShortDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return redoCommand?.shortDescription(
      documentSchema: documentSchema,
      rosterSchema: rosterSchema,
    );
  }

  HistoryCommand? get undoCommand {
    if (!canUndo) return null;
    return _commands[_pointer - 1];
  }

  HistoryCommand? get redoCommand {
    if (!canRedo) return null;
    return _commands[_pointer];
  }

  String? undoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return undoCommand?.undoDescription(
      documentSchema: documentSchema,
      rosterSchema: rosterSchema,
    );
  }

  String? redoDescription({
    required List<dynamic> documentSchema,
    required List<dynamic> rosterSchema,
  }) {
    return redoCommand?.redoDescription(
      documentSchema: documentSchema,
      rosterSchema: rosterSchema,
    );
  }
}
