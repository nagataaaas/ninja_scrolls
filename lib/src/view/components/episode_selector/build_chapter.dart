import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:provider/provider.dart';

Widget buildChapter(BuildContext context, Chapter chapter,
    [bool ignoreTap = false]) {
  final rem = context.textTheme.headlineLarge!.fontSize!;
  final textStyle = GoogleFonts.rampartOne(
    color: context.colorTheme.primary,
    fontSize: rem * 1.4,
  );
  final child = Column(
    children: [
      SizedBox(
        height: rem * 6,
        width: context.screenWidth,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRect(
              child: SizedBox(
                height: rem * 6,
                width: context.screenWidth,
                child: ImageFiltered(
                    // enabled: false,
                    imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Image.asset(chapter.imagePath, fit: BoxFit.cover)),
              ),
            ),
            SizedBox(
              height: rem * 6,
              width: context.screenWidth,
              child: Image.asset(chapter.imagePath, fit: BoxFit.contain),
            ),
            Container(color: context.colorTheme.background.withOpacity(0.8)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: rem / 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(chapter.title.split('：').first,
                          textScaleFactor: 1,
                          style: textStyle.copyWith(
                              fontSize: textStyle.fontSize! * 0.9)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        textScaleFactor: 1,
                        chapter.title.split('：')[1].trim(),
                        textAlign: TextAlign.right,
                        style: textStyle,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Divider(
          color: context.colorTheme.primary.withOpacity(0.3),
          thickness: 1,
          height: 0),
    ],
  );

  return GestureDetector(
    onTap: () {
      if (ignoreTap) return;
      GoRouter.of(context).goNamed(Routes.toName(Routes.chaptersEpisodesRoute),
          pathParameters: {'chapterId': chapter.id.toString()});
    },
    child:
        context.watch<UserSettingsProvider>().getRichAnimationEnabled(context)
            ? Hero(
                transitionOnUserGestures: true,
                tag: chapter.title,
                child: child,
              )
            : child,
  );
}
