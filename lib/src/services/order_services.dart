import 'package:shopos/src/models/input/order_input.dart';
import 'package:shopos/src/models/online_order.dart';
import 'package:shopos/src/pages/checkout.dart';

// import 'api_v1.dart';
import 'package:shopos/src/services/api_v1.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderServices {
  //const OrderServices()

  static Future<List<OnlineOrder>> orderHistory() async {
    final response = await ApiV1Service.getRequest('/myorders');
    return (response.data as List)
        .map((e) => OnlineOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> pdf({
    required OrderInput orderInput,
    required String invoiceNum,
    required Object address,
    required String companyName,
    required String email,
    required int phoneNo,
    required String date,
    required OrderType reportType,
  }) async {
    print('fine');
    print(orderInput.orderItems!.map((e) => e.toJson(reportType)).toList());
    print(orderInput.orderItems!.map((e) => e.product!.saleigst.runtimeType));
    try {
      final response = await ApiV1Service.postRequest('/invoice', data: {
        'orderItem':
            orderInput.orderItems!.map((e) => e.toJson(reportType)).toList(),
        'invoice': invoiceNum,
        'address': address,
        'companyName': companyName,
        'email': email,
        'phone': phoneNo,
        'date': date,
      });

      if (await canLaunchUrl(
          Uri.parse('http://65.0.7.20:8001/api/v1/genrate/${response.data}'))) {
        await launchUrl(
            Uri.parse('http://65.0.7.20:8001/api/v1/genrate/${response.data}'));
      }
      print('res=${response.data}');
    } catch (e) {
      print(e.toString());
    }
  }
}
