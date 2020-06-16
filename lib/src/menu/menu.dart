import 'package:flutter/material.dart';
import 'package:menu/src/helper/ui_helper.dart';
import 'package:menu/src/menu/tap_type.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';

part './decoration.dart';

typedef Widget ItemBuilder(
  MenuItem item,
  MenuDecoration menuDecoration,
  VoidCallback dismiss, {
  bool isFirst,
  bool isLast,
});

typedef Widget DividerBuilder(BuildContext context, int lastIndex);

class Menu extends StatefulWidget {
  final Widget child;
  final List<MenuItem> items;
  final MenuDecoration decoration;
  final ItemBuilder itemBuilder;
  final ClickType clickType;
  final DividerBuilder dividerBuilder;

  const Menu({
    Key key,
    this.items,
    this.child,
    this.decoration = const MenuDecoration(),
    this.itemBuilder = defaultItemBuilder,
    this.clickType = ClickType.longPress,
    this.dividerBuilder = buildDivider,
  }) : super(key: key);

  @override
  MenuState createState() => MenuState();

  static Widget buildDivider(BuildContext context, int lastIndex) {
    return Container(
      width: 0.5,
      color: Colors.white,
    );
  }
}

class MenuState extends State<Menu> {
  GlobalKey key = GlobalKey();
  String _gesture = "";
  TapPosition _position = TapPosition(Offset.zero, Offset.zero);


  @override
  Widget build(BuildContext context) {
    switch (widget.clickType) {
      case ClickType.longPress:
        return PositionedTapDetector(
          key: key,
          onLongPress: (position){
            defaultLPShowItem(position);
          },
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        );
        break;
      case ClickType.click:
        return GestureDetector(
          key: key,
          onTap: defaultShowItem,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        );
      case ClickType.doubleClick:
        return GestureDetector(
          key: key,
          onDoubleTap: defaultShowItem,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        );
      default:
        return widget.child;
    }
  }
  void defaultLPShowItem(TapPosition pos) {
    var rect = UIHelper.findGlobalRect(key);
    var noOfCharacters = widget.items.map((e) => e.text).join("").length;

    // character ~8px each, horizontal padding 20px for each MenuItem, separator 0.5px ,
    var width = noOfCharacters * 9 + widget.items.length * 20 + (widget.items.length - 1) * 0.5;
    var dx = pos.global.dx - 40;
    var dy = pos.global.dy - 70;
    var screenW = MediaQuery.of(context).size.width;
    if (dx > screenW - width){
      dx = screenW - width;
    }else if (dx < 0){
      dx = 0;
    }
    if(dy < 0){
      dy = 0;
    }

    showItem(Rect.fromLTWH(dx, dy, rect.width, rect.height));
  }
  void defaultShowItem() {
    var rect = UIHelper.findGlobalRect(key);
    print("rect $rect");
    showItem(rect);
  }

  OverlayEntry itemEntry;

  void showItem(Rect rect) {
    var items = widget.items;
    Widget w;
    w = ListView(
      scrollDirection: Axis.horizontal,
      children: items.map((item) {
        var index = widget.items.indexOf(item);
        var itemWidget = widget.itemBuilder(
          item,
          menuDecoration,
          dismissBackground,
          isFirst: index == 0,
          isLast: index == widget.items.length - 1,
        );

        return Row(
          children: <Widget>[
            itemWidget,
            if (index != widget.items.length - 1)
              widget.dividerBuilder(context, index),
          ],
        );
      }).toList(),
      // shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
    );

    w = FittedBox(
      fit: BoxFit.none,
      alignment: Alignment.topLeft,
      child: Container(
        alignment: Alignment.topLeft,
        // color: Colors.green,
        width: MediaQuery.of(context).size.width,
        child: w,
        height: 36,
      ),
    );

    w = Padding(
      padding: EdgeInsets.only(left: rect.left, top: rect.top),
      child: w,
    );

    var size = MediaQuery.of(context).size;

    w = Container(
      child: w,
      width: size.width,
      height: size.height,
    );

    w = GestureDetector(
      child: w,
      behavior: HitTestBehavior.opaque,
      onTap: () {
        dismissBackground();
      },
    );

    itemEntry = OverlayEntry(builder: (BuildContext context) => w);

    Overlay.of(context).insert(itemEntry);
  }

  MenuDecoration get menuDecoration => widget.decoration;

  void dismissBackground() {
    itemEntry.remove();
    itemEntry = null;
  }
}

class MenuItem {
  final String text;
  final Function onTap;

  const MenuItem(this.text, this.onTap);
}

Widget defaultItemBuilder(
  MenuItem item,
  MenuDecoration menuDecoration,
  VoidCallback dismiss, {
  bool isFirst,
  bool isLast,
}) {
  final BoxConstraints constraints =
      menuDecoration.constraints ?? const BoxConstraints();

  final EdgeInsetsGeometry itemPadding = menuDecoration.padding ??
      const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 10.0,
      );

  Widget w = InkWell(
    splashColor: menuDecoration.splashColor,
    // color: menuDecoration.color,
    child: Container(
      padding: itemPadding,
      constraints: constraints,
      alignment: Alignment.center,
      child: Text(
        item.text,
        style: menuDecoration.textStyle,
      ),
    ),
    onTap: () {
      item.onTap();
      dismiss();
    },
  );

  var r = menuDecoration.radius;
  var radius = BorderRadius.horizontal(
    left: isFirst ? Radius.circular(r) : Radius.zero,
    right: isLast ? Radius.circular(r) : Radius.zero,
  );

  w = Material(
    color: menuDecoration.color,
    child: w,
  );

  return ClipRRect(
    child: w,
    borderRadius: radius,
  );
}
