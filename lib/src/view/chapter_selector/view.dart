import 'package:animated_glitch/animated_glitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/providers/index_provider.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/assets.dart';
import 'package:ninja_scrolls/src/static/colors.dart';
import 'package:ninja_scrolls/src/transitions/path_animation.dart';
import 'package:ninja_scrolls/src/view/components/episode_selector/build_chapter.dart';
import 'package:provider/provider.dart';

class ChapterSelectorView extends HookWidget {
  const ChapterSelectorView({super.key});

  Widget buildLabel(BuildContext context, String label) {
    final rem = context.textTheme.headlineLarge!.fontSize!;
    final textStyle = GoogleFonts.rubikGlitch(
      color: Common.white,
      fontSize: rem * 3,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 1),
      child: AnimatedGlitch.shader(
          speed: randomIntWithRange(30, 80).toDouble(),
          child: Container(
            height: rem * 5,
            width: context.screenWidth,
            color: Common.black,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                SizedBox(
                  height: rem * 5,
                  width: context.screenWidth,
                  child: Image.asset(Assets.bannersNinjaslayerLogo,
                      fit: BoxFit.fill),
                ),
                Container(color: Common.black.withOpacity(0.5)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Divider(
                      color: Common.white,
                      thickness: 2,
                      height: 0,
                    ),
                    Text(label, style: textStyle),
                    Divider(
                      color: Common.white,
                      thickness: 2,
                      height: 0,
                    ),
                  ],
                ),
              ],
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = context.watch<IndexProvider>().index;
    final scrollContrller = useScrollController();

    return Scaffold(
      backgroundColor: context.colorTheme.background,
      body: SafeArea(
          child: (index == null)
              ? Center(child: CircularProgressIndicator.adaptive())
              : RefreshIndicator.adaptive(
                  onRefresh: () async {
                    // nothing to do
                  },
                  child: Scrollbar(
                    controller: scrollContrller,
                    child: SingleChildScrollView(
                      controller: scrollContrller,
                      child: Column(children: [
                        buildLabel(context, 'TRILOGY'),
                        buildChapter(context, index.trilogy[0]),
                        buildChapter(context, index.trilogy[1]),
                        buildChapter(context, index.trilogy[2]),
                        buildLabel(context, 'AoM'),
                        ...index.aom.map(
                            (Chapter chapter) => buildChapter(context, chapter))
                      ]),
                    ),
                  ),
                )),
    );
  }
}
