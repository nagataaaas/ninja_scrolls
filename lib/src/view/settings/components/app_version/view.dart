import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:settings_ui/settings_ui.dart';

class AppVersionView extends StatefulWidget {
  const AppVersionView({super.key});

  @override
  State<AppVersionView> createState() => _AppVersionViewState();
}

class _AppVersionViewState extends State<AppVersionView> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((value) => setState(() {
          _packageInfo = value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      sections: [
        SettingsSection(
          title: const Text('アプリについて'),
          tiles: <SettingsTile>[
            SettingsTile(
                leading: const Icon(Icons.info),
                title: const Text('アプリバージョン'),
                value: Text(_packageInfo?.version ?? "..."))
          ],
        )
      ],
    );
  }
}
