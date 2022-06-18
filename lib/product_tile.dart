import 'package:flutter/material.dart';
import 'package:i_trolley/constants.dart';

class productTile extends StatelessWidget {
  const productTile(
      {this.productTitle,
      this.productProductID,
      this.productWeight,
      this.productCost,
      this.qty});
  final productWeight;
  final productTitle;
  final productProductID;
  final productCost;
  final qty;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListTile(
        title: SizedBox(
          child: Text(
            '$productTitle',
            style: kListTextTitle,
          ),
        ),
        subtitle: Text('$productProductID  |  Qty. ${qty == null ? '' : qty}',
            style: kListContent),
        trailing: Container(
          height: 30,
          width: 125,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text('$productWeight', style: kListContent)),
              SizedBox(
                width: 5,
              ),
              VerticalDivider(
                color: Colors.grey,
              ),
              Container(child: Text('$productCost', style: kListContent))
            ],
          ),
        ),
      ),
    );
  }
}
