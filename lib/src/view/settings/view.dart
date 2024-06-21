import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/view/settings/components/app_info/view.dart';
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
  late final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _richAnimationEnabled =
        context.read<UserSettingsProvider>().getRichAnimationEnabled(context);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: () async => setState(() {}),
        child: Scrollbar(
          controller: scrollController,
          child: ListView(
            controller: scrollController,
            children: [
              SettingsList(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                lightTheme: context
                    .watch<ThemeProvider>()
                    .lightTheme
                    .theme
                    .settingsThemeData,
                darkTheme: context
                    .watch<ThemeProvider>()
                    .darkTheme
                    .theme
                    .settingsThemeData,
                sections: [
                  SettingsSection(
                    title: Text('視覚設定'),
                    tiles: <SettingsTile>[
                      SettingsTile.navigation(
                        leading: Icon(Icons.contrast),
                        title: Text('テーマ'),
                        value: Text({
                          AdaptiveThemeMode.system: 'OS設定に従う',
                          AdaptiveThemeMode.light:
                              'ライト (${context.watch<ThemeProvider>().lightTheme.name})',
                          AdaptiveThemeMode.dark:
                              'ダーク (${context.watch<ThemeProvider>().darkTheme.name})'
                        }[AdaptiveTheme.of(context).mode]!),
                        onPressed: (context) {
                          GoRouter.of(context).go(Routes.settingThemeRoute);
                        },
                      ),
                      SettingsTile.navigation(
                        leading: Icon(Icons.animation),
                        title: Text('リッチアニメーション'),
                        value: Text({null: 'OS設定に従う', true: 'する', false: 'しない'}[
                            context
                                .watch<UserSettingsProvider>()
                                .rawRichAnimationEnabled]!),
                        onPressed: (context) {
                          GoRouter.of(context).go(Routes.settingAnimationRoute);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SettingsDataView(),
              AppInfoView(),
            ],
          ),
        ),
      ),
    );
  }
}
