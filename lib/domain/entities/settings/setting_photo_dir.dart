import 'dart:convert';

class SettingPhotoDirs {
  final List<SettingPhotoDir> dirs;

  SettingPhotoDirs({required this.dirs});

  factory SettingPhotoDirs.fromRawJson(String str) =>
      SettingPhotoDirs.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SettingPhotoDirs.fromJson(Map<String, dynamic> json) =>
      SettingPhotoDirs(
        dirs: List<SettingPhotoDir>.from(
            json["dirs"].map((dir) => SettingPhotoDir.fromJson(dir))),
      );

  Map<String, dynamic> toJson() => {
        "dirs": List<dynamic>.from(dirs.map((dir) => dir.toJson())),
      };
}

class SettingPhotoDir {
  final String title;
  final String dirPath;
  bool isSelected;

  SettingPhotoDir({
    required this.title,
    required this.dirPath,
    required this.isSelected,
  });

  factory SettingPhotoDir.fromRawJson(String str) =>
      SettingPhotoDir.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SettingPhotoDir.fromJson(Map<String, dynamic> json) =>
      SettingPhotoDir(
        title: json["title"],
        dirPath: json["dirPath"],
        isSelected: json["isSelected"],
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "dirPath": dirPath,
        "isSelected": isSelected,
      };
}
