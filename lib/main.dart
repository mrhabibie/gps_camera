import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gps_camera/app/page/splash/view.dart';
import 'package:gps_camera/app/utils/bps_color.dart';
import 'package:gps_camera/app/utils/bps_router.dart';
import 'package:gps_camera/app/utils/constants.dart';
import 'package:gps_camera/data/exceptions/api_exception.dart';
import 'package:gps_camera/data/utils/flavor_settings.dart';
import 'package:localization/localization.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocalJsonLocalization.delegate.directories = ['assets/lang'];
  SharedPreferences prefs = await SharedPreferences.getInstance();
  tz.initializeTimeZones();

  final settings = await getFlavorSettings();

  runApp(MyApp(settings, prefs));
}

class MyApp extends StatefulWidget {
  MyApp(this.flavorSettings, this.prefs, {Key? key})
      : router = BpsRouter(),
        super(key: key) {
    _initLogger();
  }

  final FlavorSettings flavorSettings;
  final SharedPreferences prefs;
  final BpsRouter router;

  void _initLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      dynamic e = record.error;
      String m = e is APIException ? e.message : e.toString();
      print(
          '${record.loggerName}: ${record.level.name}: ${record.message} ${m != 'null' ? m : ''}');
    });
    Logger.root.info('Logger initialized.');
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale? _locale;
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  PackageInfo _deviceInfo = PackageInfo(
    appName: 'appName',
    packageName: 'packageName',
    version: 'version',
    buildNumber: 'buildNumber',
  );

  changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  Future<void> initPlatformState() async {
    var deviceData = <String, dynamic>{};

    try {
      if (kIsWeb) {
        deviceData = readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
      } else {
        if (Platform.isAndroid) {
          deviceData = readAndroidBuildData(await deviceInfoPlugin.androidInfo);
        } else if (Platform.isIOS) {
          deviceData = readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
        } else if (Platform.isLinux) {
          deviceData = readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo);
        } else if (Platform.isMacOS) {
          deviceData = readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo);
        } else if (Platform.isWindows) {
          deviceData =
              readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo);
        }
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };

      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: deviceData['Error']);
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });
  }

  Future<void> initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _deviceInfo = info;
    });
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.flavorSettings.appName,
      locale: _locale,
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        fontFamily: 'Lato',
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.yellow[700],
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: BPSColor.text,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: BPSColor.text,
          ),
          labelLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: BPSColor.text,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: BPSColor.text,
          ),
          labelSmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: BPSColor.textSecondary,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: BPSColor.text,
          ),
          bodySmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: BPSColor.text,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        LocalJsonLocalization.delegate,
        FallbackLocalizationsDelegate(),
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
      localeResolutionCallback: (locale, supportedLocales) {
        if (supportedLocales.contains(locale)) {
          return locale;
        }

        return const Locale('id');
      },
      onGenerateRoute: widget.router.getRoute,
      navigatorObservers: [widget.router.routeObserver],
      home: SplashScreenPage(
        appName: _deviceInfo.appName,
        appVersion: _deviceInfo.version,
      ),
    );
  }
}

class FallbackLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      const DefaultMaterialLocalizations();

  @override
  bool shouldReload(
          covariant LocalizationsDelegate<MaterialLocalizations> old) =>
      false;
}
