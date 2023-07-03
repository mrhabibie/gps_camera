import 'package:flutter/material.dart';
import 'package:gps_camera/app/page/file_name/view.dart';
import 'package:gps_camera/app/page/main/preview.dart';
import 'package:gps_camera/app/page/main/view.dart';
import 'package:gps_camera/app/page/pages.dart';
import 'package:gps_camera/app/page/permission/view.dart';
import 'package:gps_camera/app/page/save_folder/view.dart';

class BpsRouter {
  final RouteObserver<PageRoute> routeObserver;

  BpsRouter() : routeObserver = RouteObserver<PageRoute>();

  Route<dynamic>? getRoute(RouteSettings settings) {
    switch (settings.name) {
      case Pages.main:
        MainCameraPageArguments args =
            settings.arguments as MainCameraPageArguments;
        return _buildRoute(
          settings,
          MainCameraPage(
            appName: args.appName,
            appVersion: args.appVersion,
          ),
        );
      case Pages.preview:
        PreviewPageArguments args = settings.arguments as PreviewPageArguments;
        return _buildRoute(settings, PreviewPage(files: args.files));
      case Pages.permission:
        PermissionPageArguments args =
            settings.arguments as PermissionPageArguments;
        return _buildRoute(
          settings,
          PermissionPage(
            appVersion: args.appVersion,
          ),
        );
      case Pages.saveFolder:
        return _buildRoute(settings, const SaveFolderPage());
      case Pages.customFileName:
        return _buildRoute(settings, const CustomFileNamePage());
      default:
        return null;
    }
  }

  MaterialPageRoute _buildRoute(RouteSettings settings, Widget builder) =>
      MaterialPageRoute(
        settings: settings,
        builder: (context) => builder,
      );
}
