import 'dart:convert';
import 'dart:io';

import '../../services/project_storage.dart';
import '../models/history_command.dart';

class HistoryStorage {
  final StoredProject project;

  const HistoryStorage({required this.project});

  File get _dataJsonFile => File(project.dataJsonPath);
  File get _historyStorage => File(project.historyTxtPath);

  Future<List<HistoryCommand>> loadCommands() async {
    if (!await _historyStorage.exists()) {
      await _historyStorage.parent.create(recursive: true);
      await _historyStorage.writeAsString('');
      return [];
    }

    final lines = await _historyStorage.readAsLines();
    final commands = <HistoryCommand>[];

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        continue;
      }

      final jsonMap = jsonDecode(trimmed) as Map<String, dynamic>;
      commands.add(HistoryCommand.fromJson(jsonMap));
    }

    return commands;
  }

  Future<void> saveCommands(List<HistoryCommand> commands) async {
    await _historyStorage.parent.create(recursive: true);

    final text = commands
        .map((command) => jsonEncode(command.toJson()))
        .join('\n');

    await _historyStorage.writeAsString(
      text.isEmpty ? '' : '$text\n',
      flush: true,
    );
  }

  Future<void> appendCommand(HistoryCommand command) async {
    await _historyStorage.parent.create(recursive: true);

    await _historyStorage.writeAsString(
      '${jsonEncode(command.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<int> loadPointer() async {
    final data = await _loadDataJson();

    final pointer = data['historyPointer'];

    if (pointer is int) {
      return pointer;
    }

    if (pointer is num) {
      return pointer.toInt();
    }

    return 0;
  }

  Future<void> savePointer(int pointer) async {
    final data = await _loadDataJson();

    data['historyPointer'] = pointer;
    data['modifiedAt'] = DateTime.now().toIso8601String();

    await _saveDataJson(data);
  }

  Future<void> trimRedoHistory(int historyPointer) async {
    final commands = await loadCommands();

    if (historyPointer >= commands.length) {
      return;
    }

    final keptCommands = commands.take(historyPointer).toList();
    await saveCommands(keptCommands);
  }

  Future<Map<String, dynamic>> _loadDataJson() async {
    final text = await _dataJsonFile.readAsString();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Future<void> _saveDataJson(Map<String, dynamic> data) async {
    await _dataJsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
  }
}