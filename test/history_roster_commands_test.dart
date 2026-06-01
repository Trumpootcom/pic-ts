import 'package:flutter_test/flutter_test.dart';
import 'package:pic_ts/models/history_delete_roster.dart';
import 'package:pic_ts/models/history_insert_roster.dart';
import 'package:pic_ts/models/history_set_roster.dart';

void main() {
  test('insert roster command applies and undoes a row insert', () {
    final projectData = {
      'roster': <Map<String, dynamic>>[
        {
          'fullName': 'Existing Student',
          'profilePicture': 'assets/resources/portrait.png',
        },
      ],
    };

    final command = HistoryInsertRoster(
      index: 0,
      displayNumber: 2,
      row: {
        'fullName': 'First Last',
        'profilePicture': 'assets/resources/portrait.png',
      },
    );

    command.apply(projectData);

    expect(projectData['roster'], hasLength(2));
    expect((projectData['roster'] as List).first['fullName'], 'First Last');

    command.undo(projectData);

    expect(projectData['roster'], hasLength(1));
    expect((projectData['roster'] as List).first['fullName'], 'Existing Student');
  });

  test('delete roster command applies and undoes a row delete', () {
    final projectData = {
      'roster': <Map<String, dynamic>>[
        {
          'fullName': 'Jane Smith',
          'profilePicture': 'data/photos/jane.jpg',
        },
        {
          'fullName': 'John Smith',
          'profilePicture': 'data/photos/john.jpg',
        },
      ],
    };

    final command = HistoryDeleteRoster(
      index: 0,
      row: {
        'fullName': 'Jane Smith',
        'profilePicture': 'data/photos/jane.jpg',
      },
    );

    command.apply(projectData);

    expect(projectData['roster'], hasLength(1));
    expect((projectData['roster'] as List).first['fullName'], 'John Smith');

    command.undo(projectData);

    expect(projectData['roster'], hasLength(2));
    expect((projectData['roster'] as List).first['fullName'], 'Jane Smith');
  });

  test('set roster photo applies and undoes path changes', () {
    final projectData = {
      'roster': <Map<String, dynamic>>[
        {
          'fullName': 'Jane Smith',
          'profilePicture': 'assets/resources/portrait.png',
        },
      ],
    };

    final command = HistorySetRoster(
      index: 0,
      key: 'profilePicture',
      oldValue: 'assets/resources/portrait.png',
      newValue: 'data/photos/jane-cropped.jpg',
    );

    command.apply(projectData);

    expect(
      (projectData['roster'] as List).first['profilePicture'],
      'data/photos/jane-cropped.jpg',
    );

    command.undo(projectData);

    expect(
      (projectData['roster'] as List).first['profilePicture'],
      'assets/resources/portrait.png',
    );
  });

  test('insert roster command serializes display number', () {
    final command = HistoryInsertRoster(
      index: 0,
      displayNumber: 11,
      row: {
        'fullName': 'First Last',
        'profilePicture': 'assets/resources/portrait.png',
      },
    );

    final json = command.toJson();

    expect(json['cmd'], 'insert_roster');
    expect(json['index'], 0);
    expect(json['displayNumber'], 11);
    expect(json['row'], isA<Map<String, dynamic>>());

    final restored = HistoryInsertRoster.fromJson(json);

    expect(restored.index, 0);
    expect(restored.displayNumber, 11);
    expect(restored.shortDescription(documentSchema: [], rosterSchema: []), 'Add Roster 11');
  });
}