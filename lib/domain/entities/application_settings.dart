import 'dart:convert';

enum SettingKey { fileName }

class ApplicationSettings {
  final SettingKey key;
  Object content;

  ApplicationSettings({required this.key, required this.content});

  factory ApplicationSettings.fromRawJson(String str) =>
      ApplicationSettings.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApplicationSettings.fromJson(Map<String, dynamic> json) =>
      ApplicationSettings(
        key: json["key"],
        content: json["content"] as Object,
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "content": content.toString(),
      };
}
