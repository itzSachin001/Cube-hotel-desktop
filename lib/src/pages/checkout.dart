import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:ntp/ntp.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shopos/src/blocs/checkout/checkout_cubit.dart';
import 'package:shopos/src/config/colors.dart';
import 'package:shopos/src/models/input/order_input.dart';
import 'package:shopos/src/models/user.dart';
import 'package:shopos/src/pages/create_party.dart';
import 'package:shopos/src/services/global.dart';
import 'package:shopos/src/services/locator.dart';
import 'package:shopos/src/services/order_services.dart';
import 'package:shopos/src/services/party.dart';
import 'package:shopos/src/services/user.dart';
import 'package:shopos/src/widgets/custom_button.dart';
import 'package:shopos/src/widgets/custom_drop_down.dart';
import 'package:shopos/src/widgets/generate_pdf.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/party.dart';

enum OrderType { purchase, sale }

class CheckoutPageArgs {
  final OrderType invoiceType;
  final OrderInput orderInput;
  const CheckoutPageArgs({
    required this.invoiceType,
    required this.orderInput,
  });
}

class CheckoutPage extends StatefulWidget {
  final CheckoutPageArgs args;
  static const routeName = '/checkout';
  const CheckoutPage({
    Key? key,
    required this.args,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late CheckoutCubit _checkoutCubit;
  late final TextEditingController _typeAheadController;

  String? date;

  ///
  @override
  void initState() {
    super.initState();
    _checkoutCubit = CheckoutCubit();
    _typeAheadController = TextEditingController();
    fetchNTPTime();
  }

  Future<void> fetchNTPTime() async {
    DateTime currentTime;

    try {
      currentTime = await NTP.now();
    } catch (e) {
      currentTime = DateTime.now();
    }

    String day;
    String month;
    String hour;
    String minute;
    String second;

    // for day 0-9
    if (currentTime.day < 10) {
      day = '0${currentTime.day}';
    } else {
      day = '${currentTime.day}';
    }

    // for month 0-9
    if (currentTime.month < 10) {
      month = '0${currentTime.month}';
    } else {
      month = '${currentTime.month}';
    }

    // for hour 0-9
    if (currentTime.hour < 10) {
      hour = '0${currentTime.hour}';
    } else {
      hour = '${currentTime.hour}';
    }

    // for minute
    if (currentTime.minute < 10) {
      minute = '0${currentTime.minute}';
    } else {
      minute = '${currentTime.minute}';
    }

    // for seconds 0-9
    if (currentTime.second < 10) {
      second = '0${currentTime.second}';
    } else {
      second = '${currentTime.second}';
    }

    date = '${day}${month}${currentTime.year}${hour}${minute}${second}';
  }

  @override
  void dispose() {
    _checkoutCubit.close();
    _typeAheadController.dispose();
    super.dispose();
  }

  ///
  openShareModal(context, user) {
    Alert(
        style: const AlertStyle(
          animationType: AnimationType.grow,
          isButtonVisible: false,
        ),
        context: context,
        title: "Share Invoice",
        content: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            ListTile(
              title: const Text("Open Pdf"),
              onTap: () {
                _onTapShare(0);
              },
            ),
            // ListTile(
            //   title: const Text("Without GST"),
            //   onTap: () {
            //     _onTapShare(1);
            //   },
            // ),
            ListTile(
                title: const Text("Whatsapp Message"),
                onTap: () {
                  TextEditingController t = TextEditingController();
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            backgroundColor: Colors.white,
                            title: Column(children: [
                              Text(
                                "Enter Whatsapp numer\n(10-digit number only)",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Poppins-Regular",
                                    color: Colors.black),
                              )
                            ]),
                            content: TextField(
                                autofocus: true,
                                controller: t,
                                decoration: InputDecoration(
                                  hintText: "Enter 10-digit number",
                                  enabledBorder: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(),
                                ),
                                onSubmitted: (val) {
                                  if (int.tryParse(val.trim()) != null &&
                                      val.trim().length == 10)
                                    _launchUrl(
                                        val.trim(),
                                        user,
                                        widget.args.orderInput.modeOfPayment,
                                        totalbasePrice(),
                                        totalgstPrice(),
                                        "0.0",
                                        widget.args.orderInput.orderItems);
                                }),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    if (int.tryParse(t.text.trim()) != null &&
                                        t.text.length == 10)
                                      _launchUrl(
                                          t.text.trim(),
                                          user,
                                          widget.args.orderInput.modeOfPayment,
                                          totalbasePrice(),
                                          totalgstPrice(),
                                          "0.0",
                                          widget.args.orderInput.orderItems);
                                  },
                                  child: Text("Yes")),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("Cancel"))
                            ],
                          ));
                })
          ],
        )).show();
  }

  ///
  void _viewPdfwithgst(User user) async {
    // final targetPath = await getExternalCacheDirectories();
    // const targetFileName = "Invoice";
    // final htmlContent = invoiceTemplatewithGST(
    //   type: widget.args.invoiceType.toString(),
    //   date: DateTime.now(),
    //   companyName: user.businessName ?? "",
    //   order: widget.args.orderInput,
    //   user: user,
    //   headers: ["Name", "Qty", "Rate/Unit", "GST/Unit", "Amount"],
    //   total: totalPrice() ?? "",
    //   subtotal: totalbasePrice() ?? "",
    //   gsttotal: totalgstPrice() ?? "",
    // );

    // Navigator.of(context)
    //     .pushNamed(ShowPdfScreen.routeName, arguments: htmlContent);

    DateTime time = DateTime.now();

    await OrderServices.pdf(
      orderInput: widget.args.orderInput,
      invoiceNum: date ?? DateTime.now().toIso8601String(),
      address: user.address!,
      companyName: user.businessName ?? '',
      email: user.email ?? '',
      phoneNo: user.phoneNumber!,
      date: '${time.day}/${time.month}/${time.year}',
      reportType: widget.args.invoiceType,
    );

    // generatePdf(
    //     fileName: "Invoice",
    //     date: DateTime.now().toString(),
    //     companyName: user.businessName!,
    //     orderInput: widget.args.orderInput,
    //     user: user,
    //     totalPrice: totalPrice() ?? '',
    //     gstType: 'WithGST',
    //     orderType: widget.args.invoiceType,
    //     subtotal: totalbasePrice() ?? '',
    //     gstTotal: totalgstPrice() ?? '',
    //     invoiceNum: date);
    // final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
    //   htmlContent,
    //   targetPath!.first.path,
    //   targetFileName,
    // );
    // final input = _typeAheadController.value.text.trim();
    // if (input.length == 10 && int.tryParse(input) != null) {
    //   await WhatsappShare.shareFile(
    //     text: 'Invoice',
    //     phone: '91$input',
    //     filePath: [generatedPdfFile.path],
    //   );
    //   return;
    // }

    // final party = widget.args.orderInput.party;
    // if (party == null) {
    //   final path = generatedPdfFile.path;
    //   await Share.shareFiles([path], mimeTypes: ['application/pdf']);
    //   return;
    // }
    // final isValidPhoneNumber = Utils.isValidPhoneNumber(party.phoneNumber);
    // if (!isValidPhoneNumber) {
    //   locator<GlobalServices>()
    //       .infoSnackBar("Invalid phone number: ${party.phoneNumber ?? ""}");
    //   return;
    // }
    // await WhatsappShare.shareFile(
    //   text: 'Invoice',
    //   phone: '91${party.phoneNumber ?? ""}',
    //   filePath: [generatedPdfFile.path],
    // );
  }

  ///
  void _viewPdfwithoutgst(User user) async {
    // final targetPath = await getExternalCacheDirectories();
    // const targetFileName = "Invoice";
    // final htmlContent = invoiceTemplatewithouGST(
    //   type: widget.args.invoiceType.toString(),
    //   date: DateTime.now(),
    //   companyName: user.businessName ?? "",
    //   order: widget.args.orderInput,
    //   user: user,
    //   headers: ["Name", "Qty", "Rate/Unit", "Amount"],
    //   total: totalPrice() ?? "",
    // );

    // Navigator.of(context)
    //     .pushNamed(ShowPdfScreen.routeName, arguments: htmlContent);

    DateTime time = DateTime.now();

    await OrderServices.pdf(
        orderInput: widget.args.orderInput,
        invoiceNum: date!,
        address: user.address!,
        companyName: user.businessName ?? '',
        email: user.email ?? '',
        phoneNo: user.phoneNumber!,
        date: '${time.day}/${time.month}/${time.year}',
        reportType: widget.args.invoiceType);

    // generatePdf(
    //   fileName: "Invoice",
    //   date: DateTime.now().toString(),
    //   companyName: user.businessName!,
    //   orderInput: widget.args.orderInput,
    //   user: user,
    //   totalPrice: totalPrice() ?? '',
    //   gstType: 'WithoutGST',
    //   orderType: widget.args.invoiceType,
    //   invoiceNum: date,
    // );
    // final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
    //   htmlContent,
    //   targetPath!.first.path,
    //   targetFileName,
    // );
    // final input = _typeAheadController.value.text.trim();
    // if (input.length == 10 && int.tryParse(input) != null) {
    //   await WhatsappShare.shareFile(
    //     text: 'Invoice',
    //     phone: '91$input',
    //     filePath: [generatedPdfFile.path],
    //   );
    //   return;
    // }

    // final party = widget.args.orderInput.party;
    // if (party == null) {
    //   final path = generatedPdfFile.path;
    //   await Share.shareFiles([path], mimeTypes: ['application/pdf']);
    //   return;
    // }
    // final isValidPhoneNumber = Utils.isValidPhoneNumber(party.phoneNumber);
    // if (!isValidPhoneNumber) {
    //   locator<GlobalServices>()
    //       .infoSnackBar("Invalid phone number: ${party.phoneNumber ?? ""}");
    //   return;
    // }
    // await WhatsappShare.shareFile(
    //   text: 'Invoice',
    //   phone: '91${party.phoneNumber ?? ""}',
    //   filePath: [generatedPdfFile.path],
    // );
  }

  Future<Iterable<Party>> _searchParties(String pattern) async {
    if (pattern.isEmpty) {
      return [];
    }
    final type =
        widget.args.invoiceType == OrderType.sale ? "customer" : "supplier";

    try {
      final response =
          await const PartyService().getSearch(pattern, type: type);
      final data = response.data['allParty'] as List<dynamic>;
      return data.map((e) => Party.fromMap(e));
    } catch (err) {
      log(err.toString());
      return [];
    }
  }

  ///
  String? totalPrice() {
    return widget.args.orderInput.orderItems?.fold<double>(
      0,
      (acc, curr) {
        if (widget.args.invoiceType == OrderType.purchase) {
          return (curr.quantity * (curr.product?.purchasePrice ?? 1)) + acc;
        }
        return (double.parse(curr.quantity.toString()) *
                (curr.product?.sellingPrice ?? 1.0)) +
            acc;
      },
    ).toString();
  }

  ///
  String? totalbasePrice() {
    return widget.args.orderInput.orderItems?.fold<double>(
      0,
      (acc, curr) {
        if (widget.args.invoiceType == OrderType.purchase) {
          // return (curr.quantity * (curr.product?.purchasePrice ?? 1)) + acc;
          double sum = 0;
          if (curr.product!.basePurchasePriceGst! != "null")
            sum = double.parse(curr.product!.basePurchasePriceGst!);
          else {
            sum = curr.product!.purchasePrice.toDouble();
          }
          return (curr.quantity * sum) + acc;
        } else {
          double sum = 0;
          if (curr.product!.baseSellingPriceGst! != "null")
            sum = double.parse(curr.product!.baseSellingPriceGst!);
          else {
            sum = curr.product!.sellingPrice!.toDouble();
          }
          return (curr.quantity * sum) + acc;
        }
      },
    ).toString();
  }

  ///
  String? totalgstPrice() {
    return widget.args.orderInput.orderItems?.fold<double>(
      0,
      (acc, curr) {
        if (widget.args.invoiceType == OrderType.purchase) {
          // return (curr.quantity * (curr.product?.purchasePrice ?? 1)) + acc;
          double gstsum = 0;
          if (curr.product!.purchaseigst! != "null")
            gstsum = double.parse(curr.product!.purchaseigst!);
          // else {
          //   gstsum = curr.product!.sellingPrice;
          // }
          return double.parse(
              ((curr.quantity * gstsum) + acc).toStringAsFixed(2));
        } else {
          double gstsum = 0;
          if (curr.product!.saleigst! != "null")
            gstsum = double.parse(curr.product!.saleigst!);
          // else {
          //   gstsum = curr.product!.sellingPrice;
          // }
          return double.parse(
              ((curr.quantity * gstsum) + acc).toStringAsFixed(2));
        }
      },
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          "${widget.args.orderInput.orderItems?.fold<int>(0, (acc, item) => item.quantity + acc)} products",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Center(
              child: Text(
                "₹ ${totalPrice()}",
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<CheckoutCubit, CheckoutState>(
        bloc: _checkoutCubit,
        listener: (context, state) {
          if (state is CheckoutSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  'Order was created successfully',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
            Future.delayed(const Duration(milliseconds: 400), () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          }
        },
        child: BlocBuilder<CheckoutCubit, CheckoutState>(
          bloc: _checkoutCubit,
          builder: (context, state) {
            if (state is CheckoutLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsConst.primaryColor,
                  ),
                ),
              );
            }
            return Container(
              height: media.size.height * 1,
              width: media.size.width * 1,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  bottom: 20,
                  left: 20,
                  right: 30,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: media.size.width * 0.9,
                        //height: media.size.height * 0.9,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Card(
                              elevation: 0,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Column(
                                children: [
                                  Container(
                                    width: media.size.width * 0.4,
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Sub Total'),
                                            Text('₹ ${totalbasePrice()}'),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Tax GST'),
                                            Text('₹ ${totalgstPrice()}'),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Discount'),
                                            Text('₹ 0'),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Divider(color: Colors.black54),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Grand Total'),
                                            Text(
                                              '₹ ${totalPrice()}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                      ],
                                    ),
                                    // Divider(color: Colors.black54),
                                    // Text(
                                    //   "INVOICE",
                                    //   style: TextStyle(
                                    //       fontSize: 30, fontWeight: FontWeight.w500),
                                    // ),
                                    // Divider(color: Colors.black54),

                                    // Divider(color: Colors.black54),
                                    // const Divider(color: Colors.transparent),
                                  ),
                                ],
                              ),
                            ),
                            //const Divider(color: Colors.transparent),
                            Container(
                              height: media.size.height * 0.5,
                              width: media.size.width * 0.4,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 400,
                                    child: TypeAheadFormField<Party>(
                                      validator: (value) {
                                        final isEmpty =
                                            (value == null || value.isEmpty);
                                        final isCredit = widget.args.orderInput
                                                .modeOfPayment ==
                                            "Credit";
                                        if (isEmpty && isCredit) {
                                          return "Please select a party for credit order";
                                        }
                                        return null;
                                      },
                                      debounceDuration:
                                          const Duration(milliseconds: 500),
                                      textFieldConfiguration:
                                          TextFieldConfiguration(
                                        controller: _typeAheadController,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          hintText: "Party",
                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(context,
                                                  CreatePartyPage.routeName,
                                                  arguments:
                                                      CreatePartyArguments(
                                                    "",
                                                    "",
                                                    "",
                                                    "",
                                                    widget.args.invoiceType ==
                                                            OrderType.purchase
                                                        ? 'supplier'
                                                        : 'customer',
                                                  ));
                                            },
                                            child: const Icon(Icons
                                                .add_circle_outline_rounded),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: 10,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      suggestionsCallback: (String pattern) {
                                        if (int.tryParse(pattern.trim()) !=
                                            null) {
                                          return Future.value([]);
                                        }
                                        return _searchParties(pattern);
                                      },
                                      itemBuilder: (context, party) {
                                        return ListTile(
                                          leading: const Icon(Icons.person),
                                          title: Text(party.name ?? ""),
                                        );
                                      },
                                      onSuggestionSelected: (Party party) {
                                        setState(() {
                                          widget.args.orderInput.party = party;
                                        });
                                        _typeAheadController.text =
                                            party.name ?? "";
                                      },
                                    ),
                                  ),
                                  const Divider(
                                      color: Colors.transparent, height: 5),
                                  const Divider(
                                      color: Colors.transparent, height: 20),
                                  CustomDropDownField(
                                    items: const <String>[
                                      "Cash",
                                      "Credit",
                                      "Bank Transfer",
                                    ],
                                    onSelected: (e) {
                                      setState(() {
                                        widget.args.orderInput.modeOfPayment =
                                            e;
                                      });
                                    },
                                    validator: (e) {
                                      if ((e ?? "").isEmpty) {
                                        return 'Please select a mode of payment';
                                      }
                                      return null;
                                    },
                                    hintText: "Mode of payment",
                                  ),

                                  const Divider(
                                      color: Colors.transparent, height: 50),

                                  CustomButton(
                                    title: "Share",
                                    onTap: () async {
                                      try {
                                        final res = await UserService.me();
                                        if ((res.statusCode ?? 400) < 300) {
                                          final user =
                                              User.fromMap(res.data['user']);

                                          openShareModal(context, user);
                                        }
                                      } catch (_) {}
                                    },
                                    type: ButtonType.outlined,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 10,
                                    ),
                                  ),
                                  const Divider(
                                      color: Colors.transparent, height: 50),

                                  CustomButton(
                                    title: "Save",
                                    onTap: () {
                                      _onTapSubmit();
                                    },
                                  ),

                                  // TextButton(
                                  //   onPressed: () {
                                  //     _onTapSubmit();
                                  //   },
                                  //   style: TextButton.styleFrom(
                                  //     backgroundColor: ColorsConst.primaryColor,
                                  //     shape: const CircleBorder(),
                                  //   ),
                                  //   child: const Icon(
                                  //     Icons.arrow_forward_rounded,
                                  //     size: 40,
                                  //     color: Colors.white,
                                  //   )
                                  // )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onTapShare(int type) async {
    locator<GlobalServices>().showBottomSheetLoader();
    try {
      final res = await UserService.me();
      if ((res.statusCode ?? 400) < 300) {
        final user = User.fromMap(res.data['user']);
        type == 0 ? _viewPdfwithgst(user) : _viewPdfwithoutgst(user);
      }
    } catch (_) {}
    Navigator.pop(context);
  }

  void _onTapSubmit() async {
    print(date);
    _formKey.currentState?.save();
    if (_formKey.currentState?.validate() ?? false) {
      widget.args.invoiceType == OrderType.purchase
          ? _checkoutCubit.createPurchaseOrder(widget.args.orderInput, date!)
          : _checkoutCubit.createSalesOrder(widget.args.orderInput, date!);
    }
  }
}

Future<void> _launchUrl(mobNum, user, paymethod, sub, tax, dis, items) async {
  //916000637319
  final String mobile = "91${mobNum}";
  final String invoiceHeader =
      "%0A%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%0A";
  final String invoiceText =
      "%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20INVOICE";
  final String email = "%0AEmail%3A%20${user.email}";
  final String cusName = "%0ACustomer%20Name%3A%20${user.businessName}";
  // final String Date = "%0ADate%3A%20%5BDate%5D";
  final String Date =
      "Date%3A%20${DateFormat('dd LLLL yyyy').format(DateTime.now())}";
  final String invoiceNumber = "%0AMobile%20Number%3A%20${user.phoneNumber}";
  final String dash1 = "%0A------------------------------------";
  final String tableHead =
      "%0A%20%20%20%20%20ITEM%20%20%20%20%20QTY%20%20%20%20%20PRICE%20%20%20%20%20TOTAL";
  String x = "";
  for (int i = 0; i < items.length; i++) {
    if (items[i].product.name.length <= 4) {
      x = x +
          "%0A%09%09%09${items[i].product.name}%09%09%20%09%09%09${items[i].quantity}%09%09%09%09%09%09${items[i].product.sellingPrice}%09%09%09%09%09%09%09${items[i].product.sellingPrice * items[i].quantity}";
    } else {
      x = x +
          "%0A%09%09%09${items[i].product.name.substring(0, 4)}%09%09%20%09%09%09${items[i].quantity}%09%09%09%09%09%09${items[i].product.sellingPrice}%09%09%09%09%09%09%09${items[i].product.sellingPrice * items[i].quantity}";
      x = x + "%0A%09%09%09${items[i].product.name.substring(4)}";
    }
  }
  /* final String tableData1 =
        "%0A%5BItem%201%5D%20%20%20%20${items[0]["qty"]}%20%20%5BPrice%201%5D%20%20%5BTotal%201%5D";
    final String tableData2 =
        "%0A%5BItem%202%5D%20%20%20%5BQty%202%5D%20%20%5BPrice%202%5D%20%20%5BTotal%202%5D";
    final String tableData3 = "%0A%5BItem%203%5D%20%20%20%5BQty%203%5D%20%20";*/
  final String subTotal = "%0ASubtotal%3A%20₹%20${sub}";
  final String delivery = "%0AGST%20Charges%3A%20₹%20${tax}";
  final String discount = "%0ADiscount%3A%20₹%20${dis}";
  final String grandTotal =
      "%0AGrand%20Total%3A%20₹%20${num.parse(sub) + num.parse(tax) - num.parse(dis)}";
  final String detailsText =
      "%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20PAYMENT%20DETAILS";

  final String method = "%0APayment%20Method%3A%20${paymethod}";
  final String dueDate =
      "%0ADue%20Date%3A%20${DateFormat('dd LLLL yyyy').format(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1))}";
  final String thanks = "%0AThank%20you%20for%20your%20business%21%0A";

  final Uri _url = Uri.parse(
      'https://wa.me/${mobile}?text=${invoiceHeader}${invoiceText}${invoiceHeader}${Date}${cusName}${email}${invoiceNumber}${dash1}${tableHead}${dash1}${x}${dash1}${subTotal}${delivery}${discount}${grandTotal}${dash1}${detailsText}${dash1}${method}${dash1}${thanks}');

  if (await canLaunchUrl(_url)) {
    await launchUrl(_url, mode: LaunchMode.externalApplication);
  } else {
    throw Exception('Could not launch $_url');
  }
}
