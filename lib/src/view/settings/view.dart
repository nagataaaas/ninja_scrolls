import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ninja_scrolls/budoux/budoux.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/view/settings/components/app_info/view.dart';
import 'package:ninja_scrolls/src/view/settings/components/data/view.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
          child: SafeArea(
            child: ListView(
              controller: scrollController,
              children: [
                SettingsList(
                  platform: DevicePlatform.android,
                  contentPadding: EdgeInsetsDirectional.zero,
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
                      margin: EdgeInsetsDirectional.only(top: 32),
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
                          value: Text({
                            null: 'OS設定に従う',
                            true: 'する',
                            false: 'しない'
                          }[context
                              .watch<UserSettingsProvider>()
                              .rawRichAnimationEnabled]!),
                          onPressed: (context) {
                            GoRouter.of(context)
                                .go(Routes.settingAnimationRoute);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SettingsDataView(),
                AppInfoView(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ⓒ 2024-2026 nagataaaas',
                    style: context.textTheme.bodySmall,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: BudouX.budou(
                    context,
                    '※本アプリケーションで提供する 各物語部の画像・アイキャッチ画像・タイトル・本文等は ダイハードテイルズ出版局( 𝕏[旧Twitter]: @njslyr または @dhtls ) が著作・権利を保有するものです。',
                    style: context.textTheme.bodySmall,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: BudouX.budou(
                    context,
                    '※本アプリケーション内から閲覧できる ニンジャスレイヤー Wiki は有志により運営されているものであり、本アプリの著作者は権利を有していません。',
                    style: context.textTheme.bodySmall,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () {
                      launchUrl(
                        Uri.https(
                            'app.nagata.pro', '/ninja-scrolls/privacy-policy'),
                        mode: LaunchMode.inAppBrowserView,
                      );
                    },
                    child: BudouX.budou(
                      context,
                      'プライバシーポリシーはこちらからご確認ください。',
                      style: context.textTheme.bodySmall!.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
