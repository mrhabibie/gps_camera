import 'dart:convert';

class SettingFilenameBody {
  final String key;
  final String title;
  final String body;
  bool isSelected;

  SettingFilenameBody({
    required this.key,
    required this.title,
    required this.body,
    required this.isSelected,
  });

  factory SettingFilenameBody.fromRawJson(String str) =>
      SettingFilenameBody.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SettingFilenameBody.fromJson(Map<String, dynamic> json) =>
      SettingFilenameBody(
        key: json["key"],
        title: json["title"],
        body: json["body"],
        isSelected: json["isSelected"],
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "title": title,
        "body": body,
        "isSelected": isSelected,
      };
}
