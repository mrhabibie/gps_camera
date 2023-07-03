import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gps_camera/app/page/main/view.dart';
import 'package:gps_camera/app/page/pages.dart';
import 'package:gps_camera/app/page/permission/view.dart';
import 'package:gps_camera/data/utils/app_settings.dart';
import 'package:localization/localization.dart';
import 'package:location/location.dart' as gps;
import 'package:permission_handler/permission_handler.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({
    Key? key,
    required this.appName,
    required this.appVersion,
  }) : super(key: key);

  final String appName;
  final String appVersion;

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  bool _cameraAccess = false;
  bool _audioAccess = false;
  bool _locationAccess = false;
  bool _galleryAccess = false;

  Future<void> _getCameraPermission() async {
    var status = await Permission.camera.status;
    setState(() {
      _cameraAccess = status.isGranted;
    });
  }

  Future<void> _getMicrophonePermission() async {
    var status = await Permission.microphone.status;
    setState(() {
      _audioAccess = status.isGranted;
    });
  }

  Future<bool> _checkGPSService() async {
    gps.Location location = gps.Location();
    return (await location.serviceEnabled());
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

  @override
  void initState() {
    _getCameraPermission().then((_) {
      _getMicrophonePermission().then((_) {
        _getLocationPermission().then((_) {
          _checkGPSService().then((bool gpsResult) {
            _getGalleryPermission().then((_) {
              AppSettings.setDefaultDir().then((_) {
                if (!_cameraAccess ||
                    !_audioAccess ||
                    !gpsResult ||
                    !_locationAccess ||
                    !_galleryAccess) {
                  Navigator.of(context).pushReplacementNamed(
                    Pages.permission,
                    arguments: PermissionPageArguments(widget.appVersion),
                  );
                } else {
                  Navigator.of(context).pushReplacementNamed(
                    Pages.main,
                    arguments: MainCameraPageArguments(
                      widget.appName,
                      widget.appVersion,
                    ),
                  );
                }
              });
            });
          });
        });
      });
    });
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
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  widget.appName,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(
                    color: Colors.yellow[700],
                  ),
                ),
                Text(
                  '${'version-text'.i18n()} ${widget.appVersion}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
