import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'consts.dart';
import 'context_menu_edited.dart';
import 'my_expansion_tile.dart';

// ignore: must_be_immutable
class XtraDataGrid extends StatefulWidget {
  XtraDataGrid(
      {super.key,
      required this.columns,
      required this.source,
      this.headerColor,
      this.headerStyle,
      this.onColumnResize,
      this.onColumnsReorder,
      this.groupByColumn,
      this.onSelected,
      this.onLongPress,
      this.setSelectedCell,
      this.onDoubleTap,
      this.focusNode,
      this.manualFocus,
      this.autoFocus = true,
      this.contextMenu,
      this.onKey,
      this.onRebuild,
      this.groupNameBuilder,
      this.rowHeight = 22});
  final MyDataGridSource source;
  final Color? headerColor;
  final TextStyle? headerStyle;
  List<MyGridColumn> columns;
  final void Function(int, int)? onColumnsReorder;
  final void Function(MyGridColumn column, double dx)? onColumnResize;
  final double rowHeight;
  final MyGridColumn? groupByColumn;
  final void Function(DataGridRow, RowColumnIndex)? onSelected;
  final void Function(DataGridRow)? onLongPress;
  final void Function(RowColumnIndex)? setSelectedCell;
  final void Function(DataGridRow)? onDoubleTap;
  final bool autoFocus;
  final bool? manualFocus;
  final FocusNode? focusNode;
  final List<Widget> Function(BuildContext, DataGridRow, DataGridCell)?
      contextMenu;
  final void Function(KeyEvent)? onKey;
  final void Function()? onRebuild;
  final String Function(dynamic)? groupNameBuilder;

  void reorderColumns(int lastI, int newI) {
    final c = columns.removeAt(lastI);
    columns.insert(newI, c);
  }

  void resizeColumn(MyGridColumn c, double dx) {
    columns.firstWhere((element) => element.columnName == c.columnName).width +=
        dx;
  }

  @override
  State<XtraDataGrid> createState() => _XtraDataGridState();
}

class _XtraDataGridState extends State<XtraDataGrid> {
  RowColumnIndex currentCell = RowColumnIndex(0, 0);
  bool editMode = false;
  // bool columnDragging = false;
  late final focusNode = widget.focusNode ?? FocusNode();
  final scrollController = ScrollController();
  final headerController = ScrollController();
  final verticalController = ScrollController();
  // final groupsController = ScrollController();
  final indexesController = ScrollController();
  MyGridColumn? groupByColumn;

