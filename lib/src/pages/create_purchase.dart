import 'package:flutter/material.dart';
import 'package:shopos/src/models/input/order_input.dart';
import 'package:shopos/src/models/product.dart';
import 'package:shopos/src/pages/checkout.dart';
import 'package:shopos/src/pages/create_product.dart';
import 'package:shopos/src/pages/select_products_screen.dart';
import 'package:shopos/src/widgets/custom_button.dart';
import 'package:shopos/src/widgets/custom_continue_button.dart';
import 'package:shopos/src/widgets/product_card_horizontal.dart';

class CreatePurchase extends StatefulWidget {
  static const routeName = '/create_purchase';

  const CreatePurchase({Key? key}) : super(key: key);

  @override
  State<CreatePurchase> createState() => _CreatePurchaseState();
}

class _CreatePurchaseState extends State<CreatePurchase> {
  late OrderInput _orderInput;

  @override
  void initState() {
    super.initState();
    _orderInput = OrderInput(
      orderItems: [],
    );
  }

  void _onAdd(OrderItemInput orderItem) {
    setState(() {
      orderItem.quantity += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _orderItems = _orderInput.orderItems ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: _orderItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No products added yet',
                      ),
                    )
                  : GridView.builder(
                      physics: ClampingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisExtent: 200),
                      itemCount: _orderItems.length,
                      itemBuilder: (context, index) {
                        final _orderItem = _orderItems[index];
                        final product = _orderItems[index].product!;
                        return ProductCardPurchase(
                          type: "purchase",
                          product: product,
                          onAdd: () {
                            _onAdd(_orderItem);
                          },
                          onDelete: () {
                            setState(
                              () {
                                _orderItem.quantity == 1
                                    ? _orderInput.orderItems?.removeAt(index)
                                    : _orderItem.quantity -= 1;
                              },
                            );
                          },
                          productQuantity: _orderItem.quantity,
                        );
                      },
                    ),
            ),
            const Divider(color: Colors.transparent),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(
                    title: "Add Product",
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        SelectProductScreen.routeName,
                        arguments: ProductListPageArgs(
                          isSelecting: true,
                          orderType: OrderType.purchase,
                        ),
                      );
                      if (result == null && result is! List<Product>) {
                        return;
                      }
                      final orderItems = (result as List<Product>)
                          .map((e) => OrderItemInput(
                                product: e,
                                quantity: 1,
                                price: 0,
                              ))
                          .toList();
                      setState(() {
                        _orderInput.orderItems = orderItems;
                      });
                    },
                  ),
                  // const VerticalDivider(
                  //   color: Colors.transparent,
                  //   width: 10,
                  // ),
                  CustomContinueButton(
                    title: "Continue",
                    onTap: () {
                      if (_orderItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              "Please select products before continuing",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          CheckoutPage.routeName,
                          arguments: CheckoutPageArgs(
                            invoiceType: OrderType.purchase,
                            orderInput: _orderInput,
                          ),
                        );
                      }
                    },
                  ),
                  CustomButton(
                    title: "Create Product",
                    onTap: () {
                      Navigator.pushNamed(context, CreateProduct.routeName);
                    },
                    type: ButtonType.outlined,
                  )
                ],
              ),
            ),
            const Divider(color: Colors.transparent),
          ],
        ),
      ),
    );
  }
}
