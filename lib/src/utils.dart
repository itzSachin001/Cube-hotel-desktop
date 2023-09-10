import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Utils {
  const Utils();

  ///
  static bool isValidPhoneNumber(String? phoneNumber) {
    if ((phoneNumber ?? "").isEmpty) {
      return false;
    }
    if (phoneNumber?.length != 10) {
      return false;
    }
    return true;
  }

  static void showSnackBar(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  /// Check for app updates
  // Future<void> checkUpdates() async {
  //   final update = await InAppUpdate.checkForUpdate();
  //   if (update.updateAvailability < 0) {
  //     return;
  //   }
  //   if (update.immediateUpdateAllowed) {
  //     await InAppUpdate.startFlexibleUpdate();
  //     await InAppUpdate.completeFlexibleUpdate();
  //     return;
  //   }
  //   await InAppUpdate.performImmediateUpdate();
  // }
}
