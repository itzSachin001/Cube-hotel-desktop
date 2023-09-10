// import 'package:flutter/material.dart';
// import 'package:webview_universal/webview_universal.dart';

// class ShowPdfScreen extends StatefulWidget {
//   static const routeName = '/show-pdf';
//   const ShowPdfScreen({
//     Key? key,
//     required this.htmlContent,
//   }) : super(key: key);

//   final String htmlContent;

//   @override
//   State<ShowPdfScreen> createState() => _ShowPdfScreenState();
// }

// class _ShowPdfScreenState extends State<ShowPdfScreen> {
//   WebViewController controller = WebViewController();

//   @override
//   void initState() {
//     super.initState();
//     task();
//   }

//   // final String htmlContent = '''
//   //   <!DOCTYPE html>
//   //   <html>
//   //   <head>
//   //     <title>HTML Content</title>
//   //   </head>
//   //   <body>
//   //     <h1>Hello, World!</h1>
//   //     <p>This is HTML content displayed in a WebView.</p>
//   //   </body>
//   //   </html>
//   // ''';

//   Future<void> task() async {
//     await controller.init(
//       context: context,
//       uri: Uri.parse("data:text/html;charset=utf-8,${widget.htmlContent}"),
//       setState: (void Function() fn) {},
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//           child: WebView(
//         controller: controller,
//       )),
//     );
//   }
// }
