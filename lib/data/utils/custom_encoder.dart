import 'dart:convert';

import 'package:gps_camera/domain/entities/settings/setting_filename.dart';

class CustomEncoder extends Converter<Object, Object> {
  @override
  Object convert(Object input) {
    if (input is List) {
      return input.map((e) => convert(e)).toList();
    } else if (input is Map) {
      return Map.fromEntries(input.entries
          .map((e) => MapEntry(e.key.toString(), convert(e.value))));
    } else if (input is SettingFilename) {
      return input.toJson();
    } else {
      return input;
    }
  }
}
