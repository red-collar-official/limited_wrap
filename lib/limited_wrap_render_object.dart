import 'dart:math' as math;

import 'package:flutter/rendering.dart' hide WrapParentData;

import 'models/helpers.dart';

class LimitedRenderWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, WrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, WrapParentData> {
  LimitedRenderWrap({
    List<RenderBox>? children,
    double spacing = 0.0,
    double runSpacing = 0.0,
    Clip clipBehavior = Clip.none,
    int? maxLines,
  }) : _spacing = spacing,
       _runSpacing = runSpacing,
       _maxLines = maxLines,
       _clipBehavior = clipBehavior {
    addAll(children);
  }

  /// Layer handle for clipping overflowing content when clipBehavior is enabled.
  final _clipRectLayer = LayerHandle<ClipRectLayer>();

  /// Tracks whether the content size exceeds the container bounds.
  bool _hasVisualOverflow = false;

  int? get maxLines => _maxLines;
  int? _maxLines;
  set maxLines(int? value) {
    if (_maxLines == value) return;
    _maxLines = value;
    markNeedsLayout();
  }

  double get spacing => _spacing;
  double _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  double get runSpacing => _runSpacing;
  double _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! WrapParentData) {
      child.parentData = WrapParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    double width = 0;
    RenderBox? child = firstChild;

    while (child != null) {
      width = math.max(width, child.getMinIntrinsicWidth(double.infinity));
      child = childAfter(child);
    }

    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    double width = 0;
    RenderBox? child = firstChild;

    while (child != null) {
      width += child.getMaxIntrinsicWidth(double.infinity);
      child = childAfter(child);
    }

    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return computeDryLayout(BoxConstraints(maxWidth: width)).height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeDryLayout(BoxConstraints(maxWidth: width)).height;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeDryLayout(constraints);
  }

  /// Performs dry layout calculation for intrinsic size.
  Size _computeDryLayout(
    BoxConstraints constraints, [
    ChildLayouter layoutChild = ChildLayoutHelper.dryLayoutChild,
  ]) {
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    final mainAxisLimit = constraints.maxWidth;
    final state = LayoutState();

    RenderBox? child = firstChild;
    while (child != null) {
      final childSize = layoutChild(child, childConstraints);
      _processChildInDryLayout(childSize, state, mainAxisLimit);
      child = childAfter(child);
    }

    state.crossAxisExtent += state.runCrossAxisExtent;
    state.mainAxisExtent = math.max(state.mainAxisExtent, state.runMainAxisExtent);

    return constraints.constrain(Size(state.mainAxisExtent, state.crossAxisExtent));
  }

  /// Processes a single child during dry layout, updating run metrics.
  void _processChildInDryLayout(Size childSize, LayoutState state, double mainAxisLimit) {
    final childMainAxisExtent = childSize.width;
    final childCrossAxisExtent = childSize.height;

    if (_shouldStartNewRun(
      state.childCount,
      state.runMainAxisExtent,
      childMainAxisExtent,
      mainAxisLimit,
    )) {
      _finalizeCurrentRun(state);
    }

    state.runMainAxisExtent += childMainAxisExtent;
    state.runCrossAxisExtent = math.max(state.runCrossAxisExtent, childCrossAxisExtent);

    if (state.childCount > 0) {
      state.runMainAxisExtent += spacing;
    }

    state.childCount += 1;
  }

  /// Determines if a new run should be started based on available space.
  bool _shouldStartNewRun(
    int childCount,
    double runMainAxisExtent,
    double childMainAxisExtent,
    double mainAxisLimit,
  ) {
    return childCount > 0 && runMainAxisExtent + spacing + childMainAxisExtent > mainAxisLimit;
  }

  /// Finalizes the current run by updating total extents and resetting run state.
  void _finalizeCurrentRun(LayoutState state) {
    state.mainAxisExtent = math.max(state.mainAxisExtent, state.runMainAxisExtent);
    state.crossAxisExtent += state.runCrossAxisExtent + runSpacing;
    state.runMainAxisExtent = 0.0;
    state.runCrossAxisExtent = 0.0;
    state.childCount = 0;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    _hasVisualOverflow = false;

    if (firstChild == null) {
      size = constraints.smallest;
      return;
    }

    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    final mainAxisLimit = constraints.maxWidth;
    final runMetrics = <RunMetrics>[];
    final state = LayoutState();

    _layoutAllChildren(childConstraints, mainAxisLimit, runMetrics, state);
    _finalizeLayout(constraints, runMetrics, state);
    _positionChildren(runMetrics);
  }

  /// Delegates layout to appropriate method based on maxLines configuration.
  void _layoutAllChildren(
    BoxConstraints childConstraints,
    double mainAxisLimit,
    List<RunMetrics> runMetrics,
    LayoutState state,
  ) {
    if (maxLines == null) {
      _layoutWithoutMaxLines(childConstraints, mainAxisLimit, runMetrics, state);
    } else {
      _layoutWithMaxLines(childConstraints, mainAxisLimit, runMetrics, state);
    }
  }

  /// Layouts all children without line restrictions, hiding only the show-all button.
  void _layoutWithoutMaxLines(
    BoxConstraints childConstraints,
    double mainAxisLimit,
    List<RunMetrics> runMetrics,
    LayoutState state,
  ) {
    RenderBox? child = firstChild;

    while (child != null) {
      final childParentData = child.parentData! as WrapParentData;
      final isShowAllButton = child == lastChild;

      if (isShowAllButton) {
        _hideChild(child, childParentData, runMetrics);
        child = childParentData.nextSibling;
        continue;
      }

      child.layout(childConstraints, parentUsesSize: true);
      _processVisibleChild(child, childParentData, mainAxisLimit, runMetrics, state);
      child = childParentData.nextSibling;
    }

    if (state.childCount > 0) {
      _addFinalRunMetrics(runMetrics, state, false);
    }
  }

  /// Hides a child by applying zero constraints and assigning run index.
  void _hideChild(RenderBox child, WrapParentData parentData, List<RunMetrics> runMetrics) {
    child.layout(BoxConstraints.tight(Size.zero), parentUsesSize: true);
    parentData.runIndex = runMetrics.length;
  }

  /// Processes a visible child: checks for new run, updates metrics, assigns run index.
  void _processVisibleChild(
    RenderBox child,
    WrapParentData parentData,
    double mainAxisLimit,
    List<RunMetrics> runMetrics,
    LayoutState state,
  ) {
    final childMainAxisExtent = child.size.width;
    final childCrossAxisExtent = child.size.height;

    if (_shouldStartNewRun(
      state.childCount,
      state.runMainAxisExtent,
      childMainAxisExtent,
      mainAxisLimit,
    )) {
      _addRunMetrics(runMetrics, state);
    }

    _updateRunMetrics(state, childMainAxisExtent, childCrossAxisExtent, false);
    parentData.runIndex = runMetrics.length;
  }

  /// Layouts children with line restrictions, showing show-all button when content exceeds maxLines.
  void _layoutWithMaxLines(
    BoxConstraints childConstraints,
    double mainAxisLimit,
    List<RunMetrics> runMetrics,
    LayoutState state,
  ) {
    final rowAssignments = _calculateRowAssignments(childConstraints, mainAxisLimit);
    final needsShowAll = _determineIfShowAllNeeded(rowAssignments);

    _layoutChildrenWithRowRestrictions(
      childConstraints,
      mainAxisLimit,
      runMetrics,
      state,
      rowAssignments,
      needsShowAll,
    );

    if (state.childCount > 0) {
      _addFinalRunMetrics(runMetrics, state, false);
    }
  }

  /// Determines if show-all button should be visible based on content rows.
  bool _determineIfShowAllNeeded(Map<RenderBox, int> rowAssignments) {
    final showAllButton = lastChild;
    final maxRowInContent = rowAssignments.entries
        .where((e) => e.key != showAllButton)
        .map((e) => e.value)
        .fold<int>(0, (max, row) => math.max(max, row));

    return maxRowInContent >= maxLines!;
  }

  /// Layouts all children with row restrictions applied.
  void _layoutChildrenWithRowRestrictions(
    BoxConstraints childConstraints,
    double mainAxisLimit,
    List<RunMetrics> runMetrics,
    LayoutState state,
    Map<RenderBox, int> rowAssignments,
    bool needsShowAll,
  ) {
    RenderBox? child = firstChild;
    final showAllButton = lastChild;

    while (child != null) {
      final childParentData = child.parentData! as WrapParentData;
      final isShowAllButton = child == showAllButton;
      final childRow = rowAssignments[child] ?? 0;

      final shouldHide = _shouldHideChildInMaxLines(isShowAllButton, childRow, needsShowAll);

      if (shouldHide) {
        _hideChild(child, childParentData, runMetrics);
        child = childParentData.nextSibling;
        continue;
      }

      child.layout(childConstraints, parentUsesSize: true);
      _processVisibleChild(child, childParentData, mainAxisLimit, runMetrics, state);
      child = childParentData.nextSibling;
    }
  }

  /// Determines if a child should be hidden based on its row and show-all state.
  bool _shouldHideChildInMaxLines(bool isShowAllButton, int childRow, bool needsShowAll) {
    if (isShowAllButton) {
      return !needsShowAll;
    }
    return childRow >= maxLines!;
  }

  /// Calculates row assignments for all children via dry layout.
  /// Returns a map of each child to its row index.
  Map<RenderBox, int> _calculateRowAssignments(
    BoxConstraints childConstraints,
    double mainAxisLimit,
  ) {
    final assignments = <RenderBox, int>{};
    RenderBox? child = firstChild;
    int currentRow = 0;
    double currentRowWidth = 0;

    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);

      final childWidth = child.size.width;
      final needsSpacing = currentRowWidth > 0;
      final totalWidth = currentRowWidth + (needsSpacing ? spacing : 0) + childWidth;

      if (totalWidth > mainAxisLimit && currentRowWidth > 0) {
        currentRow++;
        currentRowWidth = childWidth;
      } else {
        currentRowWidth = totalWidth;
      }

      assignments[child] = currentRow;
      child = childAfter(child);
    }

    return assignments;
  }

  /// Adds current run metrics to the list and resets state for next run.
  void _addRunMetrics(List<RunMetrics> runMetrics, LayoutState state) {
    state.mainAxisExtent = math.max(state.mainAxisExtent, state.runMainAxisExtent);
    state.crossAxisExtent += state.runCrossAxisExtent;

    if (runMetrics.isNotEmpty) {
      state.crossAxisExtent += runSpacing;
    }

    runMetrics.add(RunMetrics(state.runMainAxisExtent, state.runCrossAxisExtent, state.childCount));
    state.runMainAxisExtent = 0.0;
    state.runCrossAxisExtent = 0.0;
    state.childCount = 0;
  }

  /// Updates run metrics by adding child dimensions and spacing.
  void _updateRunMetrics(
    LayoutState state,
    double childMainAxisExtent,
    double childCrossAxisExtent,
    bool isNeedToHideElements,
  ) {
    if (state.childCount > 0) {
      state.runMainAxisExtent += spacing;
    }

    state.runMainAxisExtent += childMainAxisExtent;
    state.runCrossAxisExtent = math.max(state.runCrossAxisExtent, childCrossAxisExtent);
    state.childCount += 1;
  }

  /// Adds final run metrics after all children are processed.
  void _addFinalRunMetrics(
    List<RunMetrics> runMetrics,
    LayoutState state,
    bool isNeedToHideElements,
  ) {
    state.mainAxisExtent = math.max(state.mainAxisExtent, state.runMainAxisExtent);
    state.crossAxisExtent += state.runCrossAxisExtent;

    if (runMetrics.isNotEmpty) {
      state.crossAxisExtent += runSpacing;
    }

    runMetrics.add(RunMetrics(state.runMainAxisExtent, state.runCrossAxisExtent, state.childCount));
  }

  /// Finalizes layout by setting final size and checking for overflow.
  void _finalizeLayout(BoxConstraints constraints, List<RunMetrics> runMetrics, LayoutState state) {
    size = constraints.constrain(Size(state.mainAxisExtent, state.crossAxisExtent));
    _hasVisualOverflow = size.width < state.mainAxisExtent || size.height < state.crossAxisExtent;
  }

  /// Positions all children based on calculated run metrics.
  /// Hidden children are positioned off-screen.
  void _positionChildren(List<RunMetrics> runMetrics) {
    var crossAxisOffset = 0.0;
    RenderBox? child = firstChild;

    for (int i = 0; i < runMetrics.length; ++i) {
      final metrics = runMetrics[i];
      double childMainPosition = 0;

      while (child != null) {
        final childParentData = child.parentData! as WrapParentData;
        if (childParentData.runIndex != i) break;

        if (child.size == Size.zero) {
          childParentData.offset = const Offset(-10000, -10000);
        } else {
          childParentData.offset = Offset(childMainPosition, crossAxisOffset);
          childMainPosition += child.size.width + spacing;
        }

        child = childParentData.nextSibling;
      }

      crossAxisOffset += metrics.crossAxisExtent + runSpacing;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) => _paintChildren(context, offset),
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      _paintChildren(context, offset);
    }
  }

  /// Paints all visible children, skipping zero-sized elements.
  void _paintChildren(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as WrapParentData;
      if (child.size != Size.zero) {
        context.paintChild(child, childParentData.offset + offset);
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('spacing', spacing))
      ..add(DoubleProperty('runSpacing', runSpacing))
      ..add(IntProperty('maxLines', maxLines));
  }
}
