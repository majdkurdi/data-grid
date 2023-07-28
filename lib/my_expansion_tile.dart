import 'package:flutter/material.dart';

class MyExpansionTile extends StatefulWidget {
  const MyExpansionTile(
      {super.key,
      this.children,
      this.initialExpanded = false,
      this.leading,
      this.iconSize,
      required this.title,
      this.tileBackgroundColor,
      this.tileHeight});

  final double? tileHeight;
  final bool initialExpanded;
  final Widget title;
  final Widget? leading;
  final List<Widget>? children;
  final double? iconSize;
  final Color? tileBackgroundColor;

  @override
  State<MyExpansionTile> createState() => _MyExpansionTileState();
}

class _MyExpansionTileState extends State<MyExpansionTile> {
  late bool expanded = widget.initialExpanded;
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      alignment: Alignment.topCenter,
      duration: Duration(milliseconds: 100),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            child: Container(
              color: widget.tileBackgroundColor ?? Colors.grey[400],
              height: widget.tileHeight ?? 30,
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: widget.iconSize,
                  ),
                  const SizedBox(width: 5),
                  Row(
                    children: [
                      if (widget.leading != null) widget.leading!,
                      widget.title,
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (expanded && widget.children != null)
            for (var i in widget.children!) i,
        ],
      ),
    );
  }
}
