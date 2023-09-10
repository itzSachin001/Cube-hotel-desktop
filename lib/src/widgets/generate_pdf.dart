import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
import 'package:shopos/src/models/input/order_input.dart';
import 'package:shopos/src/models/user.dart';
import 'package:shopos/src/pages/checkout.dart';

Future<void> generatePdf({
  required String fileName,
  required String date,
  required String companyName,
  required OrderInput orderInput,
  required User user,
  String? totalPrice,
  required String gstType,
  required OrderType orderType,
  String? subtotal,
  String? gstTotal,
  String? invoiceNum,
}) async {
  final pdf = pw.Document();

  List<String> address = user.address.toString().split(',');

  final List<pw.Row> tableRows = [];

  for (var data in orderInput.orderItems!) {
    double basePrice = 0.0;
    String gstrate = '';

    if (gstType == 'WithoutGST') {
      if (orderType == OrderType.sale) {
        basePrice = data.product!.sellingPrice!;
      } else {
        basePrice = data.product!.purchasePrice.toDouble();
      }
    } else {
      if (orderType == OrderType.sale) {
        if (data.product!.gstRate == "null") {
          basePrice = data.product!.sellingPrice!.toDouble();
          gstrate = "NA";
        } else {
          basePrice = double.parse(data.product!.baseSellingPriceGst!);
          gstrate = data.product!.gstRate!;
        }
      } else {
        if (data.product!.gstRate == "null" &&
            data.product!.purchasePrice != 0) {
          basePrice = data.product!.purchasePrice.toDouble();
          gstrate = "NA";
        } else if (data.product!.gstRate == "null" &&
            data.product!.purchasePrice == 0) {
          basePrice = 0;
          gstrate = "NA";
        } else if (data.product!.gstRate != "null" &&
            data.product!.purchasePrice != 0) {
          basePrice = double.parse(data.product!.basePurchasePriceGst!);
          gstrate = data.product!.gstRate!;
        } else {
          basePrice = 0;
          gstrate = data.product!.gstRate!;
        }
      }
    }

    final tableRow = pw.Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          data.product!.name.toString(),
        ),
        pw.Text(data.quantity.toString(), textAlign: TextAlign.right),
        pw.Text('$basePrice'),
        gstType == 'WithoutGST'
            ? Container()
            : (data.product!.gstRate == 'null'
                ? pw.Text('NA')
                : pw.Text(data.product!.saleigst!)),
        orderType == OrderType.sale
            ? pw.Text('${(data.quantity) * (data.product?.sellingPrice ?? 0)}')
            : pw.Text(
                '${(data.quantity) * (data.product?.purchasePrice ?? 0)}'),
      ],
    );
    tableRows.add(tableRow);
  }

  final pw.Column table = pw.Column(
    children: tableRows,
  );

  final font = await rootBundle.load('assets/OpenSans-Regular.ttf');
  final ttf = await Font.ttf(font);

  pdf.addPage(
    pw.Page(build: (pw.Context context) {
      return pw.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Invoice($invoiceNum)', style: TextStyle(font: ttf)),
          pw.Text('Date: ${date.substring(0, 10)}',
              style: TextStyle(font: ttf)),
        ]),
        pw.Divider(
          height: 10,
        ),
        pw.SizedBox(height: 10),
        pw.Text('From: ',
            style: TextStyle(
              font: ttf,
            )),
        pw.SizedBox(height: 10),
        pw.Text('$companyName',
            style: TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
        pw.Text('${address[0].replaceAll('{', '')}',
            style: TextStyle(font: ttf)),
        pw.Text('${address[1].replaceAll(' ', '')}',
            style: TextStyle(font: ttf)),
        pw.Text('${address[2].replaceAll(' ', '')}',
            style: TextStyle(font: ttf)),
        pw.Text('${address[3].replaceAll('}', '').replaceAll(' ', '')}',
            style: TextStyle(font: ttf)),
        pw.Text('Email: ${user.email}', style: TextStyle(font: ttf)),
        pw.Text('Phone: ${user.phoneNumber}', style: TextStyle(font: ttf)),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          pw.Text('Name'),
          pw.Text('Qty'),
          pw.Text('Rate/Unit'),
          gstType == 'WithoutGST' ? Container() : pw.Text('GST/Unit'),
          pw.Text('Amount')
        ]),

        // pw.Table(children: [
        //   pw.TableRow(children: [
        //     pw.Text('Name', style: TextStyle(font: ttf)),
        //     pw.Text('Qty', style: TextStyle(font: ttf)),
        //     pw.Text('Rate/Unit', style: TextStyle(font: ttf)),
        //     pw.Text('GST/Unit', style: TextStyle(font: ttf)),
        //     pw.Text('Amount', style: TextStyle(font: ttf)),
        //   ]),

        // ]),

        table,

        // table,

        pw.SizedBox(height: 20),

        subtotal == null || subtotal == ''
            ? Container()
            : pw.Row(children: [
                pw.Text('Sub Total: ',
                    style:
                        TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                pw.Text('$subtotal', style: TextStyle(font: ttf))
              ]),

        gstTotal == null || gstTotal == ''
            ? Container()
            : pw.Row(children: [
                pw.Text('GST Total: ',
                    style:
                        TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                pw.Text('$gstTotal', style: TextStyle(font: ttf))
              ]),

        pw.Row(children: [
          pw.Text('Net Total: ',
              style: TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
          totalPrice == null || totalPrice == ''
              ? pw.Text('0.0')
              : pw.Text('$totalPrice', style: TextStyle(font: ttf))
        ]),

        // pw.Text(' 100.0', style: TextStyle(font: ttf)),
        // pw.Text('GST Total: 0.00', style: TextStyle(font: ttf)),
        // pw.Text('Net Total: 100.0', style: TextStyle(font: ttf)),

        pw.SizedBox(height: 10),
        pw.Divider(height: 10),

        pw.SizedBox(height: 20),
        pw.Center(
            child: pw.Text('Thank you for your business',
                style: TextStyle(font: ttf))),
      ]);
    }),
  );

  print('ruuning');

  // Save PDF to a file
  final file = File(fileName);
  await file.writeAsBytes(await pdf.save());

  print('pdf save');

  await OpenAppFile.open(
    file.path,
    mimeType: 'application/pdf',
  );

  // final pdfController =
  //     PdfController(document: PdfDocument.openFile(file.path));

  // Widget pdfView() => PdfView(
  //       controller: pdfController,
  //     );

  // if (await file.exists()) {
  //   final filePath = file.path;

  // final uri = Uri.file(filePath);
  print('launching');

  // if (await canLaunch(filePath)) {
  //   await launch(filePath);
  //   print('launch');
  // } else {
  //   // handle the case when file would not be opened.
  // }
  // }
}
