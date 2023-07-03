import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gps_camera/app/widgets/expansion_panel_widget.dart';
import 'package:gps_camera/data/utils/app_settings.dart';
import 'package:gps_camera/domain/entities/settings/setting_filename.dart';
import 'package:gps_camera/domain/entities/settings/setting_filename_body.dart';
import 'package:localization/localization.dart';

class CustomFileNamePage extends StatefulWidget {
  const CustomFileNamePage({Key? key}) : super(key: key);

  @override
  State<CustomFileNamePage> createState() => _CustomFileNamePageState();
}

class _CustomFileNamePageState extends State<CustomFileNamePage> {
  final TextEditingController _fileNameController = TextEditingController();
  List<String> _placeholder = [];

  SettingFilename _menu = SettingFilename(list: []);

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final item = _menu.list.removeAt(oldIndex);
      _menu.list.insert(newIndex, item);
    });
  }

  void _handleUpdateDateTime() {
    setState(() {
      _placeholder = [];

      for (final data in _menu.list) {
        if (data.isSelected) {
          if (data.body is String) {
            if (data.isSelected) {
              _placeholder.add(data.body!);
            }
          } else if (data.body is List<SettingFilenameBody>) {
            for (final item in data.body) {
              if (item.isSelected) {
                if (item.key == "h") {
                  _placeholder[1] = item.body;
                } else {
                  _placeholder.add(item.body);
                }
              }
            }
          }
        }
      }

      _fileNameController.text = '${_placeholder.join('_')}.jpg';
    });
  }

  @override
  void initState() {
    AppSettings.getDefaultFilename(exportAs: String).then((value) {
      _fileNameController.text = value;

      AppSettings.getDefaultFilename(exportAs: SettingFilename).then((value) {
        _menu = value as SettingFilename;

        setState(() {});
      }).onError((error, stackTrace) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(msg: error.toString());
        return;
      });
    }).onError((error, stackTrace) {
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg: error.toString());
      return;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        AppSettings.setDefaultFilename(
            setting: _menu, dateTime: DateTime.now());

        Navigator.of(context).pop(_menu);

        return Future.value(true);
      },
      child: AnnotatedRegion(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarDividerColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              'custom-file-text'.i18n(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(left: 20, top: 20, right: 20),
                  child: TextField(
                    style: Theme.of(context).textTheme.bodyMedium,
                    controller: _fileNameController,
                    maxLines: 5,
                    enabled: false,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 20, top: 20, right: 20),
                    child: ReorderableListView.builder(
                      onReorder: _handleReorder,
                      itemCount: _menu.list.length,
                      itemBuilder: (context, index) => ExpansionPanelWidget(
                        key: ValueKey(_menu.list.elementAt(index).key),
                        title: _menu.list.elementAt(index).header,
                        isSelected: _menu.list.elementAt(index).isSelected,
                        isPremium: _menu.list.elementAt(index).isPremium,
                        onChanged: (value) {
                          setState(() {
                            _menu.list.elementAt(index).isSelected =
                                !_menu.list.elementAt(index).isSelected;
                          });

                          _handleUpdateDateTime();
                        },
                        body: _menu.list.elementAt(index).body is String
                            ? TextField(
                                style: Theme.of(context).textTheme.bodyMedium,
                                controller: TextEditingController(
                                    text: _menu.list.elementAt(index).body),
                                enabled: !_menu.list.elementAt(index).isPremium,
                              )
                            : Wrap(
                                spacing: 5,
                                children: <Widget>[
                                  for (final item
                                      in _menu.list.elementAt(index).body)
                                    FilterChip(
                                      selected: item.isSelected,
                                      backgroundColor: Colors.yellow[700],
                                      selectedColor:
                                          Colors.yellow[700]?.withOpacity(0.5),
                                      label: Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      onSelected:
                                          item.key != "dt" && item.key != "hms"
                                              ? (value) {
                                                  setState(() {
                                                    item.isSelected = value;
                                                  });

                                                  _handleUpdateDateTime();
                                                }
                                              : null,
                                    )
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
