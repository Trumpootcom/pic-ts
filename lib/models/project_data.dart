class ProjectData {
  final String templateFolderPath;
  final Map<String, dynamic> documentData;
  final List<Map<String, dynamic>> details;

  const ProjectData({
    required this.templateFolderPath,
    required this.documentData,
    required this.details,
  });
}