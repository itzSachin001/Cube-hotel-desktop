import 'package:shopos/src/models/product.dart';
import 'package:shopos/src/pages/checkout.dart';

import '../party.dart';
import '../user.dart';

class OrderInput {
  OrderInput({
    this.orderItems,
    this.modeOfPayment,
    this.party,
    this.user,
    this.createdAt,
  });

  List<OrderItemInput>? orderItems;
  String? modeOfPayment;
  Party? party;
  User? user;
  DateTime? createdAt;

  factory OrderInput.fromMap(Map<String, dynamic> json) => OrderInput(
        orderItems: List<OrderItemInput>.from(
          json["orderItems"].map(
            (x) => OrderItemInput.fromMap(x),
          ),
        ),
        modeOfPayment: json["modeOfPayment"],
        party: json["party"],
        user: json["user"],
        createdAt: json["createdAt"],
      );

  Map<String, dynamic> toMap(OrderType type) => {
        "orderItems": orderItems
            ?.map((e) =>
                type == OrderType.sale ? e.toSaleMap() : e.toPurchaseMap())
            .toList(),
        "modeOfPayment": modeOfPayment,
        "party": party?.id,
        "user": user?.id,
        "createdAt": createdAt.toString(),
      };
}

class OrderItemInput {
  OrderItemInput({
    this.price = 0,
    this.quantity = 0,
    this.product,
  });

  int? price;
  int quantity;
  Product? product;

  factory OrderItemInput.fromMap(Map<String, dynamic> json) => OrderItemInput(
        price: json["price"],
        quantity: json["quantity"],
        product: json["product"],
      );

  Map<String, dynamic> toJson(OrderType invoiceType) {
    return {
      "price": invoiceType == OrderType.sale
          ? (product?.sellingPrice ?? 1)
          : (product?.purchasePrice ?? 1),
      "quantity": quantity,
      "product": {
        'name': product!.name,
        'baseSellingPriceGst': product!.baseSellingPriceGst != 'null'
            ? product!.baseSellingPriceGst
            : null,
        'sellingPrice': product!.sellingPrice,
        'gstRate': product!.saleigst != 'null' ? product!.saleigst : null,
      }
    };
  }

  Map<String, dynamic> toSaleMap() => {
        "price": (product?.sellingPrice ?? 1),
        "quantity": quantity,
        "product": product?.id,
      };
  Map<String, dynamic> toPurchaseMap() => {
        "price": (product?.purchasePrice ?? 1),
        "quantity": quantity,
        "product": product?.id,
      };
}
