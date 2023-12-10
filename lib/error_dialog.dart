import 'package:flutter/material.dart';

void showErrorDialog(BuildContext context,
    {String title = '', String message = ''}) {
  // set up the button
  Widget okButton = TextButton(
    child: const Text("Close"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      okButton,
    ],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
