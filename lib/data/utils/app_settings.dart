import 'dart:convert';
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:geocoding/geocoding.dart' as Geocoding;
import 'package:gps_camera/data/exceptions/api_exception.dart';
import 'package:gps_camera/data/utils/constants.dart';
import 'package:gps_camera/domain/entities/settings/setting_filename.dart';
import 'package:gps_camera/domain/entities/settings/setting_filename_body.dart';
import 'package:gps_camera/domain/entities/settings/setting_filename_list.dart';
import 'package:gps_camera/domain/entities/settings/setting_photo_dir.dart';
import 'package:intl/intl.dart';
import 'package:localization/localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static Future<void> _createDefaultDir() async {
    String dir;

    if (Platform.isIOS) {
      dir = (await getApplicationDocumentsDirectory()).path;
    } else {
      dir = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DCIM);
    }

    dir = '$dir/Kamera GPS Lokasi/';

    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
  }

  static Future<bool> setDefaultDir({SettingPhotoDirs? newDirs}) async {
    bool success = false;

    _createDefaultDir();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(Constants.savePhotoPath);

      // Cek setting yang ada
      if (jsonString != null) {
        if (newDirs != null) {
          success = await prefs.setString(
              Constants.savePhotoPath, newDirs.toRawJson());
        } else {
          success = true;
        }
      } else {
        // Jika belum ada settingan
        String dir;

        if (Platform.isIOS) {
          dir = (await getApplicationDocumentsDirectory()).path;
        } else {
          dir = await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DCIM);
        }

        dir = '$dir/Kamera GPS Lokasi/';

        /**
         * Create dirs untuk simpan foto
         */
        List<SettingPhotoDir> newDirs = [
          SettingPhotoDir(
            title: "Default",
            dirPath: dir,
            isSelected: true,
          ),
          SettingPhotoDir(
            title: "Site 1",
            dirPath: '${dir}Site 1',
            isSelected: false,
          ),
          SettingPhotoDir(
            title: "Site 2",
            dirPath: '${dir}Site 2',
            isSelected: false,
          ),
        ];
        SettingPhotoDirs dirs = SettingPhotoDirs(dirs: newDirs);

        success =
            await prefs.setString(Constants.savePhotoPath, dirs.toRawJson());
      }
    } catch (e) {
      print('==> setDefaultDir failed: ${e.toString()}');
    }

    return success;
  }

  static Future<SettingPhotoDirs> getDefaultDir() async {
    SettingPhotoDirs dirs;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(Constants.savePhotoPath);
      if (jsonString != null) {
        dirs = SettingPhotoDirs.fromRawJson(jsonString);
      } else {
        dirs = SettingPhotoDirs(dirs: []);
      }
    } catch (e) {
      print('==> getDefaultDir failed: ${e.toString()}');
      rethrow;
    }

    return dirs;
  }

  static Future<String> getDefaultAppDir() async {
    String dir;

    try {
      if (Platform.isIOS) {
        dir = (await getApplicationDocumentsDirectory()).path;
      } else {
        dir = (await getExternalStorageDirectory())?.path ?? '-';
      }
    } catch (e) {
      print('==> getApplicationDir failed: ${e.toString()}');
      rethrow;
    }

    return dir;
  }

  static Future<bool> setDefaultFilename(
      {SettingFilename? setting, required DateTime dateTime}) async {
    SettingFilename defaultSetting =
        SettingFilename(list: <SettingFilenameList>[
      SettingFilenameList(
        key: "dnt",
        header: "dt-text".i18n(),
        isSelected: true,
        body: <SettingFilenameBody>[
          SettingFilenameBody(
            key: "dt",
            title: "dt-text".i18n(),
            body: DateFormat("yyyyMMdd").format(dateTime),
            isSelected: true,
          ),
          SettingFilenameBody(
            key: "hms",
            title: "hms-text".i18n(),
            body: DateFormat("hhmsa")
                .format(dateTime)
                .replaceAll(':', '')
                .replaceAll(' ', ''),
            isSelected: true,
          ),
          SettingFilenameBody(
            key: "day",
            title: "day-text".i18n(),
            body: DateFormat("EEEE").format(dateTime),
            isSelected: false,
          ),
          SettingFilenameBody(
            key: "h",
            title: "24-hour-text".i18n(),
            body: DateFormat("Hms")
                .format(dateTime)
                .replaceAll(':', '')
                .replaceAll(' ', ''),
            isSelected: false,
          ),
        ],
        isPremium: false,
      ),
      SettingFilenameList(
        key: "sn",
        header: "sequence-number-text".i18n(),
        isSelected: false,
        body: "1",
        isPremium: false,
      ),
      SettingFilenameList(
        key: "cn1",
        header: "custom-name-text".i18n(["1"]),
        isSelected: true,
        body: "captured-by-text".i18n(),
        isPremium: true,
      ),
    ]);

    try {
      /**
       * Cek setting yang ada
       */
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(Constants.saveFileName);

      /**
       * Jika setting sudah ada
       */
      if (jsonString != null) {
        /**
         * Jika mau overwrite setting yg sudah ada
         */
        return prefs
            .setString(Constants.saveFileName,
                setting?.toRawJson() ?? defaultSetting.toRawJson())
            .then((value) => true)
            .onError((error, stackTrace) => false);
      } else {
        /**
         * Jika setting belum ada
         * simpan settingan yang diberikan user
         * atau gunakan settingan default
         */
        if (setting != null) {
          prefs
              .setString(Constants.saveFileName, setting.toRawJson())
              .then((value) => true)
              .onError((error, stackTrace) => false);
        } else {
          prefs
              .setString(Constants.saveFileName, defaultSetting.toRawJson())
              .then((value) {
            return true;
          }).onError((error, stackTrace) {
            return false;
          });
        }
      }
    } catch (e) {
      print('==> error: ${e.toString()}');
      return false;
    }

    return false;
  }

  static Future<dynamic> getDefaultFilename({required Type exportAs}) async {
    SettingFilename? setting;
    List<String> placeholder = [];

    setDefaultFilename(dateTime: DateTime.now());

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(Constants.saveFileName);
      if (jsonString != null) {
        setting = SettingFilename.fromRawJson(jsonString);

        placeholder = [];
        for (final data in setting.list) {
          if (data.isSelected) {
            if (data.body is String) {
              if (data.isSelected) {
                placeholder.add(data.body!);
              }
            } else if (data.body is List<SettingFilenameBody>) {
              for (final item in data.body) {
                if (item.isSelected) {
                  if (item.key == "h") {
                    placeholder[1] = item.body;
                  } else {
                    placeholder.add(item.body);
                  }
                }
              }
            }
          }
        }

        if (exportAs == String) {
          return '${placeholder.join('_')}.jpg';
        } else if (exportAs == SettingFilename) {
          return setting;
        } else {
          throw APIException('Error', 400, 'Status tidak dikenal');
        }
      }
    } catch (e) {
      print('==> getDefaultFileNameSetting: $e');
      rethrow;
    }

    return '-';
  }

  static Future<bool> setSaveOriPhoto(bool value) async {
    bool success = false;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      success = await prefs.setBool(Constants.saveOriPhotos, value);

      return success;
    } catch (e) {
      print('==> setDefaultDir failed: ${e.toString()}');
    }

    return success;
  }

  static Future<bool> getSaveOriPhoto() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(Constants.saveOriPhotos) ?? false;
    } catch (e) {
      print('==> getSaveOriPhoto failed: ${e.toString()}');
      rethrow;
    }
  }

  static Future<void> setLastLocation(
      List<Geocoding.Placemark> placemarks) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          Constants.saveLastLocation, placemarks.toList().toString());
    } catch (e) {
      print('==> setLastLocation failed: ${e.toString()}');
    }
  }

  static Future<List<Geocoding.Placemark>> getLastLocation() async {
    List<Geocoding.Placemark> placemarks = [];

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonString = await prefs.getString(Constants.saveLastLocation);
      if (jsonString != null) {
        placemarks = json.decode(jsonString) as List<Geocoding.Placemark>;
      }
    } catch (e) {
      print('==> getLastLocation failed: ${e.toString()}');
    }

    return placemarks;
  }
}
