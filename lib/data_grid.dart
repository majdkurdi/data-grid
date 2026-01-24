import 'dart:math';

import 'package:data_grid/clipboard_api.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

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
      this.autoFocusGetter,
      this.contextMenu,
      this.shortcuts,
      this.onRebuild,
      this.groupNameBuilder,
      this.oddRowColor,
      this.alt1Shortcut,
      this.alt2Shortcut,
      this.alt3Shortcut,
      this.altEqualShortcut,
      this.rowHeight = 22});
  final MyDataGridSource source;
  final Color? headerColor;
  final Color? oddRowColor;
  final TextStyle? headerStyle;
  List<MyGridColumn> columns;
  final void Function(int, int)? onColumnsReorder;
  final void Function(MyGridColumn column, double dx)? onColumnResize;
  final double rowHeight;
  final MyGridColumn? groupByColumn;
  final void Function(DataGridRow, RowColumnIndex, DataGridCell)? onSelected;
  final void Function(DataGridRow)? onLongPress;
  final void Function(RowColumnIndex)? setSelectedCell;
  final void Function(DataGridRow)? onDoubleTap;
  final bool autoFocus;
  final bool Function()? autoFocusGetter;
  final bool? manualFocus;
  final FocusNode? focusNode;
  final List<ContextMenuTile> Function(BuildContext, DataGridRow, DataGridCell)?
      contextMenu;
  final void Function(
          RowColumnIndex cellIndex, DataGridRow row, DataGridCell cell)?
      alt1Shortcut;
  final void Function(
          RowColumnIndex cellIndex, DataGridRow row, DataGridCell cell)?
      alt2Shortcut;
  final void Function(
          RowColumnIndex cellIndex, DataGridRow row, DataGridCell cell)?
      alt3Shortcut;
  final void Function(
          RowColumnIndex cellIndex, DataGridRow row, DataGridCell cell)?
      altEqualShortcut;
  final Map<LogicalKeyboardKey, void Function(dynamic currenctCellValue)>?
      shortcuts;
  final void Function(dynamic currenctCellValue, dynamic currentRowValue)?
      onRebuild;
  final String Function(dynamic)? groupNameBuilder;

  void reorderColumns(int lastI, int newI) {
    final c = columns.removeAt(lastI);
    columns.insert(newI, c);
  }

  void resizeColumn(MyGridColumn c, double dx, {double? fixWidth}) {
    if (fixWidth != null) {
      columns
          .firstWhere((element) => element.columnName == c.columnName)
          .width = fixWidth;
    } else {
      columns
          .firstWhere((element) => element.columnName == c.columnName)
          .width += dx;
    }
  }

  @override
  State<XtraDataGrid> createState() => _XtraDataGridState();
}

class _XtraDataGridState extends State<XtraDataGrid> {
  RowColumnIndex currentCell = RowColumnIndex(0, 0);
  bool editMode = false;
  bool _endingEditMode = false;
  // bool columnDragging = false;
  late final focusNode = widget.focusNode ?? FocusNode();
  late final searchFieldFocus = FocusNode();
  final scrollController = AutoScrollController();
  final headerController = AutoScrollController();
  final verticalController = AutoScrollController();
  final searchController = TextEditingController();
  // final groupsController = ScrollController();
  final indexesController = AutoScrollController();
  MyGridColumn? searchColumn;
  MyGridColumn? groupByColumn;
  late Map<String, List<GlobalKey>> cellsKeys = Map.fromEntries(
      widget.columns.map((e) => MapEntry(e.columnName, <GlobalKey>[])));

  void resetKeys() {
    cellsKeys = Map.fromEntries(
        widget.columns.map((e) => MapEntry(e.columnName, <GlobalKey>[])));
  }

  void adjustColumnWidth(MyGridColumn column, {bool rebuild = true}) {
    double w = 0;
    for (var key in cellsKeys[column.columnName] ?? <GlobalKey>[]) {
      final context = key.currentContext;
      if (context == null) return;
      final RenderBox box = context.findRenderObject() as RenderBox;
      double width = box.getMaxIntrinsicWidth(double.infinity);
      width += 8;
      if (width > w) {
        w = width;
      }
    }

    widget.resizeColumn(column, w - column.width, fixWidth: w > 50 ? null : 50);
    if (rebuild) setState(() {});
  }

