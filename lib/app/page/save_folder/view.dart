import 'package:flutter/material.dart';
import 'package:gps_camera/app/utils/constants.dart';
import 'package:gps_camera/data/utils/app_settings.dart';
import 'package:gps_camera/domain/entities/settings/setting_photo_dir.dart';
import 'package:localization/localization.dart';

class SaveFolderPage extends StatefulWidget {
  const SaveFolderPage({Key? key}) : super(key: key);

  @override
  State<SaveFolderPage> createState() => _SaveFolderPageState();
}

class _SaveFolderPageState extends State<SaveFolderPage> {
  bool _isLoading = false;
  bool _saveOriPhotos = false;
  SettingPhotoDirs _dirs = SettingPhotoDirs(dirs: []);

  String _savePhotoPath = '';

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    _setLoading(true);

    await AppSettings.getDefaultDir().then((dirs) async {
      _dirs = dirs;
      _savePhotoPath =
          _dirs.dirs.firstWhere((element) => element.isSelected).title;

      await AppSettings.getSaveOriPhoto().then((saveOri) {
        _saveOriPhotos = saveOri;

        _setLoading(false);
      });
    });
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop([_savePhotoPath, _saveOriPhotos]);

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'choose-folder-text'.i18n(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ListTile(
                    onTap: () async {
                      _saveOriPhotos = !_saveOriPhotos;

                      await AppSettings.setSaveOriPhoto(_saveOriPhotos);

                      setState(() {});
                    },
                    title: Text(
                      'save-ori-photos-text'.i18n(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    trailing: Switch(
                      value: _saveOriPhotos,
                      activeColor: Colors.yellow[700],
                      onChanged: (value) async {
                        _saveOriPhotos = !_saveOriPhotos;

                        await AppSettings.setSaveOriPhoto(_saveOriPhotos);

                        setState(() {});
                      },
                    ),
                  ),
                  ...Iterable.generate(
                    _dirs.dirs.length,
                    (index) => ListTile(
                      onTap: () async {
                        for (var dir in _dirs.dirs) {
                          if (dir != _dirs.dirs.elementAt(index)) {
                            dir.isSelected = false;
                          } else {
                            dir.isSelected = true;
                          }
                        }

                        await AppSettings.setDefaultDir(newDirs: _dirs)
                            .then((value) {
                          setState(() {
                            _savePhotoPath = _dirs.dirs
                                .firstWhere((element) => element.isSelected)
                                .title;
                          });
                        });
                      },
                      leading: Icon(
                        Icons.folder,
                        size: 36,
                        color: Colors.yellow[700],
                      ),
                      title: Text(
                        _dirs.dirs.elementAt(index).title,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        _dirs.dirs.elementAt(index).dirPath,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: _dirs.dirs.elementAt(index).isSelected
                          ? Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.yellow[700],
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              _isLoading ? showLoading(context) : const Center(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: null,
          backgroundColor: Colors.yellow[700],
          foregroundColor: Colors.white,
          child: const Icon(
            Icons.add,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
