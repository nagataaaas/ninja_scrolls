import 'package:flutter/material.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoView extends StatefulWidget {
  const AppInfoView({super.key});

  @override
  State<AppInfoView> createState() => _AppInfoViewState();
}

class _AppInfoViewState extends State<AppInfoView> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((value) => setState(() {
          _packageInfo = value;
        }));
  }

  Future<void> launchURL(Uri url, {Uri? secondUrl}) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (secondUrl != null && await canLaunchUrl(secondUrl)) {
      await launchUrl(secondUrl);
    } else {
      // 任意のエラー処理
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      contentPadding: EdgeInsetsDirectional.zero,
      lightTheme:
          context.watch<ThemeProvider>().lightTheme.theme.settingsThemeData,
      darkTheme:
          context.watch<ThemeProvider>().darkTheme.theme.settingsThemeData,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      sections: [
        SettingsSection(
          margin: EdgeInsetsDirectional.only(top: 16),
          title: const Text('アプリについて'),
          tiles: <SettingsTile>[
            SettingsTile(
                leading: const Icon(Icons.info),
                title: const Text('アプリバージョン'),
                value: Text(_packageInfo?.version ?? "...")),
            SettingsTile(
              leading: const Icon(Icons.message),
              title: const Text('コンタクト'),
              value: Text("アプリ製作者にコンタクト"),
              onPressed: (context) {
                launchURL(Uri.parse('twitter://user?id=2684189449'),
                    secondUrl:
                        Uri.parse('https://twitter.com/i/user/2684189449'));
              },
            )
          ],
        )
      ],
    );
  }
}
