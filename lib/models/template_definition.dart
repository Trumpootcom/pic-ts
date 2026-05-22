class TemplateDefinition {
  final String id;
  final String name;
  final String productType;
  final String preview;
  final Map<String, dynamic> rawJson;

  const TemplateDefinition({
    required this.id,
    required this.name,
    required this.productType,
    required this.preview,
    required this.rawJson,
  });

  factory TemplateDefinition.fromJson(Map<String, dynamic> json) {
    return TemplateDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      productType: json['productType'] as String,
      preview: json['preview'] as String,
      rawJson: json,
    );
  }
}