import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart' as Geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gps_camera/app/page/main/preview.dart';
import 'package:gps_camera/app/page/pages.dart';
import 'package:gps_camera/app/utils/bps_color.dart';
import 'package:gps_camera/app/utils/constants.dart';
import 'package:gps_camera/app/widgets/rounded_button_widget.dart';
import 'package:gps_camera/app/widgets/shimmer_loading_widget.dart';
import 'package:gps_camera/data/utils/app_settings.dart';
import 'package:gps_camera/domain/entities/settings/setting_photo_dir.dart';
import 'package:localization/localization.dart';
import 'package:location/location.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart' as PhotoManager;
import 'package:widgets_to_image/widgets_to_image.dart';

class AspectRatioCamera {
  final String text;
  final double width;
  final double height;
  final double ratio;

  AspectRatioCamera(this.text, this.width, this.height, this.ratio);
}

class TimerCamera {
  final String text;
  final int time;

  TimerCamera(this.text, this.time);
}

class MainCameraPageArguments {
  final String appName;
  final String appVersion;

  MainCameraPageArguments(this.appName, this.appVersion);
}

class MainCameraPage extends StatefulWidget {
  const MainCameraPage({
    Key? key,
    required this.appName,
    required this.appVersion,
  }) : super(key: key);

  final String appName;
  final String appVersion;

  @override
  State<MainCameraPage> createState() => _GpsCameraPageState();
}

