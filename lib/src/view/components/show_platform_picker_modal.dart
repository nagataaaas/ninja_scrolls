import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/navkey.dart';

Future<T?> showPlatformPicker<T>(
    List<T> items, T initialLabel, Map<T, String> labelByItem) async {
  if (Platform.isIOS || Platform.isMacOS) {
    return showCupertinoPicker(items, initialLabel, labelByItem);
  } else {
    return showMaterialPicker(items, initialLabel, labelByItem);
  }
}

Future<T?> showCupertinoPicker<T>(
    List<T> items, T initialLabel, Map<T, String> labelByItem) async {
  T? result = initialLabel;
  int initialIndex = items.indexOf(initialLabel ?? items.first);

  result = await showCupertinoModalPopup<T?>(
    context: rootNavigatorKey.currentContext!,
    builder: (context) {
      return SizedBox(
        height: 300,
        child: Stack(
          children: [
            CupertinoPicker(
              backgroundColor: context.colorTheme.background,
              scrollController:
                  FixedExtentScrollController(initialItem: initialIndex),
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                result = items[index];
              },
              children: items
                  .map((e) => SizedBox(
                      width: context.screenWidth * 0.9,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Center(child: Text(labelByItem[items]!)),
                      )))
                  .toList(),
            ),
            Row(
              children: [
                CupertinoButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('キャンセル'),
                ),
                const Spacer(),
                CupertinoButton(
                  onPressed: () {
                    Navigator.pop(context, result);
                  },
                  child: Text('選ぶ'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? initialLabel;
}

Future<T?> showMaterialPicker<T>(
    List<T> items, T initialLabel, Map<T, String> labelByItem) async {
  T result = initialLabel;
  int initialIndex = items.indexOf(initialLabel ?? items.first);

  result = await showDialog(
      context: rootNavigatorKey.currentContext!,
      builder: (context) {
        return SimpleDialog(
          children: [
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(labelByItem[items[index]]!),
                    leading: Icon(initialIndex == index
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                    onTap: () {
                      Navigator.pop(context, items[index]);
                    },
                  );
                },
              ),
            ),
          ],
        );
      });

  return result ?? initialLabel;
}
