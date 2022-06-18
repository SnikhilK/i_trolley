import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:i_trolley/constants.dart';
import 'package:i_trolley/screens/welcome_screen.dart';
import '../product_tile.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

enum ProductState { inAdd, inRemove, NinAdd, isNA }

final _firestore = FirebaseFirestore.instance;

var rfidData; //main data variables
var loadData;
double prevWeight = 0;
double currentWeight = 0;
double totalCostinCart = 0;
double totalWeightinCart = 0;
int totalQtyinCart = 0;

class MyCart extends StatefulWidget {
  static const String id = 'my_cart';
  MyCart({this.cartDeviceData});
  final cartDeviceData;

  late BluetoothCharacteristic rfidCharacteristic;
  late BluetoothCharacteristic loadCharacteristic;

  @override
  State<MyCart> createState() => _MyCartState();
}

List<String> productsIdOnlyList = [];
List<Map<String, dynamic>> productsMapData = []; //
List<Map<String, dynamic>> backRoomMapData = []; //Done

class _MyCartState extends State<MyCart> {
  //todo https://api.flutter.dev/flutter/dart-core/String/substring.html
  Future<void> initializeCharacteristics() async {
    try {
      List<BluetoothService> services =
          await widget.cartDeviceData.discoverServices();
      List<int> value = await services[2].characteristics[1].read();
      List<int> value2 = await services[2].characteristics[0].read();
      widget.loadCharacteristic = services[2].characteristics[0];
      widget.rfidCharacteristic = services[2].characteristics[1];
      setState(() {
        rfidData = String.fromCharCodes(value);
        loadData = String.fromCharCodes(value2);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future rfidNotification() async {
    if (!widget.rfidCharacteristic.isNotifying) {
      await widget.rfidCharacteristic.setNotifyValue(true);
      widget.rfidCharacteristic.value.listen((data) {
        // print(utf8.decode(data));
        setState(() {
          var temp = utf8.decode(data).trim();
          rfidData = temp.substring(0, 7);
          // print('rfidData is $rfidData');
          prevWeight = double.parse(temp.substring(7));
          // print('prev weight is $prevWeight');
          Future.delayed(const Duration(seconds: 2), () {
            actionProductInCart(rfidData);
            print('why am i printed 2x');
          });
        });
      });
    }
  }

  Future loadNotification() async {
    if (!widget.loadCharacteristic.isNotifying) {
      await widget.loadCharacteristic.setNotifyValue(true);
      widget.loadCharacteristic.value.listen((data) {
        // print(utf8.decode(data));
        setState(() {
          loadData = utf8.decode(data).trim();
          currentWeight = double.parse(loadData);
          // print('$currentWeight is Current');
          print(productsIdOnlyList);
        });
        checkTotalWeight();
      });
    }
  }

  void importBackStoreData() {
    try {
      //Done
      showModalBottomSheet(
        context: context,
        builder: backRoom,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  ProductState decideProductFate(
      {required String productID,
      required List<String> productsList,
      required double prevWeight,
      required double currentWeight}) {
    //print(
    //   'curr w8 of $currentWeight and prev w8 is $prevWeight, list is $productsList');
    if (prevWeight != currentWeight && productsList.contains(productID)) {
      if (prevWeight < currentWeight) {
        return ProductState.inAdd;
      } else {
        return ProductState.isNA;
      }
    } else if (prevWeight == currentWeight) {
      return ProductState.inRemove;
    } else if (prevWeight != currentWeight &&
        !productsList.contains(productID)) {
      return ProductState.NinAdd;
    } else {
      return ProductState.isNA;
    }
  }

  int getIndexFromListMaps(String productId, List<Map<String, dynamic>> map) {
    for (var i = 0; i < map.length; i++) {
      if (map[i]['ProductID'] == productId) {
        return i;
      }
    }
    return 1000;
  }

  void actionProductInCart(String productId) {
    int index = getIndexFromListMaps(productId, backRoomMapData);
    int qty = 0;
    int indexP = getIndexFromListMaps(productId, productsMapData);
    switch (decideProductFate(
        productID: productId,
        productsList: productsIdOnlyList,
        prevWeight: prevWeight,
        currentWeight: currentWeight)) {
      case ProductState.inAdd:
        {
          productsIdOnlyList.add(productId);
          productsMapData[indexP]['Qty'] = productsMapData[indexP]['Qty'] + 1;
          //productsMapData[index]['Qty'] =
          //    countDuplicates(productsIdOnlyList, product_id);

          // Qty = productsMapData[index]['Qty'];
          // Qty += 1;
          // productsMapData.add({
          //   'ProductID': product_id,
          //   'Title': backRoomMapData[index]['Title'],
          //   'Cost': backRoomMapData[index]['Cost'],
          //   'Weight': backRoomMapData[index]['Weight'],
          //   'Qty': Qty
          // });
        }
        break;
      case ProductState.inRemove:
        {
          productsIdOnlyList.remove(productId);
          qty = productsMapData[indexP]['Qty'];
          if (qty == 1) {
            productsMapData.removeAt(indexP);
          } else {
            productsMapData[indexP]['Qty'] = qty - 1;
          }
        }
        break;
      case ProductState.NinAdd: //flawless
        {
          productsIdOnlyList.add(productId);
          productsMapData.add({
            'ProductID': productId,
            'Title': backRoomMapData[index]['Title'],
            'Cost': backRoomMapData[index]['Cost'],
            'Weight': backRoomMapData[index]['Weight'],
            'Qty': 1
          });
        }
        break;
      default:
        {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Try Again, Invalid Operation'),
            ));
        }
        break;
    }
  }

  productTile returnProductTilefromProductMapData(
      {required int index,
      required List<Map<String, dynamic>> productsMapData}) {
    return productTile(
        productTitle: productsMapData[index]['Title'],
        productProductID: productsMapData[index]['ProductID'],
        productWeight: productsMapData[index]['Weight'],
        productCost: productsMapData[index]['Cost'],
        qty: productsMapData[index]['Qty']);
  }

  double getTotalCost(List<Map<String, dynamic>> productsMapData) {
    double sum = 0;
    for (var i = 0; i < productsMapData.length; i++) {
      sum = (productsMapData[i]['Cost'] * productsMapData[i]['Qty']) + sum;
    }
    return sum;
  }

  double getTotalWeight(List<Map<String, dynamic>> productsMapData) {
    double sum = 0;
    for (var i = 0; i < productsMapData.length; i++) {
      sum = productsMapData[i]['Weight'] * productsMapData[i]['Qty'] + sum;
    }
    return sum;
  }

  int getTotalQty(List<Map<String, dynamic>> productsMapData) {
    int sum = 0;
    for (var i = 0; i < productsMapData.length; i++) {
      sum = productsMapData[i]['Qty'] + sum;
    }
    return sum;
  }

  void checkTotalWeight() {
    var totalWeightinCart = getTotalWeight(productsMapData);
    //print(
    //    '(${currentWeight - 5},${currentWeight + 5}) -> is Range || $totalWeightinCart is Registered Weight');
    bool temp = (currentWeight - 5 <= totalWeightinCart &&
        totalWeightinCart <= currentWeight + 5);

    if (!temp) {
      Vibrate.vibrate();

      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Inspect Weight!'), duration: Duration(seconds: 2)));
    }
  }

  void donothing() {}

  Future<void> setNotification() async {
    await loadNotification();
    await rfidNotification();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), importBackStoreData);
    Future.delayed(const Duration(seconds: 1), initializeCharacteristics);
  }

  @override
  Widget build(BuildContext context) {
    totalCostinCart = getTotalCost(productsMapData);
    totalWeightinCart = getTotalWeight(productsMapData);
    totalQtyinCart = getTotalQty(productsMapData);
    setNotification();
    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(
          'My Shopping Cart',
          style: kText4button.copyWith(fontSize: 25, letterSpacing: 1),
        ),
        leading: GestureDetector(
          onTap: () {
            try {
              widget.cartDeviceData.disconnect();
            } catch (e) {
              debugPrint(e.toString());
            } finally {
              Navigator.pushNamed(context, WelcomeScreen.id);
            }
          },
          child: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
        child: GestureDetector(
          onLongPress: importBackStoreData,
          onDoubleTap: donothing,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const productTile(
                  productTitle: 'Product Name',
                  productProductID: 'Product ID',
                  productWeight: 'Weight (gram)',
                  productCost: 'Cost (₹)'),
              const Divider(
                color: Colors.grey,
                indent: 10,
                endIndent: 10,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: productsMapData.length,
                  itemBuilder: (BuildContext context, int index) {
                    return returnProductTilefromProductMapData(
                        index: index, productsMapData: productsMapData);
                  },
                ),
              ),
              Container(
                  color: Colors.white,
                  height: 19,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Text(
                        ' Current Weight in Cart :',
                        style: kListContent.copyWith(
                            color: Colors.black, fontWeight: FontWeight.w400),
                        textAlign: TextAlign.left,
                      ),
                      Spacer(),
                      Text(
                        ' $loadData g ',
                        style: kListContent.copyWith(
                            color: Colors.black, fontWeight: FontWeight.w400),
                        textAlign: TextAlign.right,
                      )
                    ],
                  )),
              // GestureDetector(
              //   child: Container(
              //     height: 40,
              //     color: Colors.white,
              //     child: Text('Please Work  $rfidData $loadData ??',
              //         style: const TextStyle(color: Colors.black)),
              //   ),
              // ),
              GestureDetector(
                onLongPress: () {
                  showModalBottomSheet(
                      context: context, builder: checkoutModal);
                },
                child: productTile(
                    productTitle: 'Total Cost',
                    productProductID: 'Product ID',
                    productWeight: totalWeightinCart,
                    productCost: totalCostinCart.toStringAsFixed(2),
                    qty: totalQtyinCart),
              )
            ],
          ),
        ),
      ),
    ));
  }
}