  // void onKey(KeyEvent event) async {
  //   if (event is KeyDownEvent) {
  //     final oldCell = currentCell;
  //     final oldEditMode = editMode;
  //     if (event.logicalKey == LogicalKeyboardKey.arrowLeft && !editMode) {
  //       currentCell = arabicLocale ? _nextCell() : _previousCell();
  //       // while (!widget.columns[currentCell.columnIndex].allowEditing) {
  //       //   currentCell = arabicLocale ? _nextCell() : _previousCell();
  //       // }
  //     } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
  //         !editMode) {
  //       currentCell = arabicLocale ? _previousCell() : _nextCell();
  //       // while (!widget.columns[currentCell.columnIndex].allowEditing) {
  //       //   currentCell = arabicLocale ? _previousCell() : _nextCell();
  //       // }
  //     } else if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
  //         !editMode) {
  //       if (currentCell.rowIndex == widget.source.rows.length - 1) {
  //         currentCell = currentCell;
  //       } else {
  //         currentCell = (RowColumnIndex(
  //             currentCell.rowIndex + 1, currentCell.columnIndex));
  //       }
  //     } else if (event.logicalKey == LogicalKeyboardKey.pageDown && !editMode) {
  //       if (currentCell.rowIndex >= widget.source.rows.length - 11) {
  //         currentCell = RowColumnIndex(
  //             widget.source.rows.length - 1, currentCell.columnIndex);
  //       } else {
  //         currentCell = (RowColumnIndex(
  //             currentCell.rowIndex + 10, currentCell.columnIndex));
  //       }
  //     } else if (event.logicalKey == LogicalKeyboardKey.arrowUp && !editMode) {
  //       if (RawKeyboard.instance.keysPressed
  //           .contains(LogicalKeyboardKey.home)) {
  //         currentCell = RowColumnIndex(0, 0);
  //       } else {
  //         if (currentCell.rowIndex == 0) {
  //           currentCell = currentCell;
  //         } else {
  //           currentCell = (RowColumnIndex(
  //               currentCell.rowIndex - 1, currentCell.columnIndex));
  //         }
  //       }
  //     } else if (event.logicalKey == LogicalKeyboardKey.end && !editMode) {
  //       currentCell =
  //           RowColumnIndex(currentCell.rowIndex, widget.columns.length - 1);
  //     } else if (event.logicalKey == LogicalKeyboardKey.home && !editMode) {
  //       currentCell = RowColumnIndex(currentCell.rowIndex, 0);
  //     } else if (event.logicalKey == LogicalKeyboardKey.pageUp && !editMode) {
  //       if (currentCell.rowIndex <= 10) {
  //         currentCell = RowColumnIndex(0, currentCell.columnIndex);
  //       } else {
  //         currentCell = (RowColumnIndex(
  //             currentCell.rowIndex - 10, currentCell.columnIndex));
  //       }
  //     } else if (event.logicalKey == LogicalKeyboardKey.escape && editMode) {
  //       widget.source.onCellCancelEdit(currentCell);
  //       editMode = false;
  //     } else if (event.logicalKey == LogicalKeyboardKey.enter) {
  //       if (RawKeyboard.instance.keysPressed.any((e) => [
  //             LogicalKeyboardKey.controlLeft,
  //             LogicalKeyboardKey.controlRight
  //           ].contains(e))) {
  //         if (editMode) {
  //           endEdit(RowColumnIndex(
  //               currentCell.rowIndex + 1, currentCell.columnIndex));
  //         } else {
  //           currentCell = oldCell.rowIndex == widget.source.rows.length - 1
  //               ? currentCell
  //               : RowColumnIndex(
  //                   currentCell.rowIndex + 1, currentCell.columnIndex);
  //         }
  //       } else {
  //         if (!editMode) {
  //           currentCell = _nextCell();
  //         }
  //       }
  //     } else if (event.logicalKey == LogicalKeyboardKey.f2 &&
  //         currentCell.rowIndex >= 0 &&
  //         currentCell.columnIndex >= 0 &&
  //         widget.columns[currentCell.columnIndex].allowEditing) {
  //       editMode = widget.source.onCellBeginEdit(
  //           widget.source.rows[currentCell.rowIndex],
  //           currentCell,
  //           widget.columns[currentCell.columnIndex]);
  //     } else if (event.logicalKey == LogicalKeyboardKey.tab) {
  //       final keysPressed = RawKeyboard.instance.keysPressed;
  //       final shiftPressed =
  //           keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
  //               keysPressed.contains(LogicalKeyboardKey.shiftRight);
  //       if (editMode) {
  //         endEdit(shiftPressed ? _previousCell() : null);
  //       } else {
  //         currentCell = shiftPressed ? _previousCell() : _nextCell();
  //       }
  //     } else if ((engLetters
  //                 .contains(event.logicalKey.keyLabel.toLowerCase()) ||
  //             araLetters.contains(event.character) ||
  //             numbers.contains(
  //                 event.logicalKey.keyLabel.replaceAll('Numpad ', '')) ||
  //             araNumbers.contains(
  //                 event.logicalKey.keyLabel.replaceAll('Numpad ', '')) ||
  //             event.logicalKey == LogicalKeyboardKey.delete) &&
  //         !editMode &&
  //         widget.columns[currentCell.columnIndex].allowEditing) {
  //       if (event.logicalKey != LogicalKeyboardKey.delete) {
  //         widget.source.firstChar = event.character
  //                 ?.replaceAll('Numpad ', '')
  //                 .toLowerCase()
  //                 .replaceArabicNumber() ??
  //             '';
  //       }
  //       editMode = widget.source.onCellBeginEdit(
  //           widget.source.rows[currentCell.rowIndex],
  //           currentCell,
  //           widget.columns[currentCell.columnIndex]);
  //     } else if (event.logicalKey == LogicalKeyboardKey.f3) {
  //       await widget.source.onCellSubmit(
  //           widget.source.rows[currentCell.rowIndex],
  //           currentCell,
  //           widget.columns[currentCell.columnIndex]);
  //       setState(() {});
  //     } else if (!editMode && event.logicalKey == LogicalKeyboardKey.f10) {
  //       if (currentCellValue is ConstantsCard) {
  //         context.read<QuickInfoBloc>().add(GetCardInfo(currentCellValue));
  //       }
  //     }
  //     if (currentCell.toString() != oldCell.toString()) {
  //       editMode = false;
  //       if (scrollController.hasClients &&
  //           currentCell.columnIndex != oldCell.columnIndex) {
  //         if (oldCell.columnIndex == 0 &&
  //             currentCell.columnIndex == widget.columns.length - 1) {
  //           scrollController.animateTo(
  //               scrollController.position.maxScrollExtent,
  //               duration: const Duration(milliseconds: 50),
  //               curve: Curves.ease);
  //         } else if (oldCell.columnIndex == widget.columns.length - 1 &&
  //             currentCell.columnIndex == 0) {
  //           scrollController.animateTo(0,
  //               duration: const Duration(milliseconds: 50), curve: Curves.ease);
  //         } else if (currentCell.columnIndex >= 5 &&
  //             currentCell.columnIndex > oldCell.columnIndex &&
  //             scrollController.offset !=
  //                 scrollController.position.maxScrollExtent) {
  //           scrollController.animateTo(scrollController.offset + 100,
  //               duration: const Duration(milliseconds: 50), curve: Curves.ease);
  //         } else if (currentCell.columnIndex <= widget.columns.length - 5 &&
  //             currentCell.columnIndex < oldCell.columnIndex &&
  //             scrollController.offset !=
  //                 scrollController.position.minScrollExtent) {
  //           scrollController.animateTo(scrollController.offset - 100,
  //               duration: const Duration(milliseconds: 50), curve: Curves.ease);
  //         }
  //       }
  //       if (oldCell.rowIndex <= widget.source.rows.length - 7 &&
  //           currentCell.rowIndex < oldCell.rowIndex &&
  //           verticalController.offset != 0 &&
  //           event.logicalKey != LogicalKeyboardKey.pageUp) {
  //         verticalController
  //             .jumpTo(verticalController.offset - widget.rowHeight);
  //       } else if (oldCell.rowIndex >= 7 &&
  //           currentCell.rowIndex > oldCell.rowIndex &&
  //           verticalController.offset !=
  //               verticalController.position.maxScrollExtent &&
  //           event.logicalKey != LogicalKeyboardKey.pageDown) {
  //         verticalController
  //             .jumpTo(verticalController.offset + widget.rowHeight);
  //       } else if (oldCell.rowIndex == 0 &&
  //           currentCell.rowIndex == widget.source.rows.length - 1) {
  //         verticalController
  //             .jumpTo(verticalController.position.maxScrollExtent);
  //       } else if (oldCell.rowIndex == widget.source.rows.length - 1 &&
  //           currentCell.rowIndex == 0) {
  //         verticalController.jumpTo(0);
  //       } else if (verticalController.offset <
  //               verticalController.position.maxScrollExtent &&
  //           event.logicalKey == LogicalKeyboardKey.pageDown) {
  //         verticalController.jumpTo(
  //             verticalController.offset + widget.rowHeight * 10 <=
  //                     verticalController.position.maxScrollExtent
  //                 ? verticalController.offset + widget.rowHeight * 10
  //                 : verticalController.position.maxScrollExtent);
  //       } else if (verticalController.offset > 0 &&
  //           event.logicalKey == LogicalKeyboardKey.pageUp) {
  //         verticalController.jumpTo(
  //             verticalController.offset - widget.rowHeight * 10 >= 0
  //                 ? verticalController.offset - widget.rowHeight * 10
  //                 : 0);
  //       }
  //     }
  //     // print(oldCell.rowIndex
  //     //      == 0
  //     // &&
  //     // currentCell.rowIndex == widget.source.rows.length - 1
  //     // );
  //     if (editMode != oldEditMode ||
  //         currentCell.toString() != oldCell.toString() ||
  //         !editMode) {
  //       Future.delayed(Duration.zero, () {
  //         if (mounted) setState(() {});
  //       });
  //     }
  //   }
  // }

