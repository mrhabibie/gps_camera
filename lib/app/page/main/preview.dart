import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fullscreen/fullscreen.dart';
import 'package:gps_camera/app/utils/constants.dart';
import 'package:localization/localization.dart';
import 'package:share_plus/share_plus.dart';

class PreviewPageArguments {
  final List<File> files;

  PreviewPageArguments(this.files);
}

class PreviewPage extends StatefulWidget {
  const PreviewPage({Key? key, required this.files}) : super(key: key);

  final List<File> files;

  @override
  State<PreviewPage> createState() => _GpsCameraSharePreviewPageState();
}

class _GpsCameraSharePreviewPageState extends State<PreviewPage> {
  bool _menuVisible = true;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.of(context).pop(context);

        return Future.value(true);
      },
      child: AnnotatedRegion(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarDividerColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _menuVisible = !_menuVisible;
                    });

                    if (_menuVisible) {
                      _exitFullscreen();
                    } else {
                      _enterFullscreen();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 45),
                    child: widget.files.isNotEmpty
                        ? CarouselSlider.builder(
                            itemCount: widget.files.length,
                            itemBuilder: (context, index, realIndex) =>
                                Image.file(widget.files.elementAt(index)),
                            options: CarouselOptions(
                              enableInfiniteScroll: false,
                              height: MediaQuery.of(context).size.height - 45,
                              viewportFraction: 1,
                              enlargeCenterPage: true,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              'no-photo-found-text'.i18n(),
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
                _menuVisible
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(context);
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          widget.files.isNotEmpty
                              ? Container(
                                  color: Colors.black.withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Column(
                                        children: <Widget>[
                                          IconButton(
                                            onPressed: () {
                                              Share.shareXFiles([
                                                XFile(widget.files
                                                    .elementAt(_selectedIndex)
                                                    .path)
                                              ]);
                                            },
                                            icon: const Icon(
                                              Icons.share,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'share-text'.i18n(),
                                            style: const TextStyle(
                                              fontFamily: 'Lato',
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: <Widget>[
                                          IconButton(
                                            onPressed: () {
                                              confirmWidget(
                                                context,
                                                title:
                                                    'confirm-title-text'.i18n(),
                                                subTitle:
                                                    'del-confirm-text'.i18n(),
                                                onPressed: () {
                                                  widget.files
                                                      .elementAt(_selectedIndex)
                                                      .delete()
                                                      .then((value) {
                                                    if (!value.existsSync()) {
                                                      Fluttertoast.cancel();
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              'del-success-text'
                                                                  .i18n());

                                                      Navigator.of(context)
                                                          .pop();

                                                      setState(() {
                                                        widget.files.removeAt(
                                                            _selectedIndex);
                                                      });
                                                    } else {
                                                      Fluttertoast.cancel();
                                                      Fluttertoast.showToast(
                                                          msg: 'del-fail-text'
                                                              .i18n());
                                                    }
                                                  });
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'delete-text'.i18n(),
                                            style: const TextStyle(
                                              fontFamily: 'Lato',
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : const Center(),
                        ],
                      )
                    : const Center(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enterFullscreen() async {
    await FullScreen.enterFullScreen(FullScreenMode.EMERSIVE_STICKY);
  }

  Future<void> _exitFullscreen() async {
    await FullScreen.exitFullScreen();
  }
}
