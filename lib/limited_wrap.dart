import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:limited_wrap/limited_wrap_render_object.dart';

/// Wrap widget with line limiting and expandable content support
///
/// Improves standard Wrap with maxLines constraint and smart button
/// that manages content expansion based on overflow
///
/// Button visibility logic:
/// - maxLines = null, isLimited = true: button always visible
/// - maxLines = null, isLimited = false: button always hidden
/// - maxLines set, isLimited = true: button shown only if content overflows
/// - maxLines set, isLimited = false: throws assertion error
///
/// ```dart
/// UILimitedWrap(
///   spacing: 8.0,
///   runSpacing: 8.0,
///   maxLines: 2,
///   isLimited: true,
///   changeExpansionButton: TextButton(
///     onPressed: () {
///       // Handle expansion action
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
    this.maxLines,
    this.isLimited = true,
    required this.changeExpansionButton,
    List<Widget> children = const <Widget>[],
  })  : assert(
          maxLines == null || isLimited,
          'When maxLines is set, isLimited must be true. '
          'Use isLimited: false only with maxLines: null for unlimited mode without button.',
        ),
        super(children: [...children, changeExpansionButton]);

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
  /// When exceeded and isLimited = true, changeExpansionButton appears on next row
  /// When null, behavior depends on isLimited:
  /// - isLimited = true: all content visible, button always shown
  /// - isLimited = false: all content visible, button hidden
  final int? maxLines;

  /// Whether the wrap is in limited mode (manages button visibility)
  ///
  /// - true: Button visibility depends on maxLines and content overflow
  /// - false: Button is always hidden (only valid when maxLines = null)
  ///
  /// When maxLines is set, this must be true (enforced by assertion)
  final bool isLimited;

  /// Widget shown to change expansion state
  ///
  /// Visibility is automatically managed based on maxLines, isLimited, and content overflow:
  /// - maxLines = null, isLimited = true: always visible
  /// - maxLines = null, isLimited = false: always hidden
  /// - maxLines set, content fits: hidden (size = 0)
  /// - maxLines set, content overflows: visible on row maxLines + 1
  ///
  /// Typically contains a button like "Show All" or "Show Less"
  /// Example:
  /// ```dart
  /// changeExpansionButton: InkWell(
  ///   onTap: () => setState(() => _expanded = !_expanded),
  ///   child: Text(_expanded ? 'Show Less' : 'Show All'),
  /// )
  /// ```
  final Widget changeExpansionButton;

  @override
  LimitedRenderWrap createRenderObject(BuildContext context) {
    return LimitedRenderWrap(
      spacing: spacing,
      runSpacing: runSpacing,
      clipBehavior: clipBehavior,
      maxLines: maxLines,
      isLimited: isLimited,
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
      ..isLimited = isLimited
      ..clipBehavior = clipBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('spacing', spacing))
      ..add(DoubleProperty('runSpacing', runSpacing))
      ..add(IntProperty('maxLines', maxLines))
      ..add(DiagnosticsProperty<bool>('isLimited', isLimited));
  }
}