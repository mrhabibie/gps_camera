import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gps_camera/app/page/main/view.dart';
import 'package:gps_camera/app/page/pages.dart';
import 'package:gps_camera/app/utils/bps_color.dart';
import 'package:gps_camera/app/utils/constants.dart';
import 'package:gps_camera/app/widgets/rounded_button_widget.dart';
import 'package:gps_camera/data/utils/app_settings.dart';
import 'package:gps_camera/data/utils/constants.dart';
import 'package:gps_camera/data/utils/flavor_settings.dart';
import 'package:gps_camera/data/utils/lifecycle_handler.dart';
import 'package:localization/localization.dart';
import 'package:location/location.dart' as gps;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionPageArguments {
  final String appVersion;

  PermissionPageArguments(this.appVersion);
}

class PermissionPage extends StatefulWidget {
  const PermissionPage({Key? key, required this.appVersion}) : super(key: key);

  final String appVersion;

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool _cameraAccess = false;
  bool _micAccess = false;
  bool _locationAccess = false;
  bool _galleryAccess = false;
  FlavorSettings? _flavorSettings;
  DateTime? currentBackPressTime;

  Future<void> _getCameraPermission() async {
    var status = await Permission.camera.status;
    setState(() {
      _cameraAccess = status.isGranted;
    });
  }

  Future<void> _getMicrophonePermission() async {
    var status = await Permission.microphone.status;
    setState(() {
      _micAccess = status.isGranted;
    });
  }

  Future<void> _getLocationPermission() async {
    var status = await Permission.location.status;
    setState(() {
      _locationAccess = status.isGranted;
    });
  }

