class ClassPhotoProject {
  final BackgroundSpec background;
  final LogoSpec logo;
  final TextSpec title;
  final TextSpec subtitle;
  final StudentPortraitArea studentPortraitArea;
  final Map<String, dynamic> studentLayouts;
  final List<StudentSpec> students;

  const ClassPhotoProject({
    required this.background,
    required this.logo,
    required this.title,
    required this.subtitle,
    required this.studentPortraitArea,
    required this.studentLayouts,
    required this.students,
  });

  factory ClassPhotoProject.fromJson(Map<String, dynamic> json) {
    return ClassPhotoProject(
      background: BackgroundSpec.fromJson(json['background']),
      logo: LogoSpec.fromJson(json['logo']),
      title: TextSpec.fromJson(json['title']),
      subtitle: TextSpec.fromJson(json['subtitle']),
      studentPortraitArea:
          StudentPortraitArea.fromJson(json['studentPortraitArea']),
      studentLayouts: Map<String, dynamic>.from(json['studentLayouts']),
      students: (json['students'] as List)
          .map((e) => StudentSpec.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "background": background.toJson(),
      "logo": logo.toJson(),
      "title": title.toJson(),
      "subtitle": subtitle.toJson(),
      "studentPortraitArea": studentPortraitArea.toJson(),
      "studentLayouts": studentLayouts,
      "students": students.map((e) => e.toJson()).toList(),
    };
  }

  ClassPhotoProject copyWith({
    TextSpec? title,
    TextSpec? subtitle,
    List<StudentSpec>? students,
  }) {
    return ClassPhotoProject(
      background: background,
      logo: logo,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      studentPortraitArea: studentPortraitArea,
      studentLayouts: studentLayouts,
      students: students ?? this.students,
    );
  }
}

class BackgroundSpec {
  final String filename;

  const BackgroundSpec({
    required this.filename,
  });

  factory BackgroundSpec.fromJson(Map<String, dynamic> json) {
    return BackgroundSpec(
      filename: json['filename'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "filename": filename,
    };
  }
}

class LogoSpec {
  final String filename;
  final double centerX;
  final double topY;
  final double? width;
  final double? height;

  const LogoSpec({
    required this.filename,
    required this.centerX,
    required this.topY,
    required this.width,
    required this.height,
  });

  factory LogoSpec.fromJson(Map<String, dynamic> json) {
    return LogoSpec(
      filename: json['filename'],
      centerX: (json['centerX'] as num).toDouble(),
      topY: (json['topY'] as num).toDouble(),
      width: json['width'] == null ? null : (json['width'] as num).toDouble(),
      height:
          json['height'] == null ? null : (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "filename": filename,
      "centerX": centerX,
      "topY": topY,
      "width": width,
      "height": height,
    };
  }
}

class TextSpec {
  final String text;
  final double centerX;
  final double topY;
  final double fontSize;

  const TextSpec({
    required this.text,
    required this.centerX,
    required this.topY,
    required this.fontSize,
  });

  factory TextSpec.fromJson(Map<String, dynamic> json) {
    return TextSpec(
      text: json['text'],
      centerX: (json['centerX'] as num).toDouble(),
      topY: (json['topY'] as num).toDouble(),
      fontSize: (json['fontSize'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "text": text,
      "centerX": centerX,
      "topY": topY,
      "fontSize": fontSize,
    };
  }

  TextSpec copyWith({
    String? text,
  }) {
    return TextSpec(
      text: text ?? this.text,
      centerX: centerX,
      topY: topY,
      fontSize: fontSize,
    );
  }
}

class StudentPortraitArea {
  final double centerX;
  final double topY;
  final int maxRows;
  final int maxStudents;
  final double? ovalWidth;
  final double? ovalHeight;
  final double horizontalGap;
  final double verticalGap;
  final double nameGap;
  final double fontSize;
  final String ovalFrame;

  const StudentPortraitArea({
    required this.centerX,
    required this.topY,
    required this.maxRows,
    required this.maxStudents,
    required this.ovalWidth,
    required this.ovalHeight,
    required this.horizontalGap,
    required this.verticalGap,
    required this.nameGap,
    required this.fontSize,
    required this.ovalFrame,
  });

  factory StudentPortraitArea.fromJson(Map<String, dynamic> json) {
    return StudentPortraitArea(
      centerX: (json['centerX'] as num).toDouble(),
      topY: (json['topY'] as num).toDouble(),
      maxRows: json['maxRows'],
      maxStudents: json['maxStudents'],
      ovalWidth: json['ovalWidth'] == null
          ? null
          : (json['ovalWidth'] as num).toDouble(),
      ovalHeight: json['ovalHeight'] == null
          ? null
          : (json['ovalHeight'] as num).toDouble(),
      horizontalGap: (json['horizontalGap'] as num).toDouble(),
      verticalGap: (json['verticalGap'] as num).toDouble(),
      nameGap: (json['nameGap'] as num).toDouble(),
      fontSize: (json['fontSize'] as num).toDouble(),
      ovalFrame: json['ovalFrame'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "centerX": centerX,
      "topY": topY,
      "maxRows": maxRows,
      "maxStudents": maxStudents,
      "ovalWidth": ovalWidth,
      "ovalHeight": ovalHeight,
      "horizontalGap": horizontalGap,
      "verticalGap": verticalGap,
      "nameGap": nameGap,
      "fontSize": fontSize,
      "ovalFrame": ovalFrame,
    };
  }
}

class StudentSpec {
  final String firstName;
  final String lastName;

  const StudentSpec({
    required this.firstName,
    required this.lastName,
  });

  factory StudentSpec.fromJson(Map<String, dynamic> json) {
    return StudentSpec(
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
    };
  }

  String get fullName => '$firstName $lastName';
}