  void sortGridAZ(MyGridColumn column) {
    if (column.compareValuesForSort == null) return;
    widget.source.rows.sort((a, b) {
      final aVal =
          a.cells.firstWhere((e) => e.columnName == column.columnName).value;
      final bVal =
          b.cells.firstWhere((e) => e.columnName == column.columnName).value;
      if (aVal == null && bVal == null) return 0;
      if (aVal == null) return 1;
      if (bVal == null) return -1;
      return column.compareValuesForSort!(aVal, bVal);
    });
    setState(() {});
  }

  void adjustAllColumns() {
    for (var i in widget.columns) {
      adjustColumnWidth(i, rebuild: false);
    }
    setState(() {});
  }

  void onKey(KeyEvent event) async {
    final shiftKeys = [
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight
    ];
    final controlKeys = [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight
    ];
    final altKeys = [
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
    ];
    final keysPressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (event is KeyDownEvent) {
      final oldCell = currentCell;
      final oldEditMode = editMode;
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft && !editMode) {
        currentCell = arabicLocale ? _nextCell() : _previousCell();
        // while (!widget.columns[currentCell.columnIndex].allowEditing) {
        //   currentCell = arabicLocale ? _nextCell() : _previousCell();
        // }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
          !editMode) {
        currentCell = arabicLocale ? _previousCell() : _nextCell();
        // while (!widget.columns[currentCell.columnIndex].allowEditing) {
        //   currentCell = arabicLocale ? _previousCell() : _nextCell();
        // }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
          !editMode) {
        if (currentCell.rowIndex == widget.source.rows.length - 1) {
          currentCell = currentCell;
        } else {
          currentCell = (RowColumnIndex(
              currentCell.rowIndex + 1, currentCell.columnIndex));
        }
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown && !editMode) {
        if (currentCell.rowIndex >= widget.source.rows.length - 11) {
          currentCell = RowColumnIndex(
              widget.source.rows.length - 1, currentCell.columnIndex);
        } else {
          currentCell = (RowColumnIndex(
              currentCell.rowIndex + 10, currentCell.columnIndex));
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp && !editMode) {
        if (HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.home)) {
          currentCell = RowColumnIndex(0, 0);
        } else {
          if (currentCell.rowIndex == 0) {
            currentCell = currentCell;
          } else {
            currentCell = (RowColumnIndex(
                currentCell.rowIndex - 1, currentCell.columnIndex));
          }
        }
      } else if (event.logicalKey == LogicalKeyboardKey.end && !editMode) {
        currentCell =
            RowColumnIndex(currentCell.rowIndex, widget.columns.length - 1);
      } else if (event.logicalKey == LogicalKeyboardKey.home && !editMode) {
        currentCell = RowColumnIndex(currentCell.rowIndex, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp && !editMode) {
        if (currentCell.rowIndex <= 10) {
          currentCell = RowColumnIndex(0, currentCell.columnIndex);
        } else {
          currentCell = (RowColumnIndex(
              currentCell.rowIndex - 10, currentCell.columnIndex));
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape && editMode) {
        widget.source.onCellCancelEdit(currentCell);
        editMode = false;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (HardwareKeyboard.instance.logicalKeysPressed.any((e) => [
              LogicalKeyboardKey.controlLeft,
              LogicalKeyboardKey.controlRight
            ].contains(e))) {
          if (editMode) {
            endEdit(RowColumnIndex(
                currentCell.rowIndex + 1, currentCell.columnIndex));
          } else {
            currentCell = oldCell.rowIndex == widget.source.rows.length - 1
                ? currentCell
                : RowColumnIndex(
                    currentCell.rowIndex + 1, currentCell.columnIndex);
          }
        } else {
          if (!editMode) {
            currentCell = _nextCell();
          }
        }
      } else if (event.logicalKey == LogicalKeyboardKey.f2 &&
          currentCell.rowIndex >= 0 &&
          currentCell.columnIndex >= 0 &&
          widget.columns[currentCell.columnIndex].allowEditing) {
        editMode = widget.source.onCellBeginEdit(
            widget.source.rows[currentCell.rowIndex],
            currentCell,
            widget.columns[currentCell.columnIndex]);
      } else if (event.logicalKey == LogicalKeyboardKey.delete &&
          widget.columns[currentCell.columnIndex].allowEditing &&
          !editMode) {
        if (shiftKeys.any((e) => keysPressed.contains(e)) &&
            widget.source
                    .allowDeleteRow(widget.source.rows[currentCell.rowIndex]) !=
                false) {
          final confirm = await widget.source
              .confirmDeleteRow(widget.source.rows[currentCell.rowIndex]);
          if (confirm) {
            widget.source.deleteRow(widget.source.rows[currentCell.rowIndex]);
          }
        } else {
          widget.source.onCellDelete(currentCell);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.delete &&
          !editMode &&
          shiftKeys.any((e) => keysPressed.contains(e)) &&
          widget.source
                  .allowDeleteRow(widget.source.rows[currentCell.rowIndex]) !=
              false) {
        final confirm = await widget.source
            .confirmDeleteRow(widget.source.rows[currentCell.rowIndex]);
        if (confirm) {
          widget.source.deleteRow(widget.source.rows[currentCell.rowIndex]);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.f8 &&
          widget.columns[currentCell.columnIndex].allowEditing &&
          currentCell.rowIndex != 0 &&
          !editMode &&
          widget.columns[currentCell.columnIndex].allowCopyLastRow) {
        final col = widget.columns[currentCell.columnIndex];
        final cellVal = widget.source.rows[currentCell.rowIndex - 1].cells
            .firstWhere((e) => e.columnName == col.columnName)
            .value;

        widget.source.firstChar = col.cellValueStringforInput != null
            ? col.cellValueStringforInput!(cellVal)
            : cellVal?.toString() ?? '';
        editMode = widget.source.onCellBeginEdit(
            widget.source.rows[currentCell.rowIndex],
            currentCell,
            widget.columns[currentCell.columnIndex]);
        Future.delayed(
            const Duration(milliseconds: 100),
            () => endEdit(currentCell.rowIndex != widget.source.rows.length - 1
                ? RowColumnIndex(
                    currentCell.rowIndex + 1, currentCell.columnIndex)
                : null));
      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
        final shiftPressed =
            keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                keysPressed.contains(LogicalKeyboardKey.shiftRight);
        if (editMode) {
          endEdit(shiftPressed ? _previousCell() : null);
        } else {
          currentCell = shiftPressed ? _previousCell() : _nextCell();
        }
      } else if ([LogicalKeyboardKey.keyV, LogicalKeyboardKey.keyC]
              .contains(event.logicalKey) &&
          controlKeys.any((k) => keysPressed.contains(k))) {
        if (event.logicalKey == LogicalKeyboardKey.keyV) {
          pasteFromClipboard(currentCell);
        } else {
          copyCellContent(widget.source.rows[currentCell.rowIndex]
              .cells[currentCell.columnIndex]);
        }
      } else if (event.logicalKey.keyLabel.replaceArabicNumber() == '1' &&
          altKeys.any((k) => keysPressed.contains(k))) {
        widget.alt1Shortcut?.call(
            currentCell,
            widget.source.rows[currentCell.rowIndex],
            widget.source.rows[currentCell.rowIndex].cells.firstWhere((e) =>
                e.columnName ==
                widget.columns[currentCell.columnIndex].columnName));
      } else if (event.logicalKey.keyLabel.replaceArabicNumber() == '2' &&
          altKeys.any((k) => keysPressed.contains(k))) {
        widget.alt2Shortcut?.call(
            currentCell,
            widget.source.rows[currentCell.rowIndex],
            widget.source.rows[currentCell.rowIndex].cells.firstWhere((e) =>
                e.columnName ==
                widget.columns[currentCell.columnIndex].columnName));
      } else if (event.logicalKey.keyLabel.replaceArabicNumber() == '3' &&
          altKeys.any((k) => keysPressed.contains(k))) {
        widget.alt3Shortcut?.call(
            currentCell,
            widget.source.rows[currentCell.rowIndex],
            widget.source.rows[currentCell.rowIndex].cells.firstWhere((e) =>
                e.columnName ==
                widget.columns[currentCell.columnIndex].columnName));
      } else if ((event.logicalKey == LogicalKeyboardKey.equal) &&
          altKeys.any((k) => keysPressed.contains(k))) {
        widget.altEqualShortcut?.call(
            currentCell,
            widget.source.rows[currentCell.rowIndex],
            widget.source.rows[currentCell.rowIndex].cells.firstWhere((e) =>
                e.columnName ==
                widget.columns[currentCell.columnIndex].columnName));
      } else if ((englishLetters
                  .contains(event.logicalKey.keyLabel.toLowerCase()) ||
              arabicLetters.contains(event.character) ||
              nums.contains(
                  event.logicalKey.keyLabel.replaceAll('Numpad ', '')) ||
              arabicNumbers.contains(
                  event.logicalKey.keyLabel.replaceAll('Numpad ', '')) ||
              event.logicalKey == LogicalKeyboardKey.backspace) &&
          !editMode &&
          !HardwareKeyboard.instance.logicalKeysPressed
              .any((e) => shiftKeys.contains(e)) &&
          widget.columns[currentCell.columnIndex].allowEditing) {
        if (event.logicalKey != LogicalKeyboardKey.delete) {
          widget.source.firstChar = event.character
                  ?.replaceAll('Numpad ', '')
                  .toLowerCase()
                  .replaceArabicNumber() ??
              '';
        }
        editMode = widget.source.onCellBeginEdit(
            widget.source.rows[currentCell.rowIndex],
            currentCell,
            widget.columns[currentCell.columnIndex]);
      } else if (event.logicalKey == LogicalKeyboardKey.f3) {
        await widget.source.onCellSubmit(
            widget.source.rows[currentCell.rowIndex],
            currentCell,
            widget.columns[currentCell.columnIndex]);
        setState(() {});
      } else if (!editMode && event.logicalKey == LogicalKeyboardKey.f10) {
        widget.shortcuts?[LogicalKeyboardKey.f10]?.call(currentCellValue);
        // if (currentCellValue is ConstantsCard) {
        //   context.read<QuickInfoBloc>().add(GetCardInfo(currentCellValue));
        // }
      }
      if (currentCell.toString() != oldCell.toString()) {
        editMode = false;
        Future.delayed(Duration.zero, () {
          verticalController.scrollToIndex(currentCell.rowIndex,
              preferPosition: AutoScrollPosition.middle);
          headerController.scrollToIndex(currentCell.columnIndex,
              preferPosition: AutoScrollPosition.middle);
        });
        // if (scrollController.hasClients &&
        //     currentCell.columnIndex != oldCell.columnIndex) {
        //   if (oldCell.columnIndex == 0 &&
        //       currentCell.columnIndex == widget.columns.length - 1) {
        //     scrollController.animateTo(
        //         scrollController.position.maxScrollExtent,
        //         duration: const Duration(milliseconds: 50),
        //         curve: Curves.ease);
        //   } else if (oldCell.columnIndex == widget.columns.length - 1 &&
        //       currentCell.columnIndex == 0) {
        //     scrollController.animateTo(0,
        //         duration: const Duration(milliseconds: 50), curve: Curves.ease);
        //   } else if (currentCell.columnIndex >= 5 &&
        //       currentCell.columnIndex > oldCell.columnIndex &&
        //       scrollController.offset !=
        //           scrollController.position.maxScrollExtent) {
        //     scrollController.animateTo(scrollController.offset + 100,
        //         duration: const Duration(milliseconds: 50), curve: Curves.ease);
        //   } else if (currentCell.columnIndex <= widget.columns.length - 5 &&
        //       currentCell.columnIndex < oldCell.columnIndex &&
        //       scrollController.offset !=
        //           scrollController.position.minScrollExtent) {
        //     scrollController.animateTo(scrollController.offset - 100,
        //         duration: const Duration(milliseconds: 50), curve: Curves.ease);
        //   }
        // }
        // if (oldCell.rowIndex <= widget.source.rows.length - 7 &&
        //     currentCell.rowIndex < oldCell.rowIndex &&
        //     verticalController.offset != 0 &&
        //     event.logicalKey != LogicalKeyboardKey.pageUp) {
        //   verticalController
        //       .jumpTo(verticalController.offset - widget.rowHeight);
        // } else if (oldCell.rowIndex >= 7 &&
        //     currentCell.rowIndex > oldCell.rowIndex &&
        //     verticalController.offset !=
        //         verticalController.position.maxScrollExtent &&
        //     event.logicalKey != LogicalKeyboardKey.pageDown) {
        //   verticalController
        //       .jumpTo(verticalController.offset + widget.rowHeight);
        // } else if (oldCell.rowIndex == 0 &&
        //     currentCell.rowIndex == widget.source.rows.length - 1) {
        //   verticalController
        //       .jumpTo(verticalController.position.maxScrollExtent);
        // } else if (oldCell.rowIndex == widget.source.rows.length - 1 &&
        //     currentCell.rowIndex == 0) {
        //   verticalController.jumpTo(0);
        // } else if (verticalController.offset <
        //         verticalController.position.maxScrollExtent &&
        //     event.logicalKey == LogicalKeyboardKey.pageDown) {
        //   verticalController.jumpTo(
        //       verticalController.offset + widget.rowHeight * 10 <=
        //               verticalController.position.maxScrollExtent
        //           ? verticalController.offset + widget.rowHeight * 10
        //           : verticalController.position.maxScrollExtent);
        // } else if (verticalController.offset > 0 &&
        //     event.logicalKey == LogicalKeyboardKey.pageUp) {
        //   verticalController.jumpTo(
        //       verticalController.offset - widget.rowHeight * 10 >= 0
        //           ? verticalController.offset - widget.rowHeight * 10
        //           : 0);
        // }
      }
      // print(oldCell.rowIndex
      //      == 0
      // &&
      // currentCell.rowIndex == widget.source.rows.length - 1
      // );
      if (editMode != oldEditMode ||
          currentCell.toString() != oldCell.toString() ||
          !editMode) {
        Future.delayed(Duration.zero, () {
          if (mounted) {
            setState(() {});
            focusNode.requestFocus();
          }
        });
      }
      // Future.delayed(Duration(milliseconds: 10), () => focusNode.requestFocus());
    }
  }

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
    if (!editMode || _endingEditMode) return;
    _endingEditMode = true;
    await widget.source.onCellSubmit(widget.source.rows[currentCell.rowIndex],
        currentCell, widget.columns[currentCell.columnIndex]);
    editMode = false;
    currentCell = nextCell ?? _nextCell();
    // while(!widget.columns[currentCell.columnIndex].allowEditing){
    // currentCell = _nextCell();
    // }
    setState(() {});
    focusNode.requestFocus();
    _endingEditMode = false;
  }

  void pasteFromClipboard(RowColumnIndex cellIndex) async {
    final clipboardContent = await dataFromClipboard();
    if (clipboardContent == null) return;
    if (clipboardContent is String) {
      widget.source.firstChar = clipboardContent;
      editMode = widget.source.onCellBeginEdit(
          widget.source.rows[cellIndex.rowIndex],
          cellIndex,
          widget.columns[cellIndex.columnIndex]);
    } else if (clipboardContent is List<List<String>> &&
        widget.source.rowFromClipboard != null) {
      final rowsToDelete = widget.source.rows
          .getRange(
              cellIndex.rowIndex,
              widget.source.rows.length <= clipboardContent.length
                  ? widget.source.rows.length
                  : cellIndex.rowIndex + clipboardContent.length)
          .toList();

      for (var i in rowsToDelete) {
        widget.source.deleteRow(i);
      }
      final listToAdd = clipboardContent.reversed
          .map((i) => widget.source.rowFromClipboard!(i))
          .toList();
      for (var i in listToAdd) {
        widget.source.insertRow(cellIndex.rowIndex, i);
      }
      setState(() {});
    }
  }

  void copyCellContent(DataGridCell cell) async {
    copyToClipboard(cell.value.toString());
  }

  @override
  void initState() {
    widget.source._columns = widget.columns;
    groupByColumn = widget.groupByColumn;

    if (widget.autoFocus || widget.autoFocusGetter?.call() == true) {
      Future.delayed(
          const Duration(milliseconds: 100), () => focusNode.requestFocus());
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant XtraDataGrid oldWidget) {
    widget.source._columns = widget.columns;
    groupByColumn = widget.groupByColumn;
    if (oldWidget.source != widget.source ||
        currentCell.rowIndex >= widget.source.rows.length ||
        currentCell.columnIndex >= widget.columns.length) {
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
    searchController.dispose();
    searchFieldFocus.dispose();
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
      builder: (c) => [
        ContextMenuTile(
            onTap: () {
              Navigator.of(c).pop();
              adjustColumnWidth(e);
            },
            title: 'autoFit'.tr),
        ContextMenuTile(
            onTap: () {
              Navigator.of(c).pop();
              adjustAllColumns();
            },
            title: 'autoFitAllFields'.tr),
            if(e.canSearchInColumn)
        ContextMenuTile(
            onTap: () {
              Navigator.of(c).pop();
              searchController.text = '';
              setState(() => searchColumn = e);
              searchFieldFocus.requestFocus();
            },
            title: 'searchInColumn'.tr),
        ...e.contextMenuItems?.call(c) ?? [],
      ],
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
          DataGridCell cell, GlobalKey key) =>
      GestureDetector(
        onDoubleTap: widget.onDoubleTap != null
            ? () => widget.onDoubleTap!(row)
            : () {
                final oldCell = currentCell;
                currentCell = index;

                if (widget.onSelected != null) {
                  widget.onSelected!(row, index, cell);
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
        onTapDown: (_) async {
          focusNode.requestFocus();
          // Future.delayed(Duration(milliseconds: 1000), () {
          // print(focusNode.hasFocus);
          // });
          final oldCell = currentCell;

          currentCell = index;

          if (widget.onSelected != null) {
            widget.onSelected!(row, index, cell);
          }
          if (groupByColumn == null) {
            if (editMode && currentCell.toString() != oldCell.toString()) {
              // print('sdbds')
              await widget.source.onCellSubmit(
                  widget.source.rows[oldCell.rowIndex],
                  oldCell,
                  widget.columns[oldCell.columnIndex]);
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
              : (context) => [
                    ...widget.contextMenu!.call(context, row, cell),
                    ...widget.source
                        .buildContextMenu(context, cell, column, index, row),
                    ContextMenuTile(
                        title: 'copy'.tr,
                        onTap: () {
                          setState(() {
                            Navigator.of(context).pop();
                            copyCellContent(cell);
                          });
                        }),
                    if (column.allowEditing)
                      ContextMenuTile(
                          title: 'paste'.tr,
                          onTap: () {
                            setState(() {
                              Navigator.of(context).pop();
                              pasteFromClipboard(index);
                            });
                          }),
                    if (column.compareValuesForSort != null)
                      ContextMenuTile(
                          onTap: () {
                            Navigator.of(context).pop();
                            sortGridAZ(column);
                          },
                          title: 'sortAZ'.tr),
                    if ((column.allowEditing &&
                            widget.source.allowInsertingRow(index.rowIndex) ==
                                null) ||
                        widget.source.allowInsertingRow(index.rowIndex) == true)
                      ContextMenuTile(
                          title: 'insertRow'.tr,
                          onTap: () {
                            setState(() {
                              Navigator.of(context).pop();
                              widget.source.insertRow(
                                  index.rowIndex + 1, DataGridRow(cells: []));
                            });
                          }),
                    if (widget.source.rows.length > 1 &&
                        ((column.allowEditing &&
                                widget.source.allowDeleteRow(row) == null) ||
                            widget.source.allowDeleteRow(row) == true))
                      ContextMenuTile(
                          title: '${'deleteRow'.tr} (Shift + Del)',
                          onTap: () {
                            setState(() {
                              Navigator.of(context).pop();
                              widget.source.deleteRow(row);
                            });
                          }),
                  ],
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
                    : searchColumn?.columnName == column.columnName &&
                            searchController.text.isNotEmpty &&
                            cell.value
                                .toString()
                                .contains(searchController.text)
                        ? Colors.amber[400]
                        : index.rowIndex.isEven
                            ? Colors.white
                            : widget.oddRowColor ?? Colors.grey.shade400),
            height: widget.rowHeight,
            width: column.width,
            child: editMode && index.toString() == currentCell.toString()
                ? widget.source
                    .editBuild(cell, column.columnName, index, row, endEdit)
                : widget.source
                    .build(cell, column, index, row, currentCell, key),
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

  dynamic get currentCellValue => widget.source.rows.isEmpty
      ? null
      : widget.source.rows[currentCell.rowIndex].cells
          .firstWhereOrNull((e) =>
              e.columnName ==
              widget.columns[currentCell.columnIndex].columnName)
          ?.value;
  dynamic get currentRowValue => widget.source.rows.isEmpty
      ? null
      : widget.source.rows[currentCell.rowIndex].getValue();

  @override
  Widget build(BuildContext context) {
    cellsKeys = Map.fromEntries(
        widget.columns.map((e) => MapEntry(e.columnName, <GlobalKey>[])));
    if (widget.setSelectedCell != null) widget.setSelectedCell!(currentCell);
    widget.onRebuild?.call(currentCellValue, currentRowValue);
    // final quickInfo = context.read<QuickInfoBloc>().state;
    // if (quickInfo.showQuickInfoWidget &&
    //     currentCellValue is ConstantsCard &&
    //     !(quickInfo is QuickInfoInitialized &&
    //         currentCellValue == quickInfo.card?.card)) {
    //   context.read<QuickInfoBloc>().add(GetCardInfo(currentCellValue));
    // }
    if ((!editMode &&
            (widget.autoFocus || widget.autoFocusGetter?.call() == true)) ||
        widget.manualFocus == true) {
      focusNode.requestFocus();
    }
    if (widget.manualFocus == false && editMode) {
      widget.source.onCellCancelEdit(currentCell);
      editMode = false;
    }
    return Column(
      children: [
        if (searchColumn != null)
          Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: searchFieldFocus,
                  controller: searchController,
                  decoration: InputDecoration(
                      hint: Text('${'searchIn'.tr} ${searchColumn!.label}')),
                  onSubmitted: (value) => setState(() {}),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => searchColumn = null);
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        Expanded(
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                double requiredWidth = 0;
                for (var i in widget.columns) {
                  requiredWidth += i.width;
                }
                final scrollableGrid =
                    requiredWidth >= constraints.constrainWidth();
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
                                if (scrollController.hasClients &&
                                    scrollController.position.pixels !=
                                        scrollInfo.metrics.pixels) {
                                  scrollController
                                      .jumpTo(scrollInfo.metrics.pixels);
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
                                    final i = widget.columns.indexOf(e);
                                    return AutoScrollTag(
                                      index: i,
                                      controller: headerController,
                                      key: ValueKey(i),
                                      child: MouseRegion(
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
                                                    width:
                                                        spaceForLastColumn - 30,
                                                    child: _headerCell(e),
                                                  )
                                                : _headerCell(e);
                                          },
                                        ),
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
                        [AutoScrollController? controller,
                        AutoScrollController? bindingController]) =>
                    Column(
                      children: [
                        NotificationListener(
                          onNotification: (ScrollNotification scrollInfo) {
                            if ((bindingController ?? indexesController)
                                    .hasClients &&
                                (bindingController ?? indexesController)
                                        .position
                                        .pixels !=
                                    scrollInfo.metrics.pixels) {
                              (bindingController ?? indexesController)
                                  .jumpTo(scrollInfo.metrics.pixels);
                            }
                            return true;
                          },
                          child: Expanded(
                            child: SizedBox(
                              width: scrollableGrid ? requiredWidth : null,
                              child: ListView.builder(
                                prototypeItem:
                                    SizedBox(height: widget.rowHeight),
                                // shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                controller: controller ?? verticalController,
                                itemCount: rows.length,
                                itemBuilder: (ctx, i) => AutoScrollTag(
                                  controller: controller ?? verticalController,
                                  key: ValueKey(i),
                                  index: i,
                                  child: SizedBox(
                                    height: widget.rowHeight,
                                    child: Row(
                                      children: widget.columns.map((column) {
                                        final cell = rows[i]
                                            .getCells()
                                            // [widget.columns.indexOf(column)];
                                            .firstWhereOrNull((c) =>
                                                c.columnName ==
                                                column.columnName);
                                        if (cell == null) {
                                          print(column.columnName);
                                        }
                                        cell!;
                                        final index = RowColumnIndex(
                                            i, widget.columns.indexOf(column));
                                        final k = GlobalKey();
                                        cellsKeys[column.columnName]?.add(k);
                                        return !scrollableGrid &&
                                                widget.columns.last == column
                                            ? Expanded(
                                                child: _gridCell(index, rows[i],
                                                    column, cell, k))
                                            : _gridCell(index, rows[i], column,
                                                cell, k);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );

                Widget indexes(List<DataGridRow> rows,
                        [AutoScrollController? controller,
                        AutoScrollController? bindingController]) =>
                    Column(
                      children: [
                        NotificationListener(
                          onNotification: (ScrollNotification scrollInfo) {
                            if ((bindingController ?? verticalController)
                                    .position
                                    .pixels !=
                                scrollInfo.metrics.pixels) {
                              (bindingController ?? verticalController)
                                  .jumpTo(scrollInfo.metrics.pixels);
                            }
                            return true;
                          },
                          child: Expanded(
                            child: SizedBox(
                              width: 30,
                              child: ListView.builder(
                                physics: const ClampingScrollPhysics(),
                                prototypeItem:
                                    SizedBox(height: widget.rowHeight),
                                controller: controller ?? indexesController,
                                itemCount: rows.length,
                                itemBuilder: (ctx, i) => Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 0.3, color: Colors.grey),
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

                  return SizedBox(
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
                        final gController = AutoScrollController();
                        final iController = AutoScrollController();
                        return MyExpansionTile(
                          tileHeight: widget.rowHeight,
                          initialExpanded: i == 0,
                          title: Text(widget.groupNameBuilder?.call(group) ??
                                  group.toString()
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
                                      child: grid(
                                          items, gController, iController)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      itemCount: groups.length,
                    ),
                  );
                }

                return KeyboardListener(
                  onKeyEvent: groupByColumn == null ? onKey : (_) {},
                  // autofocus: true,
                  focusNode: focusNode,
                  child: scrollableGrid
                      ? Scrollbar(
                          // trackVisibility: true,
                          interactive: true,
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
                                            if (headerController.hasClients &&
                                                headerController
                                                        .position.pixels !=
                                                    scrollInfo.metrics.pixels) {
                                              headerController.jumpTo(
                                                  scrollInfo.metrics.pixels);
                                            }
                                            return true;
                                          },
                                          child: SingleChildScrollView(
                                            physics:
                                                const ClampingScrollPhysics(),
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
          ),
        ),
      ],
    );
  }

  // Future<void> _onPointerDown(
  //     PointerDownEvent event, MyGridColumn column) async {
  //   // Check if right mouse button clicked
  //   if (event.kind == PointerDeviceKind.mouse &&
  //       event.buttons == kSecondaryMouseButton) {
  //     final overlay =
  //         Overlay.of(context).context.findRenderObject() as RenderBox;
  //     final menuItem = await showMenu<int>(
  //         context: context,
  //         items: [
  //           PopupMenuItem(child: Text('groupBy'.tr), value: 1),
  //           // PopupMenuItem(child: Text('Cut'), value: 2),
  //         ],
  //         position: RelativeRect.fromSize(
  //             event.position & Size(0, 0.0), overlay.size));
  //     // Check if menu item clicked
  //     switch (menuItem) {
  //       case 1:
  //         setState(() => groupByColumn = column);
  //         // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         //   content: Text('Copy clicked'),
  //         //   behavior: SnackBarBehavior.floating,
  //         // ));
  //         break;
  //       case 2:
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //             content: Text('Cut clicked'),
  //             behavior: SnackBarBehavior.floating));
  //         break;
  //       default:
  //     }
  //   }
  // }
}

class ContextMenuTile extends StatelessWidget {
  const ContextMenuTile({
    super.key,
    required this.onTap,
    required this.title,
  });
  final void Function() onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: Get.textTheme.bodySmall),
        ));
  }
}

class MyGridColumn {
  final String label;
  final String columnName;
  double width;
  final bool allowEditing;
  final bool allowCopyLastRow;
  final String Function(dynamic)? cellValueStringforInput;
  // final bool searchableColumn;
  final List<Widget> Function(BuildContext)? contextMenuItems;
  final int Function(dynamic a, dynamic b)? compareValuesForSort;
  final bool canSearchInColumn;

  MyGridColumn({
    required this.label,
    required this.columnName,
    this.width = 100,
    this.contextMenuItems,
    this.compareValuesForSort,
    this.cellValueStringforInput,
    this.allowEditing = true,
    this.allowCopyLastRow = false,
    this.canSearchInColumn = false,
    // this.searchableColumn = true,
  });
}

// ignore: must_be_immutable
class MyDataGridSource extends Equatable {
  List<MyGridColumn>? _columns;
  List<MyGridColumn> get columns => _columns ?? [];
  final int id;

  MyDataGridSource({int? iid}) : id = iid ?? Random().nextInt(9999);

  List<DataGridRow> rows = <DataGridRow>[];

  void deleteRow(DataGridRow row) {}
  void onCellDelete(RowColumnIndex cellIndex) {}
  bool? allowDeleteRow(DataGridRow row) => null;
  Future<bool> confirmDeleteRow(DataGridRow row) async => false;
  bool? allowInsertingRow(int rowIndex) => null;
  void insertRow(int index, DataGridRow row) {}

  DataGridRow Function(List<String>)? rowFromClipboard;
  String firstChar = '';
  final focus = FocusNode();
  final editingController = TextEditingController();

  Widget build(DataGridCell cell, MyGridColumn column, RowColumnIndex cellIndex,
      DataGridRow row, RowColumnIndex currentCell, GlobalKey key) {
    return Container();
  }

  List<Widget> buildContextMenu(BuildContext menuCtx, DataGridCell cell,
      MyGridColumn column, RowColumnIndex cellIndex, DataGridRow row) {
    return [];
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

  @override
  List<Object?> get props => [id];
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