  Future<void> _getGalleryPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        var status = await Permission.storage.status;
        setState(() {
          _galleryAccess = status.isGranted;
        });
      } else {
        var status = await Permission.photos.status;
        setState(() {
          _galleryAccess = status.isGranted;
        });
      }
    }
  }

  Future<bool> _requestCameraPermission() async {
    Map<Permission, PermissionStatus> result =
        await [Permission.camera].request();
    return result[Permission.camera] == PermissionStatus.granted;
  }

  Future<bool> _requestMicPermission() async {
    Map<Permission, PermissionStatus> result =
        await [Permission.microphone].request();
    return result[Permission.microphone] == PermissionStatus.granted;
  }

  Future<bool> _requestGPSService() async {
    gps.Location location = gps.Location();
    bool isEnabled = await location.serviceEnabled();
    if (!isEnabled) {
      isEnabled = (await location.requestService());
    }

    return isEnabled;
  }

  Future<bool> _requestLocationPermission() async {
    Map<Permission, PermissionStatus> result =
        await [Permission.location].request();

    return result[Permission.location] == PermissionStatus.granted;
  }

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        Map<Permission, PermissionStatus> result =
            await [Permission.storage].request();
        return result[Permission.storage] == PermissionStatus.granted;
      } else {
        Map<Permission, PermissionStatus> result =
            await [Permission.photos].request();

        return result[Permission.photos] == PermissionStatus.granted;
      }
    }

    return false;
  }

  Future<void> _getFlavorSettings() async {
    _flavorSettings = await getFlavorSettings();
  }

  Future<void> _setDefaultDir() async {
    try {
      String defaultDir;

      if (Platform.isIOS) {
        defaultDir = (await getApplicationDocumentsDirectory()).path;
      } else {
        defaultDir = await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DCIM);
      }

      defaultDir = '$defaultDir/BPS_Camera/';

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(Constants.savePhotoPath, defaultDir);
      prefs.setBool(Constants.saveOriPhotos, true);
    } catch (e) {
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: 'set-photo-dir-failed-text'.i18n());
    }
  }

  void _getAllPermissions() {
    _getFlavorSettings().then((_) {
      AppSettings.setDefaultDir().then((bool isSuccess) {
        if (isSuccess) {
          _getCameraPermission().then((_) {
            _getMicrophonePermission().then((_) {
              _requestGPSService().then((bool isEnabled) {
                if (isEnabled) {
                  _getLocationPermission().then((_) {
                    _getGalleryPermission().onError((error, stackTrace) {
                      Fluttertoast.cancel();
                      Fluttertoast.showToast(msg: error.toString());
                    });
                  }).onError((error, stackTrace) {
                    Fluttertoast.cancel();
                    Fluttertoast.showToast(msg: error.toString());
                  });
                }
              }).onError((error, stackTrace) {
                Fluttertoast.cancel();
                Fluttertoast.showToast(msg: error.toString());
              });
            }).onError((error, stackTrace) {
              Fluttertoast.cancel();
              Fluttertoast.showToast(msg: error.toString());
            });
          }).onError((error, stackTrace) {
            Fluttertoast.cancel();
            Fluttertoast.showToast(msg: error.toString());
          });
        } else {
          Fluttertoast.cancel();
          Fluttertoast.showToast(msg: 'set-photo-dir-failed-text'.i18n());
        }
      }).onError((error, stackTrace) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(msg: error.toString());
      });
    }).onError((error, stackTrace) {
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: error.toString());
    });
  }

  @override
  void initState() {
    _getAllPermissions();

    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        resumeCallback: () async {
          _getAllPermissions();
        },
        suspendingCallback: () async {
          _getAllPermissions();
        },
      ),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.only(right: 20),
                        child: TextButton(
                          onPressed: () {
                            changeLanguage(
                                context,
                                getCurrentLang(context) == const Locale('id')
                                    ? const Locale('en')
                                    : const Locale('id'));
                          },
                          child: Text(
                            'current-lang-text'.i18n([
                              getCurrentLang(context).toString().toUpperCase()
                            ]),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.key,
                    size: 200,
                    color: Colors.yellow[700],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'need-access-text'.i18n(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow[700],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'need-access-desc-text'.i18n(),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(left: 20, top: 20, right: 20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Icon(
                        Icons.camera_alt,
                        size: 32,
                        color: Colors.yellow[700],
                      ),
                      title: Text(
                        'camera-access-text'.i18n(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BPSColor.text,
                        ),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 5),
                        child: Text(
                          'camera-access-desc-text'.i18n(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      trailing: Switch(
                        value: _cameraAccess,
                        activeColor: Colors.yellow[700],
                        onChanged: (_) {
                          if (!_cameraAccess) {
                            _requestCameraPermission().then((cameraStatus) {
                              setState(() {
                                _cameraAccess = cameraStatus;
                              });
                            }).onError((error, stackTrace) {
                              Fluttertoast.cancel();
                              Fluttertoast.showToast(msg: error.toString());
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(left: 20, top: 20, right: 20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Icon(
                        Icons.mic,
                        size: 32,
                        color: Colors.yellow[700],
                      ),
                      title: Text(
                        'mic-access-text'.i18n(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BPSColor.text,
                        ),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 5),
                        child: Text(
                          'mic-access-desc-text'.i18n(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      trailing: Switch(
                        value: _micAccess,
                        activeColor: Colors.yellow[700],
                        onChanged: (_) {
                          if (!_micAccess) {
                            _requestMicPermission().then((value) {
                              setState(() {
                                _micAccess = value;
                              });
                            }).onError((error, stackTrace) {
                              Fluttertoast.cancel();
                              Fluttertoast.showToast(msg: error.toString());
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(left: 20, top: 20, right: 20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Icon(
                        Icons.pin_drop,
                        size: 32,
                        color: Colors.yellow[700],
                      ),
                      title: Text(
                        'location-access-text'.i18n(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BPSColor.text,
                        ),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 5),
                        child: Text(
                          'location-access-desc-text'.i18n(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      trailing: Switch(
                        value: _locationAccess,
                        activeColor: Colors.yellow[700],
                        onChanged: (_) {
                          if (!_locationAccess) {
                            _requestLocationPermission().then((value) {
                              setState(() {
                                _locationAccess = value;
                              });
                            }).onError((error, stackTrace) {
                              Fluttertoast.cancel();
                              Fluttertoast.showToast(msg: error.toString());
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.all(20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Icon(
                        Icons.photo_library,
                        size: 32,
                        color: Colors.yellow[700],
                      ),
                      title: Text(
                        'photo-lib-access-text'.i18n(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BPSColor.text,
                        ),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 5),
                        child: Text(
                          'photo-lib-access-desc-text'.i18n(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      trailing: Switch(
                        value: _galleryAccess,
                        activeColor: Colors.yellow[700],
                        onChanged: (_) {
                          if (!_galleryAccess) {
                            _requestGalleryPermission().then((value) {
                              setState(() {
                                _galleryAccess = value;
                              });
                            }).onError((error, stackTrace) {
                              Fluttertoast.cancel();
                              Fluttertoast.showToast(msg: error.toString());
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: RoundedButtonWidget(
                      paddingTop: 10,
                      label: 'next-text'.i18n(),
                      textColor: BPSColor.text,
                      backgroundColor: Colors.yellow[700],
                      borderRadius: 5,
                      onPressed: () {
                        if (_cameraAccess &&
                            _micAccess &&
                            _locationAccess &&
                            _galleryAccess) {
                          Navigator.of(context).pushReplacementNamed(
                            Pages.main,
                            arguments: MainCameraPageArguments(
                              _flavorSettings?.appName ?? '-',
                              widget.appVersion,
                            ),
                          );
                        } else {
                          showAlert(
                            context,
                            'permission-needed-text'.i18n([
                              !_cameraAccess
                                  ? 'camera-access-desc-text'.i18n()
                                  : !_micAccess
                                      ? 'mic-access-text'.i18n()
                                      : !_locationAccess
                                          ? 'location-access-desc-text'.i18n()
                                          : !_galleryAccess
                                              ? 'photo-lib-access-desc-text'
                                                  .i18n()
                                              : 'need-access-text'.i18n()
                            ]),
                            title: 'need-access-text'.i18n(),
                            closeBackLabel: 'open-settings-text'.i18n(),
                            isError: true,
                            onPressed: () async {
                              await openAppSettings().then((value) {
                                Navigator.of(context).pop();

                                return Future.value(value);
                              });
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> onWillPop() async {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: 'Tekan sekali lagi untuk keluar');

      return Future.value(false);
    }

    return Future.value(true);
  }
}