class _GpsCameraPageState extends State<MainCameraPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  List<CameraDescription> _cameras = <CameraDescription>[];
  bool isCameraAuthorized = false;
  bool isLoading = false;
  bool _appBarVisible = false;
  final _currentKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;

  CameraController? _cameraController;
  File? _recentImageFile;
  double _minAvailExposureOffset = 0.0;
  double _maxAvailExposureOffset = 0.0;
  final double _currentExposureOffset = 0.0;
  late AnimationController _flashControlAnimationController;
  late Animation<double> _flashControlAnimation;
  late AnimationController _exposureControlAnimationController;
  late Animation<double> _exposureControlAnimation;
  late AnimationController _focusControlAnimationController;
  late Animation<double> _focusControlAnimation;
  double _minAvailZoom = 1.0;
  double _maxAvailZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  final List<AspectRatioCamera> _aspectRatioList = [];
  int _aspectRatio = 0;
  final List<TimerCamera> _timerList = [];
  int _selectedTimer = 0;
  int _timerCount = 0;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  Uint8List? _gMapSnapshot;
  Completer<GoogleMapController>? _gMapController;
  FlashMode? _flashMode;
  CameraPosition? _mapLocation;
  Location? _userLatLng;
  LocationData? _locationData;
  List<Geocoding.Placemark> _placeMarks = [];
  bool _locationEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  DateTime _currentDate = DateTime.now();
  PackageInfo? _packageInfo;

  final PhotoManager.FilterOptionGroup _filterOptionGroup =
      PhotoManager.FilterOptionGroup(
    imageOption: const PhotoManager.FilterOption(
      sizeConstraint: PhotoManager.SizeConstraint(ignoreSize: true),
    ),
  );
  final int _sizePerPage = 50;
  PhotoManager.AssetPathEntity? _currentPath;
  List<PhotoManager.AssetEntity>? _entities;
  String? _savePhotoPath = 'Loading...';
  bool _saveOriPhotos = false;
  bool _hasSdCard = false;
  final List<File> _allFileList = [];
  DateTime? currentBackPressTime;

  final WidgetsToImageController _addressImgController =
      WidgetsToImageController();

  List<String> _zoomText = [];
  final bool _showSliderZoom = false;

  bool _cameraButtonReadyToClick = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flashMode = FlashMode.off;

    _cameraButtonReadyToClick = false;
    _appBarVisible = false;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      value: 1,
      vsync: this,
    );

    _zoomText = [];

    _getAvailableCameras().then((_) async {
      var size = MediaQuery.of(context).size;

      List<AspectRatioCamera> aspectRatioList = [
        AspectRatioCamera("1:1", 1, 1, 1.0),
        AspectRatioCamera("3:4", 3, 4, 3 / 4),
        AspectRatioCamera("9:16", 9, 16, 9 / 16),
        AspectRatioCamera("full-text".i18n(), size.width, size.height,
            size.width / size.height),
      ];
      _aspectRatioList.addAll(aspectRatioList);

      List<TimerCamera> timerList = [
        TimerCamera("off-text".i18n(), 0),
        TimerCamera("3s-text".i18n(), 3),
        TimerCamera("5s-text".i18n(), 5),
        TimerCamera("10s-text".i18n(), 10),
      ];
      _timerList.addAll(timerList);

      _packageInfo = await PackageInfo.fromPlatform();

      _onNewCameraSelected(_cameras[0]).then((_) {
        _zoomText.add(_minAvailZoom.toStringAsFixed(1));
        _zoomText.add((_maxAvailZoom / 2).toStringAsFixed(1));
        _zoomText.add(_maxAvailZoom.toStringAsFixed(1));

        enterFullscreen();

        _getUserLocation().then((_) {
          _getUserAddress().then((_) {
            _hasSdCardSlot().then((_) {
              _getGallery().then((_) {
                AppSettings.getDefaultDir().then((SettingPhotoDirs dirs) {
                  _savePhotoPath = dirs.dirs
                      .firstWhere((element) => element.isSelected)
                      .title;

                  _cameraButtonReadyToClick = true;

                  setState(() {});
                });
              });
            });
          });
        });
      });
    });

    Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentDate = DateTime.now();
      });
    });

    _flashControlAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashControlAnimation = CurvedAnimation(
      parent: _flashControlAnimationController,
      curve: Curves.easeInCubic,
    );

    _exposureControlAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureControlAnimation = CurvedAnimation(
      parent: _exposureControlAnimationController,
      curve: Curves.easeInCubic,
    );

    _focusControlAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusControlAnimation = CurvedAnimation(
      parent: _focusControlAnimationController,
      curve: Curves.easeInCubic,
    );
  }

  Future<void> _getGallery() async {
    // Get the directory
    final defaultDir = await AppSettings.getDefaultDir();
    String dir =
        defaultDir.dirs.firstWhere((element) => element.isSelected).dirPath;
    String newDir = dir.replaceAll(dir.split('/').last, '');
    final Directory directory = Directory(newDir);
    List<FileSystemEntity> fileList = await directory.list().toList();
    _recentImageFile = null;
    _allFileList.clear();

    // Searching for all the image files using
    // their default format, and storing them
    for (var file in fileList) {
      print('==> file: ${file.path}');

      if (!file.path.contains('.jpg')) {
        final Directory nD = Directory(file.path);
        List<FileSystemEntity> dirFiles = await nD.list().toList();
        for (var nF in dirFiles) {
          if (nF.path.contains('.jpg') &&
              !nF.path.split('/').last.contains('.trashed')) {
            _allFileList.add(File(nF.path));
          }
        }
      } else {
        if (file.path.contains('.jpg') &&
            !file.path.split('/').last.contains('.trashed')) {
          _allFileList.add(File(file.path));
        }
      }
    }

    _allFileList
        .sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    // Retrieving the recent file
    if (_allFileList.isNotEmpty) {
      _recentImageFile = File(_allFileList.last.path);
    }

    setState(() {});
  }

  Future<void> _onNewCameraSelected(CameraDescription description) async {
    final CameraController? oldController = _cameraController;
    if (oldController != null) {
      // `controller` needs to be set to null before getting disposed,
      // to avoid a race condition when we use the controller that is being
      // disposed. This happens when camera permission dialog shows up,
      // which triggers `didChangeAppLifecycleState`, which disposes and
      // re-creates the controller.
      _cameraController = null;
      await oldController.dispose();
    }

    final CameraController camController = CameraController(
      description,
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = camController;

    // If the controller is updated then update the UI.
    camController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (camController.value.hasError) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(
            msg: 'Camera error ${camController.value.errorDescription}');
      }
    });

    try {
      await camController.initialize();
      await Future.wait(<Future<Object?>>[
        // The exposure mode is currently not supported on the web.
        ...<Future<Object?>>[
          camController
              .getMinExposureOffset()
              .then((double value) => _minAvailExposureOffset = value),
          camController
              .getMaxExposureOffset()
              .then((double value) => _maxAvailExposureOffset = value)
        ],
        camController
            .getMinZoomLevel()
            .then((double value) => _minAvailZoom = value),
        camController
            .getMaxZoomLevel()
            .then((double value) => _maxAvailZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          Fluttertoast.cancel();
          Fluttertoast.showToast(msg: 'You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          Fluttertoast.cancel();
          Fluttertoast.showToast(
              msg: 'Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
          // iOS only
          Fluttertoast.cancel();
          Fluttertoast.showToast(msg: 'Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          Fluttertoast.cancel();
          Fluttertoast.showToast(msg: 'You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          Fluttertoast.cancel();
          Fluttertoast.showToast(
              msg: 'Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
          // iOS only
          Fluttertoast.cancel();
          Fluttertoast.showToast(msg: 'Audio access is restricted.');
          break;
        default:
          _showCameraException(e);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _getAvailableCameras() async {
    _cameras = await availableCameras();
  }

  void _toggleAppBarVisible() {
    setState(() {
      _appBarVisible = !_appBarVisible;
      /*_appBarVisible
          ? _animationController.forward()
          : _animationController.reverse();*/
    });
  }

  Set<Marker> _createMarker() {
    return <Marker>{
      Marker(
        markerId: const MarkerId("marker_1"),
        draggable: false,
        position: _mapLocation!.target,
        icon: BitmapDescriptor.defaultMarker,
      ),
    };
  }

  Future<void> _getUserLocation() async {
    _gMapController = Completer<GoogleMapController>();
    _userLatLng = Location();
    if (_userLatLng != null) {
      _locationEnabled = await _userLatLng!.serviceEnabled();
      if (!_locationEnabled) {
        return;
      }

      _permissionGranted = await _userLatLng!.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await _userLatLng!.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      _locationData = await _userLatLng!.getLocation();

      _mapLocation = CameraPosition(
        target: LatLng(_locationData!.latitude!, _locationData!.longitude!),
        zoom: 14.4746,
      );
    }
  }

  Future<void> _getUserAddress() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _placeMarks = await Geocoding.placemarkFromCoordinates(
          _locationData!.latitude!,
          _locationData!.longitude!,
        );
      }
    } on SocketException catch (_) {
      _placeMarks = await AppSettings.getLastLocation();
    }

    AppSettings.setLastLocation(_placeMarks);

    setState(() {});
  }

  Future<void> _hasSdCardSlot() async {
    List<Directory>? externalStorageDirectories =
        await getExternalStorageDirectories();
    if (externalStorageDirectories != null) {
      for (Directory directory in externalStorageDirectories) {
        if (directory.path.contains("sdcard")) {
          _hasSdCard = true;
        }
      }
    }

    _hasSdCard = false;
  }

  Future<bool> onWillPop() async {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: 'press-back-button-text'.i18n());

      return Future.value(false);
    }

    exitFullscreen();

    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: AnnotatedRegion(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarDividerColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          key: _currentKey,
          backgroundColor: Colors.black,
          drawer: Drawer(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      ListTile(
                        title: Text(
                          widget.appName,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.abc),
                        title: Text(
                          'watermark-text'.i18n(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: Switch(
                          activeColor: Colors.yellow[700],
                          value: true,
                          onChanged: (value) {},
                        ),
                      ),
                      _hasSdCard
                          ? ListTile(
                              leading: const Icon(Icons.folder_open),
                              title: Text(
                                'sd-card-permission-text'.i18n(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              trailing: Switch(
                                value: false,
                                onChanged: (value) {},
                              ),
                            )
                          : const Center(),
                      ListTile(
                        onTap: () {
                          changeLanguage(
                              context,
                              getCurrentLang(context) == const Locale('id')
                                  ? const Locale('en')
                                  : const Locale('id'));
                        },
                        leading: const Icon(Icons.translate),
                        title: Text(
                          'language-text'.i18n(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: Text(
                          getCurrentLang(context).languageCode.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.layers),
                        title: Text(
                          'version-text'.i18n(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: Text(
                          widget.appVersion,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: BPSColor.textPlaceholder),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(1000),
                          ),
                          child: Container(
                            height: 50,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(30)),
                            ),
                            child: Icon(
                              Icons.workspace_premium,
                              color: Colors.yellow[700],
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'get-premium-text'.i18n().toUpperCase(),
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent[700],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  margin: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    'upgrade-text'.i18n().toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 10,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: AnnotatedRegion(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.black,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Colors.black,
              systemNavigationBarDividerColor: Colors.black,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  _cameraPreviewWidget(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                IconButton(
                                  onPressed:
                                      !_isTakingPicture && _timerCount <= 0
                                          ? () {
                                              _currentKey.currentState
                                                  ?.openDrawer();
                                            }
                                          : null,
                                  icon: const Icon(
                                    Icons.sort,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _cameraController != null &&
                                          !_isTakingPicture &&
                                          _timerCount <= 0
                                      ? onFlashButtonPressed
                                      : null,
                                  icon: Icon(
                                    _flashMode == FlashMode.auto
                                        ? Icons.flash_auto
                                        : _flashMode == FlashMode.always ||
                                                _flashMode == FlashMode.torch
                                            ? Icons.flash_on
                                            : Icons.flash_off,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      !_isTakingPicture && _timerCount <= 0
                                          ? () async {
                                              exitFullscreen();

                                              var result =
                                                  await Navigator.of(context)
                                                      .pushNamed(
                                                          Pages.customFileName);
                                              if (result != null) {
                                                enterFullscreen();
                                              }
                                            }
                                          : null,
                                  icon: const Icon(
                                    Icons.drive_file_rename_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: !_isTakingPicture &&
                                          _timerCount <= 0
                                      ? () => onChanged(_cameras.firstWhere(
                                          (element) =>
                                              element !=
                                              _cameraController?.description))
                                      : null,
                                  icon: const Icon(
                                    Icons.flip_camera_android,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      !_isTakingPicture && _timerCount <= 0
                                          ? _toggleAppBarVisible
                                          : null,
                                  icon: const Icon(
                                    Icons.tune,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _appBarVisible
                              ? Container(
                                  padding: const EdgeInsets.all(15),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      GestureDetector(
                                        onTap: !_isTakingPicture &&
                                                _timerCount <= 0
                                            ? () {
                                                setState(() {
                                                  if ((_aspectRatio + 1) <
                                                      _aspectRatioList.length) {
                                                    _aspectRatio++;
                                                  } else {
                                                    _aspectRatio = 0;
                                                  }
                                                });
                                              }
                                            : null,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Icon(
                                              Icons.aspect_ratio,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 5),
                                              child: Text(
                                                'Ratio (${_aspectRatioList.elementAt(_aspectRatio).text})',
                                                style: const TextStyle(
                                                  fontFamily: 'Lato',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: null,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Icon(
                                              Icons.grid_off,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 5),
                                              child: const Text(
                                                'None',
                                                style: TextStyle(
                                                  fontFamily: 'Lato',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: !_isTakingPicture &&
                                                _timerCount <= 0
                                            ? () {
                                                setState(() {
                                                  if ((_selectedTimer + 1) <
                                                      _timerList.length) {
                                                    _selectedTimer++;
                                                  } else {
                                                    _selectedTimer = 0;
                                                  }
                                                });
                                              }
                                            : null,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Icon(
                                              Icons.timer,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 5),
                                              child: Text(
                                                _timerList
                                                    .elementAt(_selectedTimer)
                                                    .text,
                                                style: const TextStyle(
                                                  fontFamily: 'Lato',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Center(),
                        ],
                      ),
                      SizedBox(
                        height: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () async {
                                exitFullscreen();

                                var result =
                                    await Navigator.of(context).pushNamed(
                                  Pages.preview,
                                  arguments: PreviewPageArguments(
                                      _allFileList.reversed.toList()),
                                );
                                if (result != null) {
                                  _getGallery();

                                  enterFullscreen();
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1000),
                                  child: _recentImageFile != null
                                      ? Image.file(
                                          _recentImageFile!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(color: Colors.black),
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const <Widget>[
                                  IconButton(
                                    onPressed: null,
                                    icon: Icon(
                                      Icons.timer,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  Text(
                                    'Coming soon',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.white, width: 5),
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: RoundedButtonWidget(
                                  label: '',
                                  backgroundColor: Colors.white,
                                  borderSide: const BorderSide(
                                      color: Colors.black, width: 5),
                                  borderRadius: 1000,
                                  onPressed: _cameraButtonReadyToClick &&
                                          !_isTakingPicture &&
                                          _timerCount <= 0
                                      ? () {
                                          _timerCount = _timerList
                                              .elementAt(_selectedTimer)
                                              .time;

                                          Timer.periodic(
                                              const Duration(seconds: 1),
                                              (timer) {
                                            if (!mounted) {
                                              return;
                                            }

                                            if (_timerCount == 0) {
                                              timer.cancel();
                                              _takePicture();
                                            } else {
                                              _timerCount--;
                                            }
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  IconButton(
                                    onPressed:
                                        !_isTakingPicture && _timerCount <= 0
                                            ? () async {
                                                exitFullscreen();

                                                var result =
                                                    await Navigator.of(context)
                                                        .pushNamed(
                                                            Pages.saveFolder);
                                                if (result != null &&
                                                    result is List<dynamic>) {
                                                  enterFullscreen();

                                                  _getGallery();

                                                  setState(() {
                                                    _savePhotoPath = result[0];
                                                    _saveOriPhotos = result[1];
                                                  });
                                                }
                                              }
                                            : null,
                                    icon: const Icon(
                                      Icons.folder,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  Text(
                                    '$_savePhotoPath',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const <Widget>[
                                  IconButton(
                                    onPressed: null,
                                    icon: Icon(
                                      Icons.timer,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  Text(
                                    'Coming soon',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _isTakingPicture ? showLoading(context) : const Center(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    String fileName = '';
    String appDirName = '';
    String dirPhoto = '';
    File? oriPhoto;
    File imgCaptured;

    setState(() {
      _isTakingPicture = true;
    });

    await AppSettings.getDefaultFilename(exportAs: String)
        .then((value) => fileName = value);
    await AppSettings.getDefaultAppDir().then((value) => appDirName = value);
    await AppSettings.getDefaultDir().then((dirs) {
      dirPhoto = dirs.dirs.firstWhere((dir) => dir.isSelected).dirPath;
    });
    await AppSettings.getSaveOriPhoto().then((value) => _saveOriPhotos = value);

    if (fileName.isEmpty || appDirName.isEmpty || dirPhoto.isEmpty) {
      setState(() {
        _isTakingPicture = false;
      });

      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: 'error-text'.i18n());
      return;
    }

    if (!Directory(appDirName).existsSync()) {
      Directory(appDirName).createSync(recursive: true);
    }

    if (!Directory(dirPhoto).existsSync()) {
      Directory(dirPhoto).createSync(recursive: true);
    }

    if (_saveOriPhotos) {
      final CameraController? camCtrl = _cameraController;
      if (camCtrl == null || !camCtrl.value.isInitialized) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(msg: 'save-image-failed-text'.i18n());
        return;
      }

      if (!camCtrl.value.isTakingPicture) {
        try {
          await camCtrl.takePicture().then((img) {
            img.saveTo('$appDirName/ORI_$fileName');
            oriPhoto = File('$appDirName/ORI_$fileName');
          });
        } on CameraException catch (e) {
          Fluttertoast.cancel();
          Fluttertoast.showToast(msg: 'save-image-failed-text'.i18n());
          return;
        }
      }
    }

    try {
      Uint8List? pngBytes = await _addressImgController.capture();
      imgCaptured = File('$appDirName/$fileName');
      imgCaptured.writeAsBytes(pngBytes!).then((_) async {
        if (_saveOriPhotos) {
          oriPhoto?.copySync('$dirPhoto/ORI_$fileName');
          oriPhoto?.deleteSync();
        }

        imgCaptured.copySync('$dirPhoto/$fileName');
        imgCaptured.deleteSync();

        await MediaScanner.loadMedia(path: dirPhoto).then((String? value) {
          _getGallery();

          setState(() {
            _recentImageFile = File('$dirPhoto/$fileName');
            _isTakingPicture = false;
          });
        });
      });
    } catch (e) {
      if (!mounted) return;

      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: e.toString());
      return;
    }
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    Fluttertoast.cancel();
    Fluttertoast.showToast(msg: 'Error: ${e.code}\n${e.description}');
  }

  void _logError(String code, String? message) {
    // ignore: avoid_print
    print('Error: $code${message == null ? '' : '\nError Message: $message'}');
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (_cameraController == null || _pointers != 2) {
      return;
    }

    _currentScale =
        (_baseScale * details.scale).clamp(_minAvailZoom, _maxAvailZoom);

    await _cameraController!.setZoomLevel(_currentScale);
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_cameraController == null) {
      return;
    }

    final CameraController camController = _cameraController!;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    camController.setExposurePoint(offset);
    camController.setFocusPoint(offset);

    setState(() {
      _appBarVisible = false;
    });
  }

  Widget _cameraPreviewWidget() {
    final CameraController? camController = _cameraController;

    if (camController == null || !camController.value.isInitialized) {
      return const Center(
        child: Text(
          'Gagal membuka kamera.',
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      );
    } else if (camController.value.isPreviewPaused) {
      return const Center(
        child: Text(
          'Loading...',
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return Listener(
        onPointerDown: (event) => _pointers++,
        onPointerUp: (event) => _pointers--,
        child: WidgetsToImage(
          controller: _addressImgController,
          child: Transform.scale(
            scale: _aspectRatioList.elementAt(_aspectRatio).ratio,
            child: CameraPreview(
              camController,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: !_isTakingPicture && _timerCount <= 0
                      ? _handleScaleStart
                      : null,
                  onScaleUpdate: !_isTakingPicture && _timerCount <= 0
                      ? _handleScaleUpdate
                      : null,
                  onTapDown: (details) => !_isTakingPicture && _timerCount <= 0
                      ? onViewFinderTap(details, constraints)
                      : null,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      SizedBox(
                        height: 150,
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const SizedBox(width: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(5),
                                    ),
                                  ),
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 5),
                                  child: Row(
                                    children: <Widget>[
                                      const FlutterLogo(size: 12),
                                      Container(
                                        margin: const EdgeInsets.only(left: 5),
                                        child: Text(
                                          widget.appName,
                                          style: const TextStyle(
                                            fontFamily: 'Lato',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 150,
                                child: Row(
                                  children: <Widget>[
                                    _mapLocation != null
                                        ? Container(
                                            width: 120,
                                            height: 150,
                                            margin: const EdgeInsets.only(
                                              left: 10,
                                              bottom: 10,
                                              right: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: _gMapSnapshot != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: Image.memory(
                                                      _gMapSnapshot!,
                                                      width: 120,
                                                      height: 150,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : GoogleMap(
                                                    initialCameraPosition:
                                                        _mapLocation!,
                                                    markers: _createMarker(),
                                                    zoomControlsEnabled: false,
                                                    tiltGesturesEnabled: false,
                                                    zoomGesturesEnabled: false,
                                                    mapToolbarEnabled: false,
                                                    onMapCreated:
                                                        (controller) async {
                                                      if (_gMapController !=
                                                          null) {
                                                        if (!_gMapController!
                                                            .isCompleted) {
                                                          _gMapController!
                                                              .complete(
                                                                  controller);
                                                        }
                                                      }
                                                    },
                                                    onCameraIdle: () async {
                                                      GoogleMapController
                                                          gController =
                                                          await _gMapController!
                                                              .future;
                                                      Future<void>.delayed(
                                                          const Duration(
                                                              milliseconds:
                                                                  1000),
                                                          () async {
                                                        _gMapSnapshot =
                                                            await gController
                                                                .takeSnapshot();
                                                        setState(() {});
                                                      });
                                                    },
                                                  ),
                                          )
                                        : ShimmerLoadingWidget(
                                            width: 100,
                                            height: 150,
                                            margin: const EdgeInsets.only(
                                              left: 10,
                                              bottom: 10,
                                              right: 5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                    Expanded(
                                      child: Container(
                                        height: 150,
                                        padding: const EdgeInsets.all(10),
                                        margin: const EdgeInsets.only(
                                            left: 5, bottom: 10, right: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            bottomLeft: Radius.circular(10),
                                            bottomRight: Radius.circular(10),
                                          ),
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text(
                                              _placeMarks.isEmpty
                                                  ? 'Loading...'
                                                  : '${_placeMarks.first.street}',
                                              style: const TextStyle(
                                                fontFamily: 'Lato',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              _placeMarks.isEmpty
                                                  ? 'Loading...'
                                                  : _placeMarks.first.locality!
                                                      .replaceAll(
                                                          'Kecamatan', 'Kec.'),
                                              style: const TextStyle(
                                                fontFamily: 'Lato',
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              _placeMarks.isEmpty
                                                  ? 'Loading...'
                                                  : '${_placeMarks.first.subAdministrativeArea}',
                                              style: const TextStyle(
                                                fontFamily: 'Lato',
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              _placeMarks.isEmpty
                                                  ? 'Loading...'
                                                  : '${_placeMarks.first.administrativeArea}',
                                              style: const TextStyle(
                                                fontFamily: 'Lato',
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              dateToString(
                                                date: _currentDate,
                                                separator: ' ',
                                                withYear: true,
                                                showTime: true,
                                                usingMonthName: true,
                                                usingDayName: true,
                                                withSeconds: true,
                                              ),
                                              style: const TextStyle(
                                                fontFamily: 'Lato',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _timerCount > 0
                          ? showLoading(
                              context,
                              isTimer: true,
                              withBackground: false,
                              downloadProgress: _timerCount,
                            )
                          : const Center(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  /// Returns a suitable camera icon for [direction].
  IconData getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.camera_rear;
      case CameraLensDirection.front:
        return Icons.camera_front;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        throw ArgumentError('Unknown lens direction');
    }
  }

  void onChanged(CameraDescription? description) {
    if (description == null) {
      return;
    }

    _onNewCameraSelected(description);
  }

  void onFlashButtonPressed() {
    if (_flashMode == FlashMode.off) {
      _flashMode = FlashMode.auto;
    } else if (_flashMode == FlashMode.auto) {
      _flashMode = FlashMode.torch;
    } else if (_flashMode == FlashMode.torch) {
      _flashMode = FlashMode.off;
    }

    setState(() {
      _cameraController?.setFlashMode(_flashMode ?? FlashMode.off);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? camController = _cameraController;

    if (camController == null || !camController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      camController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(camController.description);
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _flashControlAnimationController.dispose();
    _exposureControlAnimationController.dispose();
    _cameraController?.dispose();
    _animationController.dispose();
  }
}
