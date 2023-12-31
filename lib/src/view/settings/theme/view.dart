import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsThemeView extends StatelessWidget {
  const SettingsThemeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: SettingsList(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        sections: [
          SettingsSection(
            tiles: <SettingsTile>[
              SettingsTile(
                trailing: null,
                leading: Icon(AdaptiveTheme.of(context).mode.isSystem
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank),
                title: Text('OS設定に従う'),
                onPressed: (value) {
                  if (AdaptiveTheme.of(context).mode.isSystem) return;
                  AdaptiveTheme.of(context).setSystem();
                  GoRouter.of(context).pop();
                },
              ),
              SettingsTile(
                trailing: null,
                leading: Icon(AdaptiveTheme.of(context).mode.isLight
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank),
                title: Text('ライト'),
                onPressed: (value) {
                  if (AdaptiveTheme.of(context).mode.isLight) return;
                  AdaptiveTheme.of(context).setLight();
                  GoRouter.of(context).pop();
                },
              ),
              SettingsTile(
                trailing: null,
                leading: Icon(AdaptiveTheme.of(context).mode.isDark
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank),
                title: Text('ダーク'),
                onPressed: (value) {
                  if (AdaptiveTheme.of(context).mode.isDark) return;
                  AdaptiveTheme.of(context).setDark();
                  GoRouter.of(context).pop();
                },
              ),
            ],
          ),
        ],
      )),
    );
  }
}
