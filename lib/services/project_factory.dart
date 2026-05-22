import '../models/project_data.dart';
import 'template_loader.dart';

class ProjectFactory {
  ProjectData createBlankProject(LoadedTemplate loadedTemplate) {
    final templateJson = loadedTemplate.template.rawJson;

    final documentFields =
        (templateJson['data']?['document'] as List<dynamic>? ?? []);

    final documentData = <String, dynamic>{};

    for (final field in documentFields) {
      final fieldMap = field as Map<String, dynamic>;
      final key = fieldMap['key'] as String;
      documentData[key] = '';
    }

    return ProjectData(
      templateFolderPath: loadedTemplate.folderPath,
      documentData: documentData,
      details: [],
    );
  }
}