import 'package:flutter_platform_alert/flutter_platform_alert.dart';

Future<bool> showPlatformConfirmAlert(String title, String text) async {
  return await FlutterPlatformAlert.showAlert(
          windowTitle: title,
          text: text,
          alertStyle: AlertButtonStyle.okCancel) ==
      AlertButton.okButton;
}
