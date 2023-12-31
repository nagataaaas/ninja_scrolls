import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/view/settings/components/app_version/view.dart';
import 'package:ninja_scrolls/src/view/settings/components/data/view.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _richAnimationEnabled = true;
  @override
  void initState() {
    super.initState();
    _richAnimationEnabled =
        context.read<UserSettingsProvider>().richAnimationEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: () async => setState(() {}),
        child: Scrollbar(
          child: ListView(
            children: [
              SettingsList(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                sections: [
                  SettingsSection(
                    title: Text('視覚設定'),
                    tiles: <SettingsTile>[
                      SettingsTile.navigation(
                        leading: Icon(Icons.contrast),
                        title: Text('テーマ'),
                        value: Text({
                          AdaptiveThemeMode.light: 'ライト',
                          AdaptiveThemeMode.system: 'OS設定に従う',
                          AdaptiveThemeMode.dark: 'ダーク'
                        }[AdaptiveTheme.of(context).mode]!),
                        onPressed: (context) {
                          GoRouter.of(context).go(Routes.settingThemeRoute);
                        },
                      ),
                      SettingsTile.switchTile(
                        onToggle: (value) {
                          setState(() {
                            _richAnimationEnabled = value;
                          });
                          context
                              .read<UserSettingsProvider>()
                              .richAnimationEnabled = value;
                        },
                        initialValue: _richAnimationEnabled,
                        leading: Icon(Icons.animation),
                        title: Text('リッチアニメーション'),
                      ),
                    ],
                  ),
                ],
              ),
              SettingsDataView(),
              AppVersionView(),
            ],
          ),
        ),
      ),
    );
  }
}
