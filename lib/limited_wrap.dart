import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:limited_wrap/limited_wrap_render_object.dart';

/// Wrap widget with line limiting and expandable content support
///
/// Improves standard Wrap with maxLines constraint and smart "Show All" button
/// that automatically appears when content exceeds the visible area
///
/// ```dart
/// UILimitedWrap(
///   spacing: 8.0,
///   runSpacing: 8.0,
///   maxLines: 2,
///   showAllButton: TextButton(
///     onPressed: () {
///       // Handle show all action
///     },
///     child: Text('Show All'),
///   ),
///   children: [
///     Chip(label: Text('Flutter')),
///     Chip(label: Text('Dart')),
///     Chip(label: Text('Mobile')),
///     Chip(label: Text('UI/UX')),
///     // ... more chips
///   ],
/// )
/// ```

class UILimitedWrap extends MultiChildRenderObjectWidget {
  UILimitedWrap({
    super.key,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.clipBehavior = Clip.none,
    List<Widget> children = const <Widget>[],
    this.maxLines,
    required this.showAllButton,
  }) : super(children: [...children, showAllButton]);

  /// Horizontal space between children
  final double spacing;

  /// Vertical space between rows
  final double runSpacing;

  /// How to handle content that overflows the container's bounds.
  ///
  /// Defaults to [Clip.none], meaning overflow content is visible.
  final Clip clipBehavior;

  /// Maximum visible rows before truncation
  ///
  /// When exceeded, showAllButton appears on next row
  /// Null means show all content
  final int? maxLines;

  /// Widget shown when content exceeds maxLines
  ///
  /// Typically a button that expands content
  /// Automatically hidden when all content fits
  /// Example:
  /// ```dart
  /// showAllButton: TextButton(
  ///   onPressed: () => setState(() => _expanded = true),
  ///   child: Text('Show All'),
  /// )
  /// ```
  final Widget showAllButton;

  @override
  LimitedRenderWrap createRenderObject(BuildContext context) {
    return LimitedRenderWrap(
      spacing: spacing,
      runSpacing: runSpacing,
      clipBehavior: clipBehavior,
      maxLines: maxLines,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    LimitedRenderWrap renderObject,
  ) {
    renderObject
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..maxLines = maxLines
      ..clipBehavior = clipBehavior;
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
