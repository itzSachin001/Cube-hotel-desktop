import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils.dart';

void httpErrorHandle(
    {required http.Response response,
    required BuildContext context,
    required VoidCallback onSuccess}) {
  switch (response.statusCode) {
    case 200:
      onSuccess();
      break;
    case 201:
      onSuccess();
      break;
    case 400:
      Utils.showSnackBar(jsonDecode(response.body)['message']);
      break;
    case 500:
      Utils.showSnackBar(jsonDecode(response.body)['error']);
      break;
    default:
      Utils.showSnackBar(response.body);
  }
}