// ignore: use_key_in_widget_constructors
class BackRoomProductListBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('BackRoom').snapshots(),
      builder: (context, snapshot) {
        //BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent),
          );
        }
        final backRoomProducts = snapshot.data?.docs;
        List<productTile> productsList = [];
        backRoomMapData = [];
        for (var backRoomProduct in backRoomProducts!) {
          final productCost = backRoomProduct['Cost'];
          final productProductID = backRoomProduct['ProductID'];
          final productTitle = backRoomProduct['Title'];
          final productWeight = backRoomProduct['Weight'];
          final productItem = productTile(
              productTitle: productTitle,
              productProductID: productProductID,
              productWeight: productWeight,
              productCost: productCost);
          productsList.add(productItem);
          Map<String, dynamic> newMap = {
            'ProductID': backRoomProduct['ProductID'],
            'Title': backRoomProduct['Title'],
            'Cost': backRoomProduct['Cost'],
            'Weight': backRoomProduct['Weight']
          };
          backRoomMapData.add(newMap);
        }
        return Column(
          children: [
            Expanded(
              child: ListView(
                reverse:
                    false, //angel said list is sticky towards bottom side now
                children: productsList,
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget backRoom(BuildContext context) {
  return SafeArea(
    child: BackRoomProductListBuilder(),
  );
}

Widget checkoutModal(BuildContext context) {
  return SafeArea(
    child: Center(
      // ignore: sized_box_for_whitespace
      child: Column(
        children: [
          const SizedBox(height: 50),
          Expanded(
            flex: 2,
            child: const SizedBox(
              height: 200,
              child: Text(' C H E C K O U T '),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              height: 400,
              child: Text(
                'Pay ₹ $totalCostinCart',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic),
              ),
            ),
          )
        ],
      ),
    ),
  );
}
