import 'package:flutter/rendering.dart';
import 'package:limited_wrap/limited_wrap_render_object.dart';

/// Parent data for children of [LimitedRenderWrap].
/// Stores which run index the child belongs to for positioning.
class WrapParentData extends ContainerBoxParentData<RenderBox> {
  int runIndex = 0;
}
