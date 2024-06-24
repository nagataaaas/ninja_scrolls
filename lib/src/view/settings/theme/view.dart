import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/entities/user_settings.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/view/components/show_platform_picker_modal.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsThemeView extends StatefulWidget {
  const SettingsThemeView({super.key});

  @override
  State<SettingsThemeView> createState() => _SettingsThemeViewState();
}

class _SettingsThemeViewState extends State<SettingsThemeView> {
  @override
  Widget build(BuildContext context) {
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
            margin: EdgeInsetsDirectional.zero,
            title: Text('明るさの選択'),
            tiles: <SettingsTile>[
              SettingsTile(
                trailing: null,
                leading: Icon(AdaptiveTheme.of(context).mode.isSystem
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
                title: Text('OS設定に従う'),
                value: Text('ダーク/ライト'),
                onPressed: (value) {
                  if (AdaptiveTheme.of(context).mode.isSystem) return;
                  AdaptiveTheme.of(context).setSystem();
                  context.read<UserSettingsProvider>().themeType =
                      ThemeType.auto;
                },
              ),
              SettingsTile(
                trailing: null,
                leading: Icon(AdaptiveTheme.of(context).mode.isLight
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
                title: Text('ライト'),
                onPressed: (value) {
                  if (AdaptiveTheme.of(context).mode.isLight) return;
                  AdaptiveTheme.of(context).setLight();
                  context.read<UserSettingsProvider>().themeType =
                      ThemeType.light;
                },
              ),
              SettingsTile(
                trailing: null,
                leading: Icon(AdaptiveTheme.of(context).mode.isDark
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
                title: Text('ダーク'),
                onPressed: (value) {
                  if (AdaptiveTheme.of(context).mode.isDark) return;
                  AdaptiveTheme.of(context).setDark();
                  context.read<UserSettingsProvider>().themeType =
                      ThemeType.dark;
                },
              ),
            ],
          ),
          SettingsSection(
            margin: EdgeInsetsDirectional.only(top: 16),
            title: Text('テーマ選択'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.format_paint_outlined),
                title: Text('ライトテーマ'),
                value: Text(context.watch<ThemeProvider>().lightTheme.name),
                onPressed: (context) async {
                  final result = await showPlatformPicker<LightTheme>(
                    LightTheme.values,
                    context.read<ThemeProvider>().lightTheme,
                    Map.fromIterables(
                      LightTheme.values,
                      LightTheme.values.map((e) => e.name),
                    ),
                  );
                  if (result != null &&
                      mounted &&
                      context.read<ThemeProvider>().lightTheme != result) {
                    context.read<ThemeProvider>().lightTheme = result;
                    final userSettingsProvider =
                        context.read<UserSettingsProvider>();
                    userSettingsProvider.lightTheme = result;
                    AdaptiveTheme.of(context).setTheme(
                      light: userSettingsProvider.lightTheme.theme,
                      dark: userSettingsProvider.darkTheme.theme,
                    );
                  }
                },
              ),
              SettingsTile.navigation(
                leading: Icon(Icons.format_paint_outlined),
                title: Text('ダークテーマ'),
                value: Text(context.watch<ThemeProvider>().darkTheme.name),
                onPressed: (context) async {
                  final result = await showPlatformPicker<DarkTheme>(
                    DarkTheme.values,
                    context.read<ThemeProvider>().darkTheme,
                    Map.fromIterables(
                      DarkTheme.values,
                      DarkTheme.values.map((e) => e.name),
                    ),
                  );
                  if (result != null &&
                      mounted &&
                      context.read<ThemeProvider>().darkTheme != result) {
                    context.read<ThemeProvider>().darkTheme = result;
                    final userSettingsProvider =
                        context.read<UserSettingsProvider>();
                    userSettingsProvider.darkTheme = result;
                    AdaptiveTheme.of(context).setTheme(
                      light: userSettingsProvider.lightTheme.theme,
                      dark: userSettingsProvider.darkTheme.theme,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      )),
    );
  }
}
