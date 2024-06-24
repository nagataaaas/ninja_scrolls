import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsAnimationView extends StatefulWidget {
  const SettingsAnimationView({super.key});

  @override
  State<SettingsAnimationView> createState() => _SettingsAnimationViewState();
}

class _SettingsAnimationViewState extends State<SettingsAnimationView> {
  @override
  Widget build(BuildContext context) {
    final rawRichAnimationEnabled =
        context.watch<UserSettingsProvider>().rawRichAnimationEnabled;

    return Scaffold(
      body: SafeArea(
          child: SettingsList(
        lightTheme:
            context.watch<ThemeProvider>().lightTheme.theme.settingsThemeData,
        darkTheme:
            context.watch<ThemeProvider>().darkTheme.theme.settingsThemeData,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        sections: [
          SettingsSection(
            title: Text('アニメーション'),
            tiles: <SettingsTile>[
              SettingsTile(
                trailing: null,
                leading: Icon(rawRichAnimationEnabled == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
                title: Text('OS設定に従う'),
                description: Text(Platform.isAndroid
                    ? '設定 > ユーザ補助 > 色と動き > 動きの低減'
                    : Platform.isIOS
                        ? '設定 > アクセシビリティ > 動作 > 視差効果を減らす'
                        : '設定アプリなどから設定してください'),
                onPressed: (value) {
                  context.read<UserSettingsProvider>().richAnimationEnabled =
                      null;
                },
              ),
              SettingsTile(
                trailing: null,
                leading: Icon(rawRichAnimationEnabled == true
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
                title: Text('する'),
                onPressed: (value) {
                  context.read<UserSettingsProvider>().richAnimationEnabled =
                      true;
                },
              ),
              SettingsTile(
                trailing: null,
                leading: Icon(rawRichAnimationEnabled == false
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
                title: Text('しない'),
                onPressed: (value) {
                  context.read<UserSettingsProvider>().richAnimationEnabled =
                      false;
                },
              ),
            ],
          ),
        ],
      )),
    );
  }
}
