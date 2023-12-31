// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:
import 'package:ninja_scrolls/extentions.dart';

import './models/ja_model.dart';

class BudouX {
  static final spaceNewlineDivider = RegExp([
    r'(?=\n)|', // before newline
    r'(?<=\n)|', // after newline
    r'((?<=[^\s])(?=(\s+[^\s])))|', // before spaces
    r'((?<=\s+)(?=[^\s]))', // after spaces
  ].join());

  static List<String> _divideByNewline(List<String> texts) =>
      texts.expand((e) => e.split(spaceNewlineDivider)).toList();

  static Wrap budou(
    BuildContext context,
    String data, {
    TextStyle? style,
    WrapAlignment? alignment,
    WrapAlignment? runAlignment,
    WrapCrossAlignment? crossAxisAlignment,
    double? spacing,
    double? runSpacing,
    TextDirection? textDirection,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) =>
      budouMulti(context, [data],
          style: style,
          alignment: alignment,
          runAlignment: runAlignment,
          crossAxisAlignment: crossAxisAlignment,
          spacing: spacing,
          runSpacing: runSpacing,
          textDirection: textDirection,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor);

  static Wrap budouMulti(
    BuildContext context,
    List<String> data, {
    TextStyle? style,
    WrapAlignment? alignment,
    WrapAlignment? runAlignment,
    WrapCrossAlignment? crossAxisAlignment,
    double? spacing,
    double? runSpacing,
    TextDirection? textDirection,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) {
    final locale = context.locale;

    late final List<String> data_;
    data_ = _divideByNewline(data)
        .map((e) {
          if (e == ' ' || e == '\n') return [e];
          if (locale.languageCode == 'ja') {
            return JaModel.parse(e)
                .map((e_) => e_.split(' '))
                .expand((e_) => e_);
          }
          return e.split(RegExp(r'(?<= +)'));
        })
        .toList()
        .expand((e) => e)
        .toList();

    return Wrap(
      alignment: alignment ?? WrapAlignment.start,
      runAlignment: runAlignment ?? WrapAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? WrapCrossAlignment.start,
      spacing: spacing ?? 0.0,
      runSpacing: runSpacing ?? 0.0,
      children: data_.map((e) {
        final text = Text(e,
            style: style,
            textDirection: textDirection,
            softWrap: softWrap,
            overflow: overflow,
            textScaleFactor: textScaleFactor,
            maxLines: maxLines,
            semanticsLabel: semanticsLabel,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
            selectionColor: selectionColor);
        if (e == '\n') return Container(width: double.maxFinite);
        return text;
      }).toList(),
    );
  }
}