  RowColumnIndex _nextCell() {
    final nextColumn = currentCell.columnIndex == widget.columns.length - 1
        ? 0
        : currentCell.columnIndex + 1;
    final nextRow = currentCell.columnIndex == widget.columns.length - 1
        ? currentCell.rowIndex + 1
        : currentCell.rowIndex;
    return nextRow < 0 ||
            nextRow > widget.source.rows.length - 1 ||
            nextColumn > widget.columns.length - 1 ||
            nextColumn < 0
        ? currentCell
        : RowColumnIndex(nextRow, nextColumn);
  }

  RowColumnIndex _previousCell() {
    final nextColumn = currentCell.columnIndex == 0
        ? widget.columns.length - 1
        : currentCell.columnIndex - 1;
    final nextRow = currentCell.columnIndex == 0
        ? currentCell.rowIndex - 1
        : currentCell.rowIndex;

    return nextRow < 0 ||
            nextRow > widget.source.rows.length - 1 ||
            nextColumn > widget.columns.length - 1 ||
            nextColumn < 0
        ? currentCell
        : RowColumnIndex(nextRow, nextColumn);
  }

  void endEdit([RowColumnIndex? nextCell]) async {
    await widget.source.onCellSubmit(widget.source.rows[currentCell.rowIndex],
        currentCell, widget.columns[currentCell.columnIndex]);
    editMode = false;
    currentCell = nextCell ?? _nextCell();
    // while(!widget.columns[currentCell.columnIndex].allowEditing){
    // currentCell = _nextCell();
    // }
    setState(() {});
  }

