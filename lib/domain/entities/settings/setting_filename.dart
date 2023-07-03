import 'dart:convert';

import 'package:gps_camera/domain/entities/settings/setting_filename_list.dart';

class SettingFilename {
  List<SettingFilenameList> list;

  SettingFilename({required this.list});

  factory SettingFilename.fromRawJson(String str) =>
      SettingFilename.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SettingFilename.fromJson(Map<String, dynamic> json) =>
      SettingFilename(
        list: List<SettingFilenameList>.from(
            json["list"].map((str) => SettingFilenameList.fromJson(str))),
      );

  Map<String, dynamic> toJson() => {
        "list": List<dynamic>.from(list.map((e) => e.toJson())),
      };
}
