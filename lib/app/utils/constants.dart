import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gps_camera/data/utils/flavor_settings.dart';
import 'package:gps_camera/domain/entities/settings/setting_filename.dart';
import 'package:gps_camera/domain/entities/settings/setting_filename_body.dart';
import 'package:gps_camera/domain/entities/settings/setting_filename_list.dart';
import 'package:gps_camera/main.dart';
import 'package:intl/intl.dart' as intl;
import 'package:localization/localization.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<FlavorSettings> getFlavorSettings() async {
  String flavor =
      await const MethodChannel('flavor').invokeMethod<String>('getFlavor') ??
          'unknown';

  if (flavor == 'free') {
    return FlavorSettings.free();
  } else if (flavor == 'premium') {
    return FlavorSettings.premium();
  } else if (flavor == 'dev') {
    return FlavorSettings.dev();
  } else {
    throw Exception('Unknown flavor: $flavor');
  }
}

void confirmWidget(
  BuildContext context, {
  String? title,
  String? subTitle,
  String? cancelLabel,
  String? okLabel,
  void Function()? onPressed,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Wrap(
          children: <Widget>[
            Center(
              child: Text(
                title ?? 'confirm-title-text'.i18n(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  subTitle ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 30, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ButtonStyle(
                          fixedSize: MaterialStateProperty.all(
                            Size(MediaQuery.of(context).size.width, 40),
                          ),
                          backgroundColor:
                              MaterialStateProperty.all(Colors.yellow[700]),
                          elevation: MaterialStateProperty.all(0),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide.none,
                            ),
                          ),
                        ),
                        child: Text(
                          cancelLabel ?? 'cancel-text'.i18n(),
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onPressed,
                        style: ButtonStyle(
                          fixedSize: MaterialStateProperty.all(
                            Size(MediaQuery.of(context).size.width, 40),
                          ),
                          backgroundColor:
                              MaterialStateProperty.all(Colors.white),
                          elevation: MaterialStateProperty.all(0),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.yellow[700]!),
                            ),
                          ),
                        ),
                        child: Text(
                          cancelLabel ?? 'ok-text'.i18n(),
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.yellow[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showAlert(
  BuildContext context,
  String text, {
  String? title,
  bool isError = false,
  String? closeBackLabel,
  void Function()? onPressed,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Wrap(
          children: <Widget>[
            isError
                ? Center(
                    child: Text(
                      title ?? 'Whoops!',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  )
                : const Center(),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 70, top: 30, right: 70),
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ButtonStyle(
                    fixedSize: MaterialStateProperty.all(
                      Size(MediaQuery.of(context).size.width, 40),
                    ),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.yellow[700]),
                    elevation: MaterialStateProperty.all(0),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                  child: Text(
                    closeBackLabel ?? 'cancel-text'.i18n(),
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget showLoading(
  BuildContext context, {
  bool withBackground = true,
  bool isDownload = false,
  bool isTimer = false,
  int downloadProgress = 0,
}) {
  return Center(
    child: Container(
      color: withBackground ? const Color(0x80000000) : Colors.transparent,
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                !isTimer
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        '$downloadProgress',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 200,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                isDownload
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        child: Center(
                          child: Text(
                            'Downloading $downloadProgress%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Lato',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      )
                    : const Center(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Locale getCurrentLang(BuildContext context) {
  return Localizations.localeOf(context);
}

void changeLanguage(BuildContext context, Locale locale) {
  final myApp = context.findAncestorStateOfType<MyAppState>()!;
  myApp.changeLocale(locale);
}

Future<dynamic> getApplicationSettings({
  required String settingKey,
  required Type dataType,
}) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (dataType == bool) {
      return prefs.getBool(settingKey);
    } else if (dataType == String) {
      return prefs.getString(settingKey);
    } else if (dataType == int) {
      return prefs.getInt(settingKey);
    } else if (dataType == double) {
      return prefs.getDouble(settingKey);
    } else {
      return null;
    }
  } catch (e) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(msg: e.toString());
  }
}

Future<bool> checkGPSService() async {
  Location location = Location();
  return (await location.serviceEnabled());
}

Future<bool> requestGPSService() async {
  Location location = Location();
  return (await location.requestService());
}

Future<PermissionStatus> checkGPSPermission() async {
  Location location = Location();
  return (await location.hasPermission());
}

Future<PermissionStatus> requestGPSPermission() async {
  Location location = Location();
  return (await location.requestPermission());
}

Map<String, dynamic> readAndroidBuildData(AndroidDeviceInfo build) {
  return <String, dynamic>{
    'version.securityPatch': build.version.securityPatch,
    'version.sdkInt': build.version.sdkInt,
    'version.release': build.version.release,
    'version.previewSdkInt': build.version.previewSdkInt,
    'version.incremental': build.version.incremental,
    'version.codename': build.version.codename,
    'version.baseOS': build.version.baseOS,
    'board': build.board,
    'bootloader': build.bootloader,
    'brand': build.brand,
    'device': build.device,
    'display': build.display,
    'fingerprint': build.fingerprint,
    'hardware': build.hardware,
    'host': build.host,
    'id': build.id,
    'manufacturer': build.manufacturer,
    'model': build.model,
    'product': build.product,
    'supported32BitAbis': build.supported32BitAbis,
    'supported64BitAbis': build.supported64BitAbis,
    'supportedAbis': build.supportedAbis,
    'tags': build.tags,
    'type': build.type,
    'isPhysicalDevice': build.isPhysicalDevice,
    'systemFeatures': build.systemFeatures,
    'displaySizeInches':
        ((build.displayMetrics.sizeInches * 10).roundToDouble() / 10),
    'displayWidthPixels': build.displayMetrics.widthPx,
    'displayWidthInches': build.displayMetrics.widthInches,
    'displayHeightPixels': build.displayMetrics.heightPx,
    'displayHeightInches': build.displayMetrics.heightInches,
    'displayXDpi': build.displayMetrics.xDpi,
    'displayYDpi': build.displayMetrics.yDpi,
    'serialNumber': build.serialNumber,
  };
}

Map<String, dynamic> readIosDeviceInfo(IosDeviceInfo data) {
  return <String, dynamic>{
    'name': data.name,
    'systemName': data.systemName,
    'systemVersion': data.systemVersion,
    'model': data.model,
    'localizedModel': data.localizedModel,
    'identifierForVendor': data.identifierForVendor,
    'isPhysicalDevice': data.isPhysicalDevice,
    'utsname.sysname:': data.utsname.sysname,
    'utsname.nodename:': data.utsname.nodename,
    'utsname.release:': data.utsname.release,
    'utsname.version:': data.utsname.version,
    'utsname.machine:': data.utsname.machine,
  };
}

Map<String, dynamic> readLinuxDeviceInfo(LinuxDeviceInfo data) {
  return <String, dynamic>{
    'name': data.name,
    'version': data.version,
    'id': data.id,
    'idLike': data.idLike,
    'versionCodename': data.versionCodename,
    'versionId': data.versionId,
    'prettyName': data.prettyName,
    'buildId': data.buildId,
    'variant': data.variant,
    'variantId': data.variantId,
    'machineId': data.machineId,
  };
}

Map<String, dynamic> readWebBrowserInfo(WebBrowserInfo data) {
  return <String, dynamic>{
    'browserName': describeEnum(data.browserName),
    'appCodeName': data.appCodeName,
    'appName': data.appName,
    'appVersion': data.appVersion,
    'deviceMemory': data.deviceMemory,
    'language': data.language,
    'languages': data.languages,
    'platform': data.platform,
    'product': data.product,
    'productSub': data.productSub,
    'userAgent': data.userAgent,
    'vendor': data.vendor,
    'vendorSub': data.vendorSub,
    'hardwareConcurrency': data.hardwareConcurrency,
    'maxTouchPoints': data.maxTouchPoints,
  };
}

Map<String, dynamic> readMacOsDeviceInfo(MacOsDeviceInfo data) {
  return <String, dynamic>{
    'computerName': data.computerName,
    'hostName': data.hostName,
    'arch': data.arch,
    'model': data.model,
    'kernelVersion': data.kernelVersion,
    'osRelease': data.osRelease,
    'activeCPUs': data.activeCPUs,
    'memorySize': data.memorySize,
    'cpuFrequency': data.cpuFrequency,
    'systemGUID': data.systemGUID,
  };
}

Map<String, dynamic> readWindowsDeviceInfo(WindowsDeviceInfo data) {
  return <String, dynamic>{
    'numberOfCores': data.numberOfCores,
    'computerName': data.computerName,
    'systemMemoryInMegabytes': data.systemMemoryInMegabytes,
    'userName': data.userName,
    'majorVersion': data.majorVersion,
    'minorVersion': data.minorVersion,
    'buildNumber': data.buildNumber,
    'platformId': data.platformId,
    'csdVersion': data.csdVersion,
    'servicePackMajor': data.servicePackMajor,
    'servicePackMinor': data.servicePackMinor,
    'suitMask': data.suitMask,
    'productType': data.productType,
    'reserved': data.reserved,
    'buildLab': data.buildLab,
    'buildLabEx': data.buildLabEx,
    'digitalProductId': data.digitalProductId,
    'displayVersion': data.displayVersion,
    'editionId': data.editionId,
    'installDate': data.installDate,
    'productId': data.productId,
    'productName': data.productName,
    'registeredOwner': data.registeredOwner,
    'releaseId': data.releaseId,
    'deviceId': data.deviceId,
  };
}

const List<String> BpsMonth = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember'
];

String getDay(String dayInEnglish) {
  switch (dayInEnglish) {
    case 'Mon':
      return 'Sen';
    case 'Tue':
      return 'Sel';
    case 'Wed':
      return 'Rab';
    case 'Thu':
      return 'Kam';
    case 'Fri':
      return "Jum";
    case 'Sat':
      return 'Sab';
    case 'Sun':
      return 'Min';
    default:
      return 'Unknown day';
  }
}

String getDayLong(String dayInEnglish) {
  switch (dayInEnglish) {
    case 'Monday':
      return 'Senin';
    case 'Tuesday':
      return 'Selasa';
    case 'Wednesday':
      return 'Rabu';
    case 'Thursday':
      return 'Kamis';
    case 'Friday':
      return "Jum'at";
    case 'Saturday':
      return 'Sabtu';
    case 'Sunday':
      return 'Minggu';
    default:
      return 'Unknown day';
  }
}

String dateToString({
  required DateTime date,
  String? separator = '',
  bool withYear = true,
  bool usingMonthName = false,
  bool showTime = false,
  bool usingDayName = false,
  bool withSeconds = false,
}) {
  String monthName = (usingMonthName
      ? BpsMonth.elementAt(date.month - 1)
      : date.month.toString().padLeft(2, "0"));
  String year = (withYear ? date.year.toString().padLeft(4, "0") : "");
  String withTime = (showTime
      ? ' ${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}${withSeconds ? ':${date.second.toString().padLeft(2, "0")}' : ''} WIB'
      : '');
  String dayName =
      usingDayName ? '${getDay(intl.DateFormat.E().format(date))}, ' : '';

  return '$dayName${date.day.toString().padLeft(2, "0")}$separator$monthName$separator$year$withTime';
}

SettingFilename defaultFilename =
    SettingFilename(list: defaultFilenameList.toList());

final defaultFilenameList = [
  SettingFilenameList(
    key: "dnt",
    header: "dt-text".i18n(),
    isSelected: true,
    body: <SettingFilenameBody>[
      SettingFilenameBody(
        key: "dt",
        title: "dt-text".i18n(),
        body: intl.DateFormat("yyyyMMdd").format(DateTime.now()),
        isSelected: true,
      ),
      SettingFilenameBody(
        key: "hms",
        title: "hms-text".i18n(),
        body: intl.DateFormat("hhmsa")
            .format(DateTime.now())
            .replaceAll(':', '')
            .replaceAll(' ', ''),
        isSelected: true,
      ),
      SettingFilenameBody(
        key: "day",
        title: "day-text".i18n(),
        body: intl.DateFormat("EEEE").format(DateTime.now()),
        isSelected: false,
      ),
      SettingFilenameBody(
        key: "h",
        title: "24-hour-text".i18n(),
        body: intl.DateFormat("Hms")
            .format(DateTime.now())
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
];

List<Map<String, dynamic>> defaultFn = <Map<String, dynamic>>[
  {
    "key": "dnt",
    "header": "dt-text".i18n(),
    "isSelected": true,
    "bodyType": List<SettingFilenameBody>,
    "bodyList": <Map<String, dynamic>>[
      {
        "key": "dt",
        "title": "dt-text".i18n(),
        "body": intl.DateFormat("yyyyMMdd").format(DateTime.now()),
        "isSelected": true,
      },
      {
        "key": "hms",
        "title": "hms-text".i18n(),
        "body": intl.DateFormat("hhmsa")
            .format(DateTime.now())
            .replaceAll(':', '')
            .replaceAll(' ', ''),
        "isSelected": true,
      },
      {
        "key": "day",
        "title": "day-text".i18n(),
        "body": intl.DateFormat("EEEE").format(DateTime.now()),
        "isSelected": false,
      },
      {
        "key": "h",
        "title": "24-hour-text".i18n(),
        "body": intl.DateFormat("Hms")
            .format(DateTime.now())
            .replaceAll(':', '')
            .replaceAll(' ', ''),
        "isSelected": false,
      },
    ],
    "isPremium": false,
  },
  {
    "key": "sn",
    "header": "sequence-number-text".i18n(),
    "isSelected": false,
    "bodyType": String,
    "body": "1",
    "isPremium": false,
  },
  {
    "key": "cn1",
    "header": "custom-name-text".i18n(["1"]),
    "isSelected": true,
    "bodyType": String,
    "body": "captured-by-text".i18n(),
    "isPremium": true,
  },
];

void enterFullscreen() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: <SystemUiOverlay>[
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ],
  );
}

void exitFullscreen() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