  @override
  void initState() {
    groupByColumn = widget.groupByColumn;

    if (widget.autoFocus) {
      focusNode.requestFocus();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant XtraDataGrid oldWidget) {
    groupByColumn = widget.groupByColumn;
    if (oldWidget.source != widget.source) {
      // widget.source.onCellCancelEdit(currentCell);
      editMode = false;
      currentCell = RowColumnIndex(0, 0);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (scrollController.hasClients) scrollController.jumpTo(0);
        if (verticalController.hasClients) verticalController.jumpTo(0);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      focusNode.dispose();
    }
    scrollController.dispose();
    verticalController.dispose();
    indexesController.dispose();
    super.dispose();
  }

  // List<Widget> contextMenu(
  //         BuildContext ctx, DataGridRow row, DataGridCell cell) =>
  //     constsContextMenu(context, ctx, cell.value)
  //       ..addIf(
  //         widget.source.rows.length > 1,
  //         ContextMenuTile(
  //             title: 'deleteRow'.tr,
  //             onTap: () {
  //               setState(() {
  //                 Navigator.of(ctx).pop();
  //                 widget.source.deleteRow(row);
  //               });
  //             }),
  //       );

  Widget _headerCell(MyGridColumn e) {
    return ContextMenuEdited(
      width: 150,
      builder: e.contextMenuItems,
      child: Container(
        // key: ValueKey(e.columnName),
        // duration: Duration.zero,
        // alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(width: 0.25, color: Colors.grey),
        ),
        width: e.width,
        height: widget.rowHeight,
        child: DragTarget<MyGridColumn>(
          onAccept: (data) {
            if (!widget.columns.contains(data) || !widget.columns.contains(e)) {
              return;
            }
            if (widget.onColumnsReorder != null && e.columnName != 'index') {
              widget.onColumnsReorder!(
                  widget.columns.indexOf(data), widget.columns.indexOf(e));
            } else if (widget.onColumnsReorder == null &&
                e.columnName != 'index') {
              widget.reorderColumns(
                  widget.columns.indexOf(data), widget.columns.indexOf(e));
              setState(() {});
            }
          },
          builder: (BuildContext context, List<Object?> candidateData,
                  List<dynamic> rejectedData) =>
              Container(
                  color: widget.headerColor ?? Colors.blue,
                  child: Row(
                    children: [
                      Expanded(
                        child: e.columnName == 'index'
                            ? Container(
                                width: e.width,
                                height: widget.rowHeight,
                                color: widget.headerColor,
                                child: Center(
                                    child: Text(
                                  e.label,
                                  style: widget.headerStyle,
                                )),
                              )
                            : Draggable(
                                data: e,
                                feedback: Container(
                                  width: e.width,
                                  height: widget.rowHeight,
                                  color: widget.headerColor,
                                  child: Center(
                                      child: Text(
                                    e.label,
                                    style: widget.headerStyle,
                                  )),
                                ),
                                childWhenDragging: Container(
                                  width: e.width,
                                  height: widget.rowHeight,
                                ),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                      child: Text(
                                    e.label,
                                    style: widget.headerStyle,
                                  )),
                                ),
                              ),
                      ),
                      MouseRegion(
                        cursor: e.columnName != 'index'
                            ? SystemMouseCursors.resizeColumn
                            : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onPanUpdate: (d) {
                            if (widget.onColumnResize != null &&
                                e.columnName != 'index') {
                              widget.onColumnResize!(
                                  e, (d.delta.dx * (arabicLocale ? -1 : 1)));
                            } else if (widget.onColumnResize == null &&
                                e.columnName != 'index') {
                              widget.resizeColumn(
                                  e, (d.delta.dx * (arabicLocale ? -1 : 1)));
                              setState(() {});
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            width: 15,
                          ),
                        ),
                      ),
                    ],
                  )),
        ),
      ),
    );
  }

  Widget _gridCell(RowColumnIndex index, DataGridRow row, MyGridColumn column,
          DataGridCell cell) =>
      GestureDetector(
        onDoubleTap: widget.onDoubleTap != null
            ? () => widget.onDoubleTap!(row)
            : () {
                final oldCell = currentCell;
                currentCell = index;

                if (widget.onSelected != null) {
                  widget.onSelected!(row, index);
                }
                if (groupByColumn == null) {
                  if (editMode &&
                      currentCell.toString() != oldCell.toString()) {
                    widget.source.onCellSubmit(row, oldCell, column);
                    editMode = false;
                  } else if (!editMode &&
                      widget.columns[currentCell.columnIndex].allowEditing) {
                    editMode =
                        widget.source.onCellBeginEdit(row, index, column);
                  }
                }
                setState(() {});
              },
        onLongPress: () => widget.onLongPress?.call(row),
        onTap: () {
          final oldCell = currentCell;

          currentCell = index;

          if (widget.onSelected != null) {
            widget.onSelected!(row, index);
          }
          if (groupByColumn == null) {
            if (editMode && currentCell.toString() != oldCell.toString()) {
              // print('sdbds')
              widget.source.onCellCancelEdit(oldCell);
              editMode = false;
            } else if (!editMode &&
                widget.columns[currentCell.columnIndex].allowEditing &&
                oldCell.toString() == currentCell.toString()) {
              editMode = widget.source.onCellBeginEdit(row, index, column);
            }
          }
          setState(() {});
        },
        child: ContextMenuEdited(
          width: 150,
          builder: widget.contextMenu == null
              ? null
              : (context) => widget.contextMenu!.call(context, row, cell),
          child: AnimatedContainer(
            duration: Duration.zero,
            decoration: BoxDecoration(
                border: Border.all(
                    width:
                        currentCell.toString() == index.toString() ? 1.3 : 0.3,
                    color: currentCell.toString() == index.toString() &&
                            widget.manualFocus != false
                        ? Get.theme.colorScheme.primary.withOpacity(0.2)
                        : Colors.grey),
                color: currentCell.toString() == index.toString() &&
                        widget.manualFocus != false
                    ? Get.theme.colorScheme.primary.withOpacity(0.4)
                    : index.rowIndex.isEven
                        ? null
                        : Colors.grey.shade400),
            height: widget.rowHeight,
            width: column.width,
            child: editMode && index.toString() == currentCell.toString()
                ? widget.source
                    .editBuild(cell, column.columnName, index, row, endEdit)
                : widget.source.build(cell, column, index, row),
          ),
        ),
      );

  List getGroups() {
    if (groupByColumn == null) return [];
    var allValues = widget.source.rows.map((e) => e
        .getCells()
        .firstWhere(
            (element) => element.columnName == groupByColumn!.columnName)
        .value);
    if (allValues.isNotEmpty && allValues.first is DateTime) {
      allValues = allValues
          .map((e) => DateTime((e as DateTime).year, e.month, e.day))
          .toList()
        ..sort((a, b) => b.compareTo(a));
    }
    return allValues.toSet().toList();
  }

  List<DataGridRow> getGroupsItems(dynamic value) {
    if (groupByColumn == null) return [];
    return widget.source.rows.where((e) {
      final v = e
          .getCells()
          .firstWhere((el) => el.columnName == groupByColumn!.columnName)
          .value;
      return v is! DateTime
          ? v == value
          : DateTime(v.year, v.month, v.day) == value;
    }).toList();
  }

  dynamic get currentCellValue => widget.source.rows[currentCell.rowIndex].cells
      .firstWhereOrNull((e) =>
          e.columnName == widget.columns[currentCell.columnIndex].columnName)
      ?.value;

  @override
  Widget build(BuildContext context) {
    if (widget.setSelectedCell != null) widget.setSelectedCell!(currentCell);

    // final quickInfo = context.read<QuickInfoBloc>().state;
    // if (quickInfo.showQuickInfoWidget &&
    //     currentCellValue is ConstantsCard &&
    //     !(quickInfo is QuickInfoInitialized &&
    //         currentCellValue == quickInfo.card?.card)) {
    //   context.read<QuickInfoBloc>().add(GetCardInfo(currentCellValue));
    // }
    if ((!editMode && widget.autoFocus) || widget.manualFocus == true) {
      focusNode.requestFocus();
    }
    if (widget.manualFocus == false && editMode) {
      widget.source.onCellCancelEdit(currentCell);
      editMode = false;
    }
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double requiredWidth = 0;
          for (var i in widget.columns) {
            requiredWidth += i.width;
          }
          final scrollableGrid = requiredWidth >= constraints.constrainWidth();
          double spaceForLastColumn = constraints.constrainWidth();
          for (var i in widget.columns) {
            if (i != widget.columns.last) {
              spaceForLastColumn -= i.width;
            }
          }

          Widget headers() => SizedBox(
                height: widget.rowHeight,
                child: Row(
                  children: [
                    _headerCell(MyGridColumn(
                        label: '', columnName: 'index', width: 30)),
                    Expanded(
                      child: NotificationListener(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollController.hasClients) {
                            scrollController.jumpTo(scrollInfo.metrics.pixels);
                          }
                          return true;
                        },
                        child: ListView(
                            physics: const ClampingScrollPhysics(),
                            controller: headerController,
                            // dragStartBehavior: DragStartBehavior.down,
                            // onReorderStart: (index) => print(index),
                            scrollDirection: Axis.horizontal,
                            // buildDefaultDragHandles: false,
                            // physics: const NeverScrollableScrollPhysics(),
                            // shrinkWrap: true,
                            // onReorderStart: (_) {
                            //   print('start');
                            //   setState(() => columnDragging = true);
                            // },
                            // onReorderEnd: (_) =>
                            //     setState(() => columnDragging = false),
                            // onReorder: (oldI, newI) {
                            //   if (widget.onColumnsReorder != null) {
                            //     widget.onColumnsReorder!(oldI, newI);
                            //   }
                            // },
                            children: widget.columns.map<Widget>((e) {
                              return MouseRegion(
                                cursor: widget.onColumnsReorder != null
                                    ? SystemMouseCursors.grab
                                    : SystemMouseCursors.basic,
                                // key: ValueKey(e.columnName),
                                child: Builder(
                                  builder: (ct) {
                                    return !scrollableGrid &&
                                            widget.columns.last == e
                                        ? SizedBox(
                                            height: widget.rowHeight,
                                            width: spaceForLastColumn,
                                            child: _headerCell(e),
                                          )
                                        : _headerCell(e);
                                  },
                                ),
                              );
                            }).toList()
                            // ..insert(
                            //     0,
                            //     _headerCell(MyGridColumn(
                            //         label: '', columnName: 'index', width: 30))),
                            ),
                      ),
                    ),
                  ],
                ),
              );
          Widget grid(List<DataGridRow> rows,
                  [ScrollController? controller,
                  ScrollController? bindingController]) =>
              Column(
                children: [
                  NotificationListener(
                    onNotification: (ScrollNotification scrollInfo) {
                      if ((bindingController ?? indexesController).hasClients) {
                        (bindingController ?? indexesController)
                            .jumpTo(scrollInfo.metrics.pixels);
                      }
                      return true;
                    },
                    child: Expanded(
                      child: SizedBox(
                        width: scrollableGrid ? requiredWidth : null,
                        child: ListView.builder(
                          prototypeItem: SizedBox(height: widget.rowHeight),
                          // shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          controller: controller ?? verticalController,
                          itemCount: rows.length,
                          itemBuilder: (ctx, i) => SizedBox(
                            height: widget.rowHeight,
                            child: Row(
                              children: widget.columns.map((column) {
                                final cell = rows[i]
                                    .getCells()
                                    // [widget.columns.indexOf(column)];
                                    .firstWhere((c) =>
                                        c.columnName == column.columnName);
                                final index = RowColumnIndex(
                                    i, widget.columns.indexOf(column));

                                return !scrollableGrid &&
                                        widget.columns.last == column
                                    ? Expanded(
                                        child: _gridCell(
                                            index, rows[i], column, cell))
                                    : _gridCell(index, rows[i], column, cell);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );

          Widget indexes(List<DataGridRow> rows,
                  [ScrollController? controller,
                  ScrollController? bindingController]) =>
              Column(
                children: [
                  NotificationListener(
                    onNotification: (ScrollNotification scrollInfo) {
                      (bindingController ?? verticalController)
                          .jumpTo(scrollInfo.metrics.pixels);
                      return true;
                    },
                    child: Expanded(
                      child: SizedBox(
                        width: 30,
                        child: ListView.builder(
                          prototypeItem: SizedBox(height: widget.rowHeight),
                          controller: controller ?? indexesController,
                          itemCount: rows.length,
                          itemBuilder: (ctx, i) => Container(
                            decoration: BoxDecoration(
                                border:
                                    Border.all(width: 0.3, color: Colors.grey),
                                color: Get.theme.colorScheme.tertiary),
                            height: widget.rowHeight,
                            width: 30,
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  (i + 1).toString(),
                                  style: widget.headerStyle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              );

          Widget stackedGrid() {
            final groups = getGroups();

            return NotificationListener(
              onNotification: (_) {
                return true;
              },
              child: SizedBox(
                width: scrollableGrid ? requiredWidth + 30 : null,
                child:
                    //  CustomScrollView(
                    //   controller: verticalController,
                    //   slivers: groups.map((e) {
                    //     final group = e;
                    //     final items = getGroupsItems(group);
                    //     final gController = ScrollController();
                    //     final iController = ScrollController();
                    //     return SliverList(
                    //         delegate: SliverChildListDelegate([
                    //       MyExpansionTile(
                    //         tileHeight: widget.rowHeight,
                    //         initialExpanded: false,
                    //         title: Text(group is ConstantsCard
                    //             ? group.nameForLocale
                    //             : group.toString()),
                    //         children: [
                    //           SizedBox(
                    //             height: items.length * widget.rowHeight <= 200
                    //                 ? items.length * widget.rowHeight
                    //                 : 200,
                    //             child: Row(
                    //               children: [
                    //                 indexes(items, iController, gController),
                    //                 Expanded(
                    //                     child:
                    //                         grid(items, gController, iController)),
                    //               ],
                    //             ),
                    //           ),
                    //         ],
                    //       )
                    //     ]));
                    //   }).toList(),
                    // )
                    ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  controller: verticalController,
                  // itemExtent: widget.rowHeight,
                  // prototypeItem: SizedBox(height: widget.rowHeight),
                  itemBuilder: (ctx, i) {
                    final group = groups[i];
                    final items = getGroupsItems(group);
                    final gController = ScrollController();
                    final iController = ScrollController();
                    return MyExpansionTile(
                      tileHeight: widget.rowHeight,
                      initialExpanded: i == 0,
                      title: Text(widget.groupNameBuilder?.call(group) ?? ''
                          // group is ConstantsCard
                          //   ? group.nameForLocale
                          //   : group is DateTime
                          //       ? DateFormat('yyy-MM-dd').format(group)
                          //       : group.toString()
                          ),
                      children: [
                        SizedBox(
                          height: items.length * widget.rowHeight <= 200
                              ? items.length * widget.rowHeight
                              : 200,
                          child: Row(
                            children: [
                              indexes(items, iController, gController),
                              Expanded(
                                  child: grid(items, gController, iController)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  itemCount: groups.length,
                ),
              ),
            );
          }

          return KeyboardListener(
            onKeyEvent: groupByColumn == null ? widget.onKey : (_) {},
            // autofocus: true,
            focusNode: focusNode,
            child: scrollableGrid
                ? Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: Scrollbar(
                      // trackVisibility: true,
                      controller: verticalController,
                      thumbVisibility: verticalController.hasClients &&
                          groupByColumn == null,
                      interactive: true,
                      scrollbarOrientation: arabicLocale
                          ? ScrollbarOrientation.left
                          : ScrollbarOrientation.right,
                      child: Column(
                        children: [
                          headers(),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (groupByColumn == null)
                                  indexes(widget.source.rows),
                                Expanded(
                                  child: NotificationListener(
                                    onNotification:
                                        (ScrollNotification scrollInfo) {
                                      if (headerController.hasClients) {
                                        headerController
                                            .jumpTo(scrollInfo.metrics.pixels);
                                      }
                                      return true;
                                    },
                                    child: SingleChildScrollView(
                                      physics: const ClampingScrollPhysics(),
                                      controller: scrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: groupByColumn == null
                                          ? grid(widget.source.rows)
                                          : stackedGrid(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: verticalController,
                    thumbVisibility: true,
                    scrollbarOrientation: arabicLocale
                        ? ScrollbarOrientation.left
                        : ScrollbarOrientation.right,
                    child: Column(
                      children: [
                        headers(),
                        Expanded(
                          child: Row(
                            children: [
                              if (groupByColumn == null)
                                indexes(widget.source.rows),
                              Expanded(
                                  child: groupByColumn == null
                                      ? grid(widget.source.rows)
                                      : stackedGrid()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _onPointerDown(
      PointerDownEvent event, MyGridColumn column) async {
    // Check if right mouse button clicked
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kSecondaryMouseButton) {
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final menuItem = await showMenu<int>(
          context: context,
          items: [
            PopupMenuItem(child: Text('groupBy'.tr), value: 1),
            // PopupMenuItem(child: Text('Cut'), value: 2),
          ],
          position: RelativeRect.fromSize(
              event.position & Size(0, 0.0), overlay.size));
      // Check if menu item clicked
      switch (menuItem) {
        case 1:
          setState(() => groupByColumn = column);
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          //   content: Text('Copy clicked'),
          //   behavior: SnackBarBehavior.floating,
          // ));
          break;
        case 2:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Cut clicked'),
              behavior: SnackBarBehavior.floating));
          break;
        default:
      }
    }
  }
}

class MyGridColumn {
  final String label;
  final String columnName;
  double width;
  final bool allowEditing;
  final List<Widget> Function(BuildContext)? contextMenuItems;

  MyGridColumn(
      {required this.label,
      required this.columnName,
      this.width = 100,
      this.contextMenuItems,
      this.allowEditing = true});
}

class MyDataGridSource {
  List<DataGridRow> rows = <DataGridRow>[];

  void deleteRow(DataGridRow row) {}

  String firstChar = '';
  final focus = FocusNode();
  final editingController = TextEditingController();

  Widget build(DataGridCell cell, MyGridColumn column, RowColumnIndex cellIndex,
      DataGridRow row) {
    return Container();
  }

  Widget editBuild(DataGridCell cell, String columnName,
      RowColumnIndex cellIndex, DataGridRow row, void Function() submitCell) {
    return Container();
  }

  void onCellCancelEdit(RowColumnIndex cell) {}
  Future<void> onCellSubmit(
      DataGridRow row, RowColumnIndex cell, MyGridColumn column) async {
    firstChar = '';
  }

  bool onCellBeginEdit(
      DataGridRow row, RowColumnIndex cell, MyGridColumn column) {
    return true;
  }
}

class DataGridCell<T> {
  String columnName;
  T? value;
  DataGridCell({required this.columnName, required this.value});
}

class DataGridRow {
  List<DataGridCell> cells;
  dynamic value;
  DataGridRow({required this.cells, this.value});

  List<DataGridCell> getCells() => cells;
  dynamic getValue() => value;
}

class RowColumnIndex {
  final int rowIndex;
  final int columnIndex;
  RowColumnIndex(this.rowIndex, this.columnIndex);
  @override
  String toString() {
    return 'RowColumnIndex($rowIndex, $columnIndex)';
  }
}
