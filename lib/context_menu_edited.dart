import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';

class ContextMenuEdited extends StatelessWidget {
  const ContextMenuEdited(
      {super.key,
      required this.child,
      this.builder,
      this.width,
      this.verticalPadding});

  final List<Widget> Function(BuildContext)? builder;
  final Widget child;
  final double? width;
  final double? verticalPadding;

  @override
  Widget build(BuildContext context) {
    return builder != null && builder!(context).isNotEmpty
        ? ContextMenuArea(
            builder: builder!,
            width: width ?? 320,
            verticalPadding: verticalPadding ?? 8,
            child: child,
          )
        : child;
  }
}
