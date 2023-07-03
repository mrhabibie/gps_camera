import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gps_camera/domain/entities/settings/setting_filename_body.dart';

class SettingFilenameList {
  final String key;
  final String header;
  bool isSelected;
  final dynamic body;
  final TextEditingController? bodyController;
  final bool isPremium;

  SettingFilenameList({
    required this.key,
    required this.header,
    required this.isSelected,
    this.body,
    this.bodyController,
    required this.isPremium,
  });

  factory SettingFilenameList.fromRawJson(String str) =>
      SettingFilenameList.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SettingFilenameList.fromJson(Map<String, dynamic> json) =>
      SettingFilenameList(
        key: json["key"],
        header: json["header"],
        isSelected: json["isSelected"],
        body: json["body"] is String
            ? json["body"]
            : List<SettingFilenameBody>.from(
                json["body"].map((str) => SettingFilenameBody.fromJson(str))),
        bodyController: json["bodyController"],
        isPremium: json["isPremium"],
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "header": header,
        "isSelected": isSelected,
        "body": body is List<SettingFilenameBody>
            ? List<dynamic>.from(body.map((e) => e.toJson()))
            : body,
        "bodyController": bodyController,
        "isPremium": isPremium,
      };
}
