part of "../nb_maps_flutter.dart";

abstract class LayerProperties {
  Map<String, dynamic> toJson();
}

class SymbolLayerProperties implements LayerProperties {
  // Paint Properties
  /// The opacity at which the icon will be drawn.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconOpacity;

  /// The color of the icon. This can only be used with sdf icons.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconColor;

  /// The color of the icon's halo. Icon halos can only be used with SDF
  /// icons.
  ///
  /// Type: color
  ///   default: rgba(0, 0, 0, 0)
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconHaloColor;

  /// Distance of halo to the icon outline.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconHaloWidth;

  /// Fade out the halo towards the outside.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconHaloBlur;

  /// Distance that the icon's anchor is moved from its original placement.
  /// Positive values indicate right and down, while negative values
  /// indicate left and up.
  ///
  /// Type: array
  ///   default: [0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconTranslate;

  /// Controls the frame of reference for `icon-translate`.
  ///
  /// Type: enum
  ///   default: map
  /// Options:
  ///   "map"
  ///      Icons are translated relative to the map.
  ///   "viewport"
  ///      Icons are translated relative to the viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconTranslateAnchor;

  /// The opacity at which the text will be drawn.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textOpacity;

  /// The color with which the text will be drawn.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textColor;

  /// The color of the text's halo, which helps it stand out from
  /// backgrounds.
  ///
  /// Type: color
  ///   default: rgba(0, 0, 0, 0)
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textHaloColor;

  /// Distance of halo to the font outline. Max text halo width is 1/4 of
  /// the font-size.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textHaloWidth;

  /// The halo's fadeout distance towards the outside.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textHaloBlur;

  /// Distance that the text's anchor is moved from its original placement.
  /// Positive values indicate right and down, while negative values
  /// indicate left and up.
  ///
  /// Type: array
  ///   default: [0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textTranslate;

  /// Controls the frame of reference for `text-translate`.
  ///
  /// Type: enum
  ///   default: map
  /// Options:
  ///   "map"
  ///      The text is translated relative to the map.
  ///   "viewport"
  ///      The text is translated relative to the viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textTranslateAnchor;

  // Layout Properties
  /// Label placement relative to its geometry.
  ///
  /// Type: enum
  ///   default: point
  /// Options:
  ///   "point"
  ///      The label is placed at the point where the geometry is located.
  ///   "line"
  ///      The label is placed along the line of the geometry. Can only be
  ///      used on `LineString` and `Polygon` geometries.
  ///   "line-center"
  ///      The label is placed at the center of the line of the geometry.
  ///      Can only be used on `LineString` and `Polygon` geometries. Note
  ///      that a single feature in a vector tile may contain multiple line
  ///      geometries.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic symbolPlacement;

  /// Distance between two symbol anchors.
  ///
  /// Type: number
  ///   default: 250
  ///   minimum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic symbolSpacing;

  /// If true, the symbols will not cross tile edges to avoid mutual
  /// collisions. Recommended in layers that don't have enough padding in
  /// the vector tile to prevent collisions, or if it is a point symbol
  /// layer placed after a line symbol layer. When using a client that
  /// supports global collision detection, like NbMaps GL JS version 0.42.0
  /// or greater, enabling this property is not needed to prevent clipped
  /// labels at tile boundaries.
  ///
  /// Type: boolean
  ///   default: false
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic symbolAvoidEdges;

  /// Sorts features in ascending order based on this value. Features with
  /// lower sort keys are drawn and placed first.  When `icon-allow-overlap`
  /// or `text-allow-overlap` is `false`, features with a lower sort key
  /// will have priority during placement. When `icon-allow-overlap` or
  /// `text-allow-overlap` is set to `true`, features with a higher sort key
  /// will overlap over features with a lower sort key.
  ///
  /// Type: number
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic symbolSortKey;

  /// Controls the order in which overlapping symbols in the same layer are
  /// rendered
  ///
  /// Type: enum
  ///   default: auto
  /// Options:
  ///   "auto"
  ///      If `symbol-sort-key` is set, sort based on that. Otherwise sort
  ///      symbols by their y-position relative to the viewport.
  ///   "viewport-y"
  ///      Symbols will be sorted by their y-position relative to the
  ///      viewport.
  ///   "source"
  ///      Symbols will be rendered in the same order as the source data
  ///      with no sorting applied.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic symbolZOrder;

  /// If true, the icon will be visible even if it collides with other
  /// previously drawn symbols.
  ///
  /// Type: boolean
  ///   default: false
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconAllowOverlap;

  /// If true, other symbols can be visible even if they collide with the
  /// icon.
  ///
  /// Type: boolean
  ///   default: false
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconIgnorePlacement;

  /// If true, text will display without their corresponding icons when the
  /// icon collides with other symbols and the text does not.
  ///
  /// Type: boolean
  ///   default: false
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconOptional;

  /// In combination with `symbol-placement`, determines the rotation
  /// behavior of icons.
  ///
  /// Type: enum
  ///   default: auto
  /// Options:
  ///   "map"
  ///      When `symbol-placement` is set to `point`, aligns icons
  ///      east-west. When `symbol-placement` is set to `line` or
  ///      `line-center`, aligns icon x-axes with the line.
  ///   "viewport"
  ///      Produces icons whose x-axes are aligned with the x-axis of the
  ///      viewport, regardless of the value of `symbol-placement`.
  ///   "auto"
  ///      When `symbol-placement` is set to `point`, this is equivalent to
  ///      `viewport`. When `symbol-placement` is set to `line` or
  ///      `line-center`, this is equivalent to `map`.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconRotationAlignment;

  /// Scales the original size of the icon by the provided factor. The new
  /// pixel size of the image will be the original pixel size multiplied by
  /// `icon-size`. 1 is the original size; 3 triples the size of the image.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconSize;

  /// Scales the icon to fit around the associated text.
  ///
  /// Type: enum
  ///   default: none
  /// Options:
  ///   "none"
  ///      The icon is displayed at its intrinsic aspect ratio.
  ///   "width"
  ///      The icon is scaled in the x-dimension to fit the width of the
  ///      text.
  ///   "height"
  ///      The icon is scaled in the y-dimension to fit the height of the
  ///      text.
  ///   "both"
  ///      The icon is scaled in both x- and y-dimensions.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconTextFit;

  /// Size of the additional area added to dimensions determined by
  /// `icon-text-fit`, in clockwise order: top, right, bottom, left.
  ///
  /// Type: array
  ///   default: [0, 0, 0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconTextFitPadding;

  /// Name of image in sprite to use for drawing an image background.
  ///
  /// Type: resolvedImage
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconImage;

  /// Rotates the icon clockwise.
  ///
  /// Type: number
  ///   default: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconRotate;

  /// Size of the additional area around the icon bounding box used for
  /// detecting symbol collisions.
  ///
  /// Type: number
  ///   default: 2
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconPadding;

  /// If true, the icon may be flipped to prevent it from being rendered
  /// upside-down.
  ///
  /// Type: boolean
  ///   default: false
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconKeepUpright;

  /// Offset distance of icon from its anchor. Positive values indicate
  /// right and down, while negative values indicate left and up. Each
  /// component is multiplied by the value of `icon-size` to obtain the
  /// final offset in pixels. When combined with `icon-rotate` the offset
  /// will be as if the rotated direction was up.
  ///
  /// Type: array
  ///   default: [0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconOffset;

  /// Part of the icon placed closest to the anchor.
  ///
  /// Type: enum
  ///   default: center
  /// Options:
  ///   "center"
  ///      The center of the icon is placed closest to the anchor.
  ///   "left"
  ///      The left side of the icon is placed closest to the anchor.
  ///   "right"
  ///      The right side of the icon is placed closest to the anchor.
  ///   "top"
  ///      The top of the icon is placed closest to the anchor.
  ///   "bottom"
  ///      The bottom of the icon is placed closest to the anchor.
  ///   "top-left"
  ///      The top left corner of the icon is placed closest to the anchor.
  ///   "top-right"
  ///      The top right corner of the icon is placed closest to the anchor.
  ///   "bottom-left"
  ///      The bottom left corner of the icon is placed closest to the
  ///      anchor.
  ///   "bottom-right"
  ///      The bottom right corner of the icon is placed closest to the
  ///      anchor.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic iconAnchor;

  /// Orientation of icon when map is pitched.
  ///
  /// Type: enum
  ///   default: auto
  /// Options:
  ///   "map"
  ///      The icon is aligned to the plane of the map.
  ///   "viewport"
  ///      The icon is aligned to the plane of the viewport.
  ///   "auto"
  ///      Automatically matches the value of `icon-rotation-alignment`.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic iconPitchAlignment;

  /// Orientation of text when map is pitched.
  ///
  /// Type: enum
  ///   default: auto
  /// Options:
  ///   "map"
  ///      The text is aligned to the plane of the map.
  ///   "viewport"
  ///      The text is aligned to the plane of the viewport.
  ///   "auto"
  ///      Automatically matches the value of `text-rotation-alignment`.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textPitchAlignment;

  /// In combination with `symbol-placement`, determines the rotation
  /// behavior of the individual glyphs forming the text.
  ///
  /// Type: enum
  ///   default: auto
  /// Options:
  ///   "map"
  ///      When `symbol-placement` is set to `point`, aligns text east-west.
  ///      When `symbol-placement` is set to `line` or `line-center`, aligns
  ///      text x-axes with the line.
  ///   "viewport"
  ///      Produces glyphs whose x-axes are aligned with the x-axis of the
  ///      viewport, regardless of the value of `symbol-placement`.
  ///   "auto"
  ///      When `symbol-placement` is set to `point`, this is equivalent to
  ///      `viewport`. When `symbol-placement` is set to `line` or
  ///      `line-center`, this is equivalent to `map`.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textRotationAlignment;

  /// Value to use for a text label. If a plain `string` is provided, it
  /// will be treated as a `formatted` with default/inherited formatting
  /// options.
  ///
  /// Type: formatted
  ///   default:
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textField;

  /// Font stack to use for displaying text.
  ///
  /// Type: array
  ///   default: [Open Sans Regular, Arial Unicode MS Regular]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textFont;

  /// Font size.
  ///
  /// Type: number
  ///   default: 16
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textSize;

  /// The maximum line width for text wrapping.
  ///
  /// Type: number
  ///   default: 10
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textMaxWidth;

  /// Text leading value for multi-line text.
  ///
  /// Type: number
  ///   default: 1.2
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textLineHeight;

  /// Text tracking amount.
  ///
  /// Type: number
  ///   default: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textLetterSpacing;

  /// Text justification options.
  ///
  /// Type: enum
  ///   default: center
  /// Options:
  ///   "auto"
  ///      The text is aligned towards the anchor position.
  ///   "left"
  ///      The text is aligned to the left.
  ///   "center"
  ///      The text is centered.
  ///   "right"
  ///      The text is aligned to the right.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textJustify;

  /// Radial offset of text, in the direction of the symbol's anchor. Useful
  /// in combination with `text-variable-anchor`, which defaults to using
  /// the two-dimensional `text-offset` if present.
  ///
  /// Type: number
  ///   default: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textRadialOffset;

  /// To increase the chance of placing high-priority labels on the map, you
  /// can provide an array of `text-anchor` locations: the renderer will
  /// attempt to place the label at each location, in order, before moving
  /// onto the next label. Use `text-justify: auto` to choose justification
  /// based on anchor position. To apply an offset, use the
  /// `text-radial-offset` or the two-dimensional `text-offset`.
  ///
  /// Type: array
  /// Options:
  ///   "center"
  ///      The center of the text is placed closest to the anchor.
  ///   "left"
  ///      The left side of the text is placed closest to the anchor.
  ///   "right"
  ///      The right side of the text is placed closest to the anchor.
  ///   "top"
  ///      The top of the text is placed closest to the anchor.
  ///   "bottom"
  ///      The bottom of the text is placed closest to the anchor.
  ///   "top-left"
  ///      The top left corner of the text is placed closest to the anchor.
  ///   "top-right"
  ///      The top right corner of the text is placed closest to the anchor.
  ///   "bottom-left"
  ///      The bottom left corner of the text is placed closest to the
  ///      anchor.
  ///   "bottom-right"
  ///      The bottom right corner of the text is placed closest to the
  ///      anchor.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textVariableAnchor;

  /// Part of the text placed closest to the anchor.
  ///
  /// Type: enum
  ///   default: center
  /// Options:
  ///   "center"
  ///      The center of the text is placed closest to the anchor.
  ///   "left"
  ///      The left side of the text is placed closest to the anchor.
  ///   "right"
  ///      The right side of the text is placed closest to the anchor.
  ///   "top"
  ///      The top of the text is placed closest to the anchor.
  ///   "bottom"
  ///      The bottom of the text is placed closest to the anchor.
  ///   "top-left"
  ///      The top left corner of the text is placed closest to the anchor.
  ///   "top-right"
  ///      The top right corner of the text is placed closest to the anchor.
  ///   "bottom-left"
  ///      The bottom left corner of the text is placed closest to the
  ///      anchor.
  ///   "bottom-right"
  ///      The bottom right corner of the text is placed closest to the
  ///      anchor.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textAnchor;

  /// Maximum angle change between adjacent characters.
  ///
  /// Type: number
  ///   default: 45
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textMaxAngle;

  /// The property allows control over a symbol's orientation. Note that the
  /// property values act as a hint, so that a symbol whose language doesn’t
  /// support the provided orientation will be laid out in its natural
  /// orientation. Example: English point symbol will be rendered
  /// horizontally even if array value contains single 'vertical' enum
  /// value. The order of elements in an array define priority order for the
  /// placement of an orientation variant.
  ///
  /// Type: array
  /// Options:
  ///   "horizontal"
  ///      If a text's language supports horizontal writing mode, symbols
  ///      with point placement would be laid out horizontally.
  ///   "vertical"
  ///      If a text's language supports vertical writing mode, symbols with
  ///      point placement would be laid out vertically.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textWritingMode;

  /// Rotates the text clockwise.
  ///
  /// Type: number
  ///   default: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textRotate;

  /// Size of the additional area around the text bounding box used for
  /// detecting symbol collisions.
  ///
  /// Type: number
  ///   default: 2
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textPadding;

  /// If true, the text may be flipped vertically to prevent it from being
  /// rendered upside-down.
  ///
  /// Type: boolean
  ///   default: true
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textKeepUpright;

  /// Specifies how to capitalize text, similar to the CSS `text-transform`
  /// property.
  ///
  /// Type: enum
  ///   default: none
  /// Options:
  ///   "none"
  ///      The text is not altered.
  ///   "uppercase"
  ///      Forces all letters to be displayed in uppercase.
  ///   "lowercase"
  ///      Forces all letters to be displayed in lowercase.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textTransform;

  /// Offset distance of text from its anchor. Positive values indicate
  /// right and down, while negative values indicate left and up. If used
  /// with text-variable-anchor, input values will be taken as absolute
  /// values. Offsets along the x- and y-axis will be applied automatically
  /// based on the anchor position.
  ///
  /// Type: array
  ///   default: [0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic textOffset;

  /// If true, the text will be visible even if it collides with other
  /// previously drawn symbols.
  ///
  /// Type: boolean
  ///   default: false
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textAllowOverlap;

  /// If true, other symbols can be visible even if they collide with the
  /// text.
  ///
  /// Type: boolean
  ///   default: false
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textIgnorePlacement;

  /// If true, icons will display without their corresponding text when the
  /// text collides with other symbols and the icon does not.
  ///
  /// Type: boolean
  ///   default: false
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic textOptional;

  /// Whether this layer is displayed.
  ///
  /// Type: enum
  ///   default: visible
  /// Options:
  ///   "visible"
  ///      The layer is shown.
  ///   "none"
  ///      The layer is not shown.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic visibility;

  const SymbolLayerProperties({
    this.iconOpacity,
    this.iconColor,
    this.iconHaloColor,
    this.iconHaloWidth,
    this.iconHaloBlur,
    this.iconTranslate,
    this.iconTranslateAnchor,
    this.textOpacity,
    this.textColor,
    this.textHaloColor,
    this.textHaloWidth,
    this.textHaloBlur,
    this.textTranslate,
    this.textTranslateAnchor,
    this.symbolPlacement,
    this.symbolSpacing,
    this.symbolAvoidEdges,
    this.symbolSortKey,
    this.symbolZOrder,
    this.iconAllowOverlap,
    this.iconIgnorePlacement,
    this.iconOptional,
    this.iconRotationAlignment,
    this.iconSize,
    this.iconTextFit,
    this.iconTextFitPadding,
    this.iconImage,
    this.iconRotate,
    this.iconPadding,
    this.iconKeepUpright,
    this.iconOffset,
    this.iconAnchor,
    this.iconPitchAlignment,
    this.textPitchAlignment,
    this.textRotationAlignment,
    this.textField,
    this.textFont,
    this.textSize,
    this.textMaxWidth,
    this.textLineHeight,
    this.textLetterSpacing,
    this.textJustify,
    this.textRadialOffset,
    this.textVariableAnchor,
    this.textAnchor,
    this.textMaxAngle,
    this.textWritingMode,
    this.textRotate,
    this.textPadding,
    this.textKeepUpright,
    this.textTransform,
    this.textOffset,
    this.textAllowOverlap,
    this.textIgnorePlacement,
    this.textOptional,
    this.visibility,
  });

  SymbolLayerProperties copyWith(SymbolLayerProperties changes) {
    return SymbolLayerProperties(
      iconOpacity: changes.iconOpacity ?? iconOpacity,
      iconColor: changes.iconColor ?? iconColor,
      iconHaloColor: changes.iconHaloColor ?? iconHaloColor,
      iconHaloWidth: changes.iconHaloWidth ?? iconHaloWidth,
      iconHaloBlur: changes.iconHaloBlur ?? iconHaloBlur,
      iconTranslate: changes.iconTranslate ?? iconTranslate,
      iconTranslateAnchor: changes.iconTranslateAnchor ?? iconTranslateAnchor,
      textOpacity: changes.textOpacity ?? textOpacity,
      textColor: changes.textColor ?? textColor,
      textHaloColor: changes.textHaloColor ?? textHaloColor,
      textHaloWidth: changes.textHaloWidth ?? textHaloWidth,
      textHaloBlur: changes.textHaloBlur ?? textHaloBlur,
      textTranslate: changes.textTranslate ?? textTranslate,
      textTranslateAnchor: changes.textTranslateAnchor ?? textTranslateAnchor,
      symbolPlacement: changes.symbolPlacement ?? symbolPlacement,
      symbolSpacing: changes.symbolSpacing ?? symbolSpacing,
      symbolAvoidEdges: changes.symbolAvoidEdges ?? symbolAvoidEdges,
      symbolSortKey: changes.symbolSortKey ?? symbolSortKey,
      symbolZOrder: changes.symbolZOrder ?? symbolZOrder,
      iconAllowOverlap: changes.iconAllowOverlap ?? iconAllowOverlap,
      iconIgnorePlacement: changes.iconIgnorePlacement ?? iconIgnorePlacement,
      iconOptional: changes.iconOptional ?? iconOptional,
      iconRotationAlignment:
          changes.iconRotationAlignment ?? iconRotationAlignment,
      iconSize: changes.iconSize ?? iconSize,
      iconTextFit: changes.iconTextFit ?? iconTextFit,
      iconTextFitPadding: changes.iconTextFitPadding ?? iconTextFitPadding,
      iconImage: changes.iconImage ?? iconImage,
      iconRotate: changes.iconRotate ?? iconRotate,
      iconPadding: changes.iconPadding ?? iconPadding,
      iconKeepUpright: changes.iconKeepUpright ?? iconKeepUpright,
      iconOffset: changes.iconOffset ?? iconOffset,
      iconAnchor: changes.iconAnchor ?? iconAnchor,
      iconPitchAlignment: changes.iconPitchAlignment ?? iconPitchAlignment,
      textPitchAlignment: changes.textPitchAlignment ?? textPitchAlignment,
      textRotationAlignment:
          changes.textRotationAlignment ?? textRotationAlignment,
      textField: changes.textField ?? textField,
      textFont: changes.textFont ?? textFont,
      textSize: changes.textSize ?? textSize,
      textMaxWidth: changes.textMaxWidth ?? textMaxWidth,
      textLineHeight: changes.textLineHeight ?? textLineHeight,
      textLetterSpacing: changes.textLetterSpacing ?? textLetterSpacing,
      textJustify: changes.textJustify ?? textJustify,
      textRadialOffset: changes.textRadialOffset ?? textRadialOffset,
      textVariableAnchor: changes.textVariableAnchor ?? textVariableAnchor,
      textAnchor: changes.textAnchor ?? textAnchor,
      textMaxAngle: changes.textMaxAngle ?? textMaxAngle,
      textWritingMode: changes.textWritingMode ?? textWritingMode,
      textRotate: changes.textRotate ?? textRotate,
      textPadding: changes.textPadding ?? textPadding,
      textKeepUpright: changes.textKeepUpright ?? textKeepUpright,
      textTransform: changes.textTransform ?? textTransform,
      textOffset: changes.textOffset ?? textOffset,
      textAllowOverlap: changes.textAllowOverlap ?? textAllowOverlap,
      textIgnorePlacement: changes.textIgnorePlacement ?? textIgnorePlacement,
      textOptional: changes.textOptional ?? textOptional,
      visibility: changes.visibility ?? visibility,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('icon-opacity', iconOpacity);
    addIfPresent('icon-color', iconColor);
    addIfPresent('icon-halo-color', iconHaloColor);
    addIfPresent('icon-halo-width', iconHaloWidth);
    addIfPresent('icon-halo-blur', iconHaloBlur);
    addIfPresent('icon-translate', iconTranslate);
    addIfPresent('icon-translate-anchor', iconTranslateAnchor);
    addIfPresent('text-opacity', textOpacity);
    addIfPresent('text-color', textColor);
    addIfPresent('text-halo-color', textHaloColor);
    addIfPresent('text-halo-width', textHaloWidth);
    addIfPresent('text-halo-blur', textHaloBlur);
    addIfPresent('text-translate', textTranslate);
    addIfPresent('text-translate-anchor', textTranslateAnchor);
    addIfPresent('symbol-placement', symbolPlacement);
    addIfPresent('symbol-spacing', symbolSpacing);
    addIfPresent('symbol-avoid-edges', symbolAvoidEdges);
    addIfPresent('symbol-sort-key', symbolSortKey);
    addIfPresent('symbol-z-order', symbolZOrder);
    addIfPresent('icon-allow-overlap', iconAllowOverlap);
    addIfPresent('icon-ignore-placement', iconIgnorePlacement);
    addIfPresent('icon-optional', iconOptional);
    addIfPresent('icon-rotation-alignment', iconRotationAlignment);
    addIfPresent('icon-size', iconSize);
    addIfPresent('icon-text-fit', iconTextFit);
    addIfPresent('icon-text-fit-padding', iconTextFitPadding);
    addIfPresent('icon-image', iconImage);
    addIfPresent('icon-rotate', iconRotate);
    addIfPresent('icon-padding', iconPadding);
    addIfPresent('icon-keep-upright', iconKeepUpright);
    addIfPresent('icon-offset', iconOffset);
    addIfPresent('icon-anchor', iconAnchor);
    addIfPresent('icon-pitch-alignment', iconPitchAlignment);
    addIfPresent('text-pitch-alignment', textPitchAlignment);
    addIfPresent('text-rotation-alignment', textRotationAlignment);
    addIfPresent('text-field', textField);
    addIfPresent('text-font', textFont);
    addIfPresent('text-size', textSize);
    addIfPresent('text-max-width', textMaxWidth);
    addIfPresent('text-line-height', textLineHeight);
    addIfPresent('text-letter-spacing', textLetterSpacing);
    addIfPresent('text-justify', textJustify);
    addIfPresent('text-radial-offset', textRadialOffset);
    addIfPresent('text-variable-anchor', textVariableAnchor);
    addIfPresent('text-anchor', textAnchor);
    addIfPresent('text-max-angle', textMaxAngle);
    addIfPresent('text-writing-mode', textWritingMode);
    addIfPresent('text-rotate', textRotate);
    addIfPresent('text-padding', textPadding);
    addIfPresent('text-keep-upright', textKeepUpright);
    addIfPresent('text-transform', textTransform);
    addIfPresent('text-offset', textOffset);
    addIfPresent('text-allow-overlap', textAllowOverlap);
    addIfPresent('text-ignore-placement', textIgnorePlacement);
    addIfPresent('text-optional', textOptional);
    addIfPresent('visibility', visibility);
    return json;
  }

  factory SymbolLayerProperties.fromJson(Map<String, dynamic> json) {
    return SymbolLayerProperties(
      iconOpacity: json['icon-opacity'],
      iconColor: json['icon-color'],
      iconHaloColor: json['icon-halo-color'],
      iconHaloWidth: json['icon-halo-width'],
      iconHaloBlur: json['icon-halo-blur'],
      iconTranslate: json['icon-translate'],
      iconTranslateAnchor: json['icon-translate-anchor'],
      textOpacity: json['text-opacity'],
      textColor: json['text-color'],
      textHaloColor: json['text-halo-color'],
      textHaloWidth: json['text-halo-width'],
      textHaloBlur: json['text-halo-blur'],
      textTranslate: json['text-translate'],
      textTranslateAnchor: json['text-translate-anchor'],
      symbolPlacement: json['symbol-placement'],
      symbolSpacing: json['symbol-spacing'],
      symbolAvoidEdges: json['symbol-avoid-edges'],
      symbolSortKey: json['symbol-sort-key'],
      symbolZOrder: json['symbol-z-order'],
      iconAllowOverlap: json['icon-allow-overlap'],
      iconIgnorePlacement: json['icon-ignore-placement'],
      iconOptional: json['icon-optional'],
      iconRotationAlignment: json['icon-rotation-alignment'],
      iconSize: json['icon-size'],
      iconTextFit: json['icon-text-fit'],
      iconTextFitPadding: json['icon-text-fit-padding'],
      iconImage: json['icon-image'],
      iconRotate: json['icon-rotate'],
      iconPadding: json['icon-padding'],
      iconKeepUpright: json['icon-keep-upright'],
      iconOffset: json['icon-offset'],
      iconAnchor: json['icon-anchor'],
      iconPitchAlignment: json['icon-pitch-alignment'],
      textPitchAlignment: json['text-pitch-alignment'],
      textRotationAlignment: json['text-rotation-alignment'],
      textField: json['text-field'],
      textFont: json['text-font'],
      textSize: json['text-size'],
      textMaxWidth: json['text-max-width'],
      textLineHeight: json['text-line-height'],
      textLetterSpacing: json['text-letter-spacing'],
      textJustify: json['text-justify'],
      textRadialOffset: json['text-radial-offset'],
      textVariableAnchor: json['text-variable-anchor'],
      textAnchor: json['text-anchor'],
      textMaxAngle: json['text-max-angle'],
      textWritingMode: json['text-writing-mode'],
      textRotate: json['text-rotate'],
      textPadding: json['text-padding'],
      textKeepUpright: json['text-keep-upright'],
      textTransform: json['text-transform'],
      textOffset: json['text-offset'],
      textAllowOverlap: json['text-allow-overlap'],
      textIgnorePlacement: json['text-ignore-placement'],
      textOptional: json['text-optional'],
      visibility: json['visibility'],
    );
  }
}

class CircleLayerProperties implements LayerProperties {
  // Paint Properties
  /// Circle radius.
  ///
  /// Type: number
  ///   default: 5
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleRadius;

  /// The fill color of the circle.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleColor;

  /// Amount to blur the circle. 1 blurs the circle such that only the
  /// centerpoint is full opacity.
  ///
  /// Type: number
  ///   default: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleBlur;

  /// The opacity at which the circle will be drawn.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleOpacity;

  /// The geometry's offset. Values are [x, y] where negatives indicate left
  /// and up, respectively.
  ///
  /// Type: array
  ///   default: [0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic circleTranslate;

  /// Controls the frame of reference for `circle-translate`.
  ///
  /// Type: enum
  ///   default: map
  /// Options:
  ///   "map"
  ///      The circle is translated relative to the map.
  ///   "viewport"
  ///      The circle is translated relative to the viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic circleTranslateAnchor;

  /// Controls the scaling behavior of the circle when the map is pitched.
  ///
  /// Type: enum
  ///   default: map
  /// Options:
  ///   "map"
  ///      Circles are scaled according to their apparent distance to the
  ///      camera.
  ///   "viewport"
  ///      Circles are not scaled.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic circlePitchScale;

  /// Orientation of circle when map is pitched.
  ///
  /// Type: enum
  ///   default: viewport
  /// Options:
  ///   "map"
  ///      The circle is aligned to the plane of the map.
  ///   "viewport"
  ///      The circle is aligned to the plane of the viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic circlePitchAlignment;

  /// The width of the circle's stroke. Strokes are placed outside of the
  /// `circle-radius`.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleStrokeWidth;

  /// The stroke color of the circle.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleStrokeColor;

  /// The opacity of the circle's stroke.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleStrokeOpacity;

  // Layout Properties
  /// Sorts features in ascending order based on this value. Features with a
  /// higher sort key will appear above features with a lower sort key.
  ///
  /// Type: number
  ///
  /// Sdk Support:
  ///   basic functionality with js
  ///   data-driven styling with js
  final dynamic circleSortKey;

  /// Whether this layer is displayed.
  ///
  /// Type: enum
  ///   default: visible
  /// Options:
  ///   "visible"
  ///      The layer is shown.
  ///   "none"
  ///      The layer is not shown.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic visibility;

  const CircleLayerProperties({
    this.circleRadius,
    this.circleColor,
    this.circleBlur,
    this.circleOpacity,
    this.circleTranslate,
    this.circleTranslateAnchor,
    this.circlePitchScale,
    this.circlePitchAlignment,
    this.circleStrokeWidth,
    this.circleStrokeColor,
    this.circleStrokeOpacity,
    this.circleSortKey,
    this.visibility,
  });

  CircleLayerProperties copyWith(CircleLayerProperties changes) {
    return CircleLayerProperties(
      circleRadius: changes.circleRadius ?? circleRadius,
      circleColor: changes.circleColor ?? circleColor,
      circleBlur: changes.circleBlur ?? circleBlur,
      circleOpacity: changes.circleOpacity ?? circleOpacity,
      circleTranslate: changes.circleTranslate ?? circleTranslate,
      circleTranslateAnchor:
          changes.circleTranslateAnchor ?? circleTranslateAnchor,
      circlePitchScale: changes.circlePitchScale ?? circlePitchScale,
      circlePitchAlignment:
          changes.circlePitchAlignment ?? circlePitchAlignment,
      circleStrokeWidth: changes.circleStrokeWidth ?? circleStrokeWidth,
      circleStrokeColor: changes.circleStrokeColor ?? circleStrokeColor,
      circleStrokeOpacity: changes.circleStrokeOpacity ?? circleStrokeOpacity,
      circleSortKey: changes.circleSortKey ?? circleSortKey,
      visibility: changes.visibility ?? visibility,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('circle-radius', circleRadius);
    addIfPresent('circle-color', circleColor);
    addIfPresent('circle-blur', circleBlur);
    addIfPresent('circle-opacity', circleOpacity);
    addIfPresent('circle-translate', circleTranslate);
    addIfPresent('circle-translate-anchor', circleTranslateAnchor);
    addIfPresent('circle-pitch-scale', circlePitchScale);
    addIfPresent('circle-pitch-alignment', circlePitchAlignment);
    addIfPresent('circle-stroke-width', circleStrokeWidth);
    addIfPresent('circle-stroke-color', circleStrokeColor);
    addIfPresent('circle-stroke-opacity', circleStrokeOpacity);
    addIfPresent('circle-sort-key', circleSortKey);
    addIfPresent('visibility', visibility);
    return json;
  }

  factory CircleLayerProperties.fromJson(Map<String, dynamic> json) {
    return CircleLayerProperties(
      circleRadius: json['circle-radius'],
      circleColor: json['circle-color'],
      circleBlur: json['circle-blur'],
      circleOpacity: json['circle-opacity'],
      circleTranslate: json['circle-translate'],
      circleTranslateAnchor: json['circle-translate-anchor'],
      circlePitchScale: json['circle-pitch-scale'],
      circlePitchAlignment: json['circle-pitch-alignment'],
      circleStrokeWidth: json['circle-stroke-width'],
      circleStrokeColor: json['circle-stroke-color'],
      circleStrokeOpacity: json['circle-stroke-opacity'],
      circleSortKey: json['circle-sort-key'],
      visibility: json['visibility'],
    );
  }
}

class LineLayerProperties implements LayerProperties {
  // Paint Properties
  /// The opacity at which the line will be drawn.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic lineOpacity;

  /// The color with which the line will be drawn.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic lineColor;

  /// The geometry's offset. Values are [x, y] where negatives indicate left
  /// and up, respectively.
  ///
  /// Type: array
  ///   default: [0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic lineTranslate;

  /// Controls the frame of reference for `line-translate`.
  ///
  /// Type: enum
  ///   default: map
  /// Options:
  ///   "map"
  ///      The line is translated relative to the map.
  ///   "viewport"
  ///      The line is translated relative to the viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic lineTranslateAnchor;

  /// Stroke thickness.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic lineWidth;

  /// Draws a line casing outside of a line's actual path. Value indicates
  /// the width of the inner gap.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic lineGapWidth;

  /// The line's offset. For linear features, a positive value offsets the
  /// line to the right, relative to the direction of the line, and a
  /// negative value to the left. For polygon features, a positive value
  /// results in an inset, and a negative value results in an outset.
  ///
  /// Type: number
  ///   default: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic lineOffset;

  /// Blur applied to the line, in pixels.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic lineBlur;

  /// Specifies the lengths of the alternating dashes and gaps that form the
  /// dash pattern. The lengths are later scaled by the line width. To
  /// convert a dash length to pixels, multiply the length by the current
  /// line width. Note that GeoJSON sources with `lineMetrics: true`
  /// specified won't render dashed lines to the expected scale. Also note
  /// that zoom-dependent expressions will be evaluated only at integer zoom
  /// levels.
  ///
  /// Type: array
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic lineDasharray;

  /// Name of image in sprite to use for drawing image lines. For seamless
  /// patterns, image width must be a factor of two (2, 4, 8, ..., 512).
  /// Note that zoom-dependent expressions will be evaluated only at integer
  /// zoom levels.
  ///
  /// Type: resolvedImage
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, macos, ios
  final dynamic linePattern;

  /// Defines a gradient with which to color a line feature. Can only be
  /// used with GeoJSON sources that specify `"lineMetrics": true`.
  ///
  /// Type: color
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic lineGradient;

  // Layout Properties
  /// The display of line endings.
  ///
  /// Type: enum
  ///   default: butt
  /// Options:
  ///   "butt"
  ///      A cap with a squared-off end which is drawn to the exact endpoint
  ///      of the line.
  ///   "round"
  ///      A cap with a rounded end which is drawn beyond the endpoint of
  ///      the line at a radius of one-half of the line's width and centered
  ///      on the endpoint of the line.
  ///   "square"
  ///      A cap with a squared-off end which is drawn beyond the endpoint
  ///      of the line at a distance of one-half of the line's width.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic lineCap;

  /// The display of lines when joining.
  ///
  /// Type: enum
  ///   default: miter
  /// Options:
  ///   "bevel"
  ///      A join with a squared-off end which is drawn beyond the endpoint
  ///      of the line at a distance of one-half of the line's width.
  ///   "round"
  ///      A join with a rounded end which is drawn beyond the endpoint of
  ///      the line at a radius of one-half of the line's width and centered
  ///      on the endpoint of the line.
  ///   "miter"
  ///      A join with a sharp, angled corner which is drawn with the outer
  ///      sides beyond the endpoint of the path until they meet.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic lineJoin;

  /// Used to automatically convert miter joins to bevel joins for sharp
  /// angles.
  ///
  /// Type: number
  ///   default: 2
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic lineMiterLimit;

  /// Used to automatically convert round joins to miter joins for shallow
  /// angles.
  ///
  /// Type: number
  ///   default: 1.05
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic lineRoundLimit;

  /// Sorts features in ascending order based on this value. Features with a
  /// higher sort key will appear above features with a lower sort key.
  ///
  /// Type: number
  ///
  /// Sdk Support:
  ///   basic functionality with js
  ///   data-driven styling with js
  final dynamic lineSortKey;

  /// Whether this layer is displayed.
  ///
  /// Type: enum
  ///   default: visible
  /// Options:
  ///   "visible"
  ///      The layer is shown.
  ///   "none"
  ///      The layer is not shown.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic visibility;

  const LineLayerProperties({
    this.lineOpacity,
    this.lineColor,
    this.lineTranslate,
    this.lineTranslateAnchor,
    this.lineWidth,
    this.lineGapWidth,
    this.lineOffset,
    this.lineBlur,
    this.lineDasharray,
    this.linePattern,
    this.lineGradient,
    this.lineCap,
    this.lineJoin,
    this.lineMiterLimit,
    this.lineRoundLimit,
    this.lineSortKey,
    this.visibility,
  });

  LineLayerProperties copyWith(LineLayerProperties changes) {
    return LineLayerProperties(
      lineOpacity: changes.lineOpacity ?? lineOpacity,
      lineColor: changes.lineColor ?? lineColor,
      lineTranslate: changes.lineTranslate ?? lineTranslate,
      lineTranslateAnchor: changes.lineTranslateAnchor ?? lineTranslateAnchor,
      lineWidth: changes.lineWidth ?? lineWidth,
      lineGapWidth: changes.lineGapWidth ?? lineGapWidth,
      lineOffset: changes.lineOffset ?? lineOffset,
      lineBlur: changes.lineBlur ?? lineBlur,
      lineDasharray: changes.lineDasharray ?? lineDasharray,
      linePattern: changes.linePattern ?? linePattern,
      lineGradient: changes.lineGradient ?? lineGradient,
      lineCap: changes.lineCap ?? lineCap,
      lineJoin: changes.lineJoin ?? lineJoin,
      lineMiterLimit: changes.lineMiterLimit ?? lineMiterLimit,
      lineRoundLimit: changes.lineRoundLimit ?? lineRoundLimit,
      lineSortKey: changes.lineSortKey ?? lineSortKey,
      visibility: changes.visibility ?? visibility,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('line-opacity', lineOpacity);
    addIfPresent('line-color', lineColor);
    addIfPresent('line-translate', lineTranslate);
    addIfPresent('line-translate-anchor', lineTranslateAnchor);
    addIfPresent('line-width', lineWidth);
    addIfPresent('line-gap-width', lineGapWidth);
    addIfPresent('line-offset', lineOffset);
    addIfPresent('line-blur', lineBlur);
    addIfPresent('line-dasharray', lineDasharray);
    addIfPresent('line-pattern', linePattern);
    addIfPresent('line-gradient', lineGradient);
    addIfPresent('line-cap', lineCap);
    addIfPresent('line-join', lineJoin);
    addIfPresent('line-miter-limit', lineMiterLimit);
    addIfPresent('line-round-limit', lineRoundLimit);
    addIfPresent('line-sort-key', lineSortKey);
    addIfPresent('visibility', visibility);
    return json;
  }

  factory LineLayerProperties.fromJson(Map<String, dynamic> json) {
    return LineLayerProperties(
      lineOpacity: json['line-opacity'],
      lineColor: json['line-color'],
      lineTranslate: json['line-translate'],
      lineTranslateAnchor: json['line-translate-anchor'],
      lineWidth: json['line-width'],
      lineGapWidth: json['line-gap-width'],
      lineOffset: json['line-offset'],
      lineBlur: json['line-blur'],
      lineDasharray: json['line-dasharray'],
      linePattern: json['line-pattern'],
      lineGradient: json['line-gradient'],
      lineCap: json['line-cap'],
      lineJoin: json['line-join'],
      lineMiterLimit: json['line-miter-limit'],
      lineRoundLimit: json['line-round-limit'],
      lineSortKey: json['line-sort-key'],
      visibility: json['visibility'],
    );
  }
}

class FillLayerProperties implements LayerProperties {
  // Paint Properties
  /// Whether or not the fill should be antialiased.
  ///
  /// Type: boolean
  ///   default: true
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic fillAntialias;

  /// The opacity of the entire fill layer. In contrast to the `fill-color`,
  /// this value will also affect the 1px stroke around the fill, if the
  /// stroke is used.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic fillOpacity;

  /// The color of the filled part of this layer. This color can be
  /// specified as `rgba` with an alpha component and the color's opacity
  /// will not affect the opacity of the 1px stroke, if it is used.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic fillColor;

  /// The outline color of the fill. Matches the value of `fill-color` if
  /// unspecified.
  ///
  /// Type: color
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic fillOutlineColor;

  /// The geometry's offset. Values are [x, y] where negatives indicate left
  /// and up, respectively.
  ///
  /// Type: array
  ///   default: [0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic fillTranslate;

  /// Controls the frame of reference for `fill-translate`.
  ///
  /// Type: enum
  ///   default: map
  /// Options:
  ///   "map"
  ///      The fill is translated relative to the map.
  ///   "viewport"
  ///      The fill is translated relative to the viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic fillTranslateAnchor;

  /// Name of image in sprite to use for drawing image fills. For seamless
  /// patterns, image width and height must be a factor of two (2, 4, 8,
  /// ..., 512). Note that zoom-dependent expressions will be evaluated only
  /// at integer zoom levels.
  ///
  /// Type: resolvedImage
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, macos, ios
  final dynamic fillPattern;

  // Layout Properties
  /// Sorts features in ascending order based on this value. Features with a
  /// higher sort key will appear above features with a lower sort key.
  ///
  /// Type: number
  ///
  /// Sdk Support:
  ///   basic functionality with js
  ///   data-driven styling with js
  final dynamic fillSortKey;

  /// Whether this layer is displayed.
  ///
  /// Type: enum
  ///   default: visible
  /// Options:
  ///   "visible"
  ///      The layer is shown.
  ///   "none"
  ///      The layer is not shown.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic visibility;

  const FillLayerProperties({
    this.fillAntialias,
    this.fillOpacity,
    this.fillColor,
    this.fillOutlineColor,
    this.fillTranslate,
    this.fillTranslateAnchor,
    this.fillPattern,
    this.fillSortKey,
    this.visibility,
  });

  FillLayerProperties copyWith(FillLayerProperties changes) {
    return FillLayerProperties(
      fillAntialias: changes.fillAntialias ?? fillAntialias,
      fillOpacity: changes.fillOpacity ?? fillOpacity,
      fillColor: changes.fillColor ?? fillColor,
      fillOutlineColor: changes.fillOutlineColor ?? fillOutlineColor,
      fillTranslate: changes.fillTranslate ?? fillTranslate,
      fillTranslateAnchor: changes.fillTranslateAnchor ?? fillTranslateAnchor,
      fillPattern: changes.fillPattern ?? fillPattern,
      fillSortKey: changes.fillSortKey ?? fillSortKey,
      visibility: changes.visibility ?? visibility,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('fill-antialias', fillAntialias);
    addIfPresent('fill-opacity', fillOpacity);
    addIfPresent('fill-color', fillColor);
    addIfPresent('fill-outline-color', fillOutlineColor);
    addIfPresent('fill-translate', fillTranslate);
    addIfPresent('fill-translate-anchor', fillTranslateAnchor);
    addIfPresent('fill-pattern', fillPattern);
    addIfPresent('fill-sort-key', fillSortKey);
    addIfPresent('visibility', visibility);
    return json;
  }

  factory FillLayerProperties.fromJson(Map<String, dynamic> json) {
    return FillLayerProperties(
      fillAntialias: json['fill-antialias'],
      fillOpacity: json['fill-opacity'],
      fillColor: json['fill-color'],
      fillOutlineColor: json['fill-outline-color'],
      fillTranslate: json['fill-translate'],
      fillTranslateAnchor: json['fill-translate-anchor'],
      fillPattern: json['fill-pattern'],
      fillSortKey: json['fill-sort-key'],
      visibility: json['visibility'],
    );
  }
}

class FillExtrusionLayerProperties implements LayerProperties {
  // Paint Properties
  /// The opacity of the entire fill extrusion layer. This is rendered on a
  /// per-layer, not per-feature, basis, and data-driven styling is not
  /// available.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic fillExtrusionOpacity;

  /// The base color of the extruded fill. The extrusion's surfaces will be
  /// shaded differently based on this color in combination with the root
  /// `light` settings. If this color is specified as `rgba` with an alpha
  /// component, the alpha component will be ignored; use
  /// `fill-extrusion-opacity` to set layer opacity.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic fillExtrusionColor;

  /// The geometry's offset. Values are [x, y] where negatives indicate left
  /// and up (on the flat plane), respectively.
  ///
  /// Type: array
  ///   default: [0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic fillExtrusionTranslate;

  /// Controls the frame of reference for `fill-extrusion-translate`.
  ///
  /// Type: enum
  ///   default: map
  /// Options:
  ///   "map"
  ///      The fill extrusion is translated relative to the map.
  ///   "viewport"
  ///      The fill extrusion is translated relative to the viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic fillExtrusionTranslateAnchor;

  /// Name of image in sprite to use for drawing images on extruded fills.
  /// For seamless patterns, image width and height must be a factor of two
  /// (2, 4, 8, ..., 512). Note that zoom-dependent expressions will be
  /// evaluated only at integer zoom levels.
  ///
  /// Type: resolvedImage
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, macos, ios
  final dynamic fillExtrusionPattern;

  /// The height with which to extrude this layer.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic fillExtrusionHeight;

  /// The height with which to extrude the base of this layer. Must be less
  /// than or equal to `fill-extrusion-height`.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic fillExtrusionBase;

  /// Whether to apply a vertical gradient to the sides of a fill-extrusion
  /// layer. If true, sides will be shaded slightly darker farther down.
  ///
  /// Type: boolean
  ///   default: true
  ///
  /// Sdk Support:
  ///   basic functionality with js, ios, macos
  final dynamic fillExtrusionVerticalGradient;

  // Layout Properties
  /// Whether this layer is displayed.
  ///
  /// Type: enum
  ///   default: visible
  /// Options:
  ///   "visible"
  ///      The layer is shown.
  ///   "none"
  ///      The layer is not shown.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic visibility;

  const FillExtrusionLayerProperties({
    this.fillExtrusionOpacity,
    this.fillExtrusionColor,
    this.fillExtrusionTranslate,
    this.fillExtrusionTranslateAnchor,
    this.fillExtrusionPattern,
    this.fillExtrusionHeight,
    this.fillExtrusionBase,
    this.fillExtrusionVerticalGradient,
    this.visibility,
  });

  FillExtrusionLayerProperties copyWith(FillExtrusionLayerProperties changes) {
    return FillExtrusionLayerProperties(
      fillExtrusionOpacity:
          changes.fillExtrusionOpacity ?? fillExtrusionOpacity,
      fillExtrusionColor: changes.fillExtrusionColor ?? fillExtrusionColor,
      fillExtrusionTranslate:
          changes.fillExtrusionTranslate ?? fillExtrusionTranslate,
      fillExtrusionTranslateAnchor:
          changes.fillExtrusionTranslateAnchor ?? fillExtrusionTranslateAnchor,
      fillExtrusionPattern:
          changes.fillExtrusionPattern ?? fillExtrusionPattern,
      fillExtrusionHeight: changes.fillExtrusionHeight ?? fillExtrusionHeight,
      fillExtrusionBase: changes.fillExtrusionBase ?? fillExtrusionBase,
      fillExtrusionVerticalGradient: changes.fillExtrusionVerticalGradient ??
          fillExtrusionVerticalGradient,
      visibility: changes.visibility ?? visibility,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('fill-extrusion-opacity', fillExtrusionOpacity);
    addIfPresent('fill-extrusion-color', fillExtrusionColor);
    addIfPresent('fill-extrusion-translate', fillExtrusionTranslate);
    addIfPresent(
        'fill-extrusion-translate-anchor', fillExtrusionTranslateAnchor);
    addIfPresent('fill-extrusion-pattern', fillExtrusionPattern);
    addIfPresent('fill-extrusion-height', fillExtrusionHeight);
    addIfPresent('fill-extrusion-base', fillExtrusionBase);
    addIfPresent(
        'fill-extrusion-vertical-gradient', fillExtrusionVerticalGradient);
    addIfPresent('visibility', visibility);
    return json;
  }

  factory FillExtrusionLayerProperties.fromJson(Map<String, dynamic> json) {
    return FillExtrusionLayerProperties(
      fillExtrusionOpacity: json['fill-extrusion-opacity'],
      fillExtrusionColor: json['fill-extrusion-color'],
      fillExtrusionTranslate: json['fill-extrusion-translate'],
      fillExtrusionTranslateAnchor: json['fill-extrusion-translate-anchor'],
      fillExtrusionPattern: json['fill-extrusion-pattern'],
      fillExtrusionHeight: json['fill-extrusion-height'],
      fillExtrusionBase: json['fill-extrusion-base'],
      fillExtrusionVerticalGradient: json['fill-extrusion-vertical-gradient'],
      visibility: json['visibility'],
    );
  }
}

class RasterLayerProperties implements LayerProperties {
  // Paint Properties
  /// The opacity at which the image will be drawn.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic rasterOpacity;

  /// Rotates hues around the color wheel.
  ///
  /// Type: number
  ///   default: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic rasterHueRotate;

  /// Increase or reduce the brightness of the image. The value is the
  /// minimum brightness.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic rasterBrightnessMin;

  /// Increase or reduce the brightness of the image. The value is the
  /// maximum brightness.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic rasterBrightnessMax;

  /// Increase or reduce the saturation of the image.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: -1
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic rasterSaturation;

  /// Increase or reduce the contrast of the image.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: -1
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic rasterContrast;

  /// The resampling/interpolation method to use for overscaling, also known
  /// as texture magnification filter
  ///
  /// Type: enum
  ///   default: linear
  /// Options:
  ///   "linear"
  ///      (Bi)linear filtering interpolates pixel values using the weighted
  ///      average of the four closest original source pixels creating a
  ///      smooth but blurry look when overscaled
  ///   "nearest"
  ///      Nearest neighbor filtering interpolates pixel values using the
  ///      nearest original source pixel creating a sharp but pixelated look
  ///      when overscaled
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic rasterResampling;

  /// Fade duration when a new tile is added.
  ///
  /// Type: number
  ///   default: 300
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic rasterFadeDuration;

  // Layout Properties
  /// Whether this layer is displayed.
  ///
  /// Type: enum
  ///   default: visible
  /// Options:
  ///   "visible"
  ///      The layer is shown.
  ///   "none"
  ///      The layer is not shown.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic visibility;

  const RasterLayerProperties({
    this.rasterOpacity,
    this.rasterHueRotate,
    this.rasterBrightnessMin,
    this.rasterBrightnessMax,
    this.rasterSaturation,
    this.rasterContrast,
    this.rasterResampling,
    this.rasterFadeDuration,
    this.visibility,
  });

  RasterLayerProperties copyWith(RasterLayerProperties changes) {
    return RasterLayerProperties(
      rasterOpacity: changes.rasterOpacity ?? rasterOpacity,
      rasterHueRotate: changes.rasterHueRotate ?? rasterHueRotate,
      rasterBrightnessMin: changes.rasterBrightnessMin ?? rasterBrightnessMin,
      rasterBrightnessMax: changes.rasterBrightnessMax ?? rasterBrightnessMax,
      rasterSaturation: changes.rasterSaturation ?? rasterSaturation,
      rasterContrast: changes.rasterContrast ?? rasterContrast,
      rasterResampling: changes.rasterResampling ?? rasterResampling,
      rasterFadeDuration: changes.rasterFadeDuration ?? rasterFadeDuration,
      visibility: changes.visibility ?? visibility,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('raster-opacity', rasterOpacity);
    addIfPresent('raster-hue-rotate', rasterHueRotate);
    addIfPresent('raster-brightness-min', rasterBrightnessMin);
    addIfPresent('raster-brightness-max', rasterBrightnessMax);
    addIfPresent('raster-saturation', rasterSaturation);
    addIfPresent('raster-contrast', rasterContrast);
    addIfPresent('raster-resampling', rasterResampling);
    addIfPresent('raster-fade-duration', rasterFadeDuration);
    addIfPresent('visibility', visibility);
    return json;
  }

  factory RasterLayerProperties.fromJson(Map<String, dynamic> json) {
    return RasterLayerProperties(
      rasterOpacity: json['raster-opacity'],
      rasterHueRotate: json['raster-hue-rotate'],
      rasterBrightnessMin: json['raster-brightness-min'],
      rasterBrightnessMax: json['raster-brightness-max'],
      rasterSaturation: json['raster-saturation'],
      rasterContrast: json['raster-contrast'],
      rasterResampling: json['raster-resampling'],
      rasterFadeDuration: json['raster-fade-duration'],
      visibility: json['visibility'],
    );
  }
}

class HillshadeLayerProperties implements LayerProperties {
  // Paint Properties
  /// The direction of the light source used to generate the hillshading
  /// with 0 as the top of the viewport if `hillshade-illumination-anchor`
  /// is set to `viewport` and due north if `hillshade-illumination-anchor`
  /// is set to `map`.
  ///
  /// Type: number
  ///   default: 335
  ///   minimum: 0
  ///   maximum: 359
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic hillshadeIlluminationDirection;

  /// Direction of light source when map is rotated.
  ///
  /// Type: enum
  ///   default: viewport
  /// Options:
  ///   "map"
  ///      The hillshade illumination is relative to the north direction.
  ///   "viewport"
  ///      The hillshade illumination is relative to the top of the
  ///      viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic hillshadeIlluminationAnchor;

  /// Intensity of the hillshade
  ///
  /// Type: number
  ///   default: 0.5
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic hillshadeExaggeration;

  /// The shading color of areas that face away from the light source.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic hillshadeShadowColor;

  /// The shading color of areas that faces towards the light source.
  ///
  /// Type: color
  ///   default: #FFFFFF
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic hillshadeHighlightColor;

  /// The shading color used to accentuate rugged terrain like sharp cliffs
  /// and gorges.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic hillshadeAccentColor;

  // Layout Properties
  /// Whether this layer is displayed.
  ///
  /// Type: enum
  ///   default: visible
  /// Options:
  ///   "visible"
  ///      The layer is shown.
  ///   "none"
  ///      The layer is not shown.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic visibility;

  const HillshadeLayerProperties({
    this.hillshadeIlluminationDirection,
    this.hillshadeIlluminationAnchor,
    this.hillshadeExaggeration,
    this.hillshadeShadowColor,
    this.hillshadeHighlightColor,
    this.hillshadeAccentColor,
    this.visibility,
  });

  HillshadeLayerProperties copyWith(HillshadeLayerProperties changes) {
    return HillshadeLayerProperties(
      hillshadeIlluminationDirection: changes.hillshadeIlluminationDirection ??
          hillshadeIlluminationDirection,
      hillshadeIlluminationAnchor:
          changes.hillshadeIlluminationAnchor ?? hillshadeIlluminationAnchor,
      hillshadeExaggeration:
          changes.hillshadeExaggeration ?? hillshadeExaggeration,
      hillshadeShadowColor:
          changes.hillshadeShadowColor ?? hillshadeShadowColor,
      hillshadeHighlightColor:
          changes.hillshadeHighlightColor ?? hillshadeHighlightColor,
      hillshadeAccentColor:
          changes.hillshadeAccentColor ?? hillshadeAccentColor,
      visibility: changes.visibility ?? visibility,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent(
        'hillshade-illumination-direction', hillshadeIlluminationDirection);
    addIfPresent('hillshade-illumination-anchor', hillshadeIlluminationAnchor);
    addIfPresent('hillshade-exaggeration', hillshadeExaggeration);
    addIfPresent('hillshade-shadow-color', hillshadeShadowColor);
    addIfPresent('hillshade-highlight-color', hillshadeHighlightColor);
    addIfPresent('hillshade-accent-color', hillshadeAccentColor);
    addIfPresent('visibility', visibility);
    return json;
  }

  factory HillshadeLayerProperties.fromJson(Map<String, dynamic> json) {
    return HillshadeLayerProperties(
      hillshadeIlluminationDirection: json['hillshade-illumination-direction'],
      hillshadeIlluminationAnchor: json['hillshade-illumination-anchor'],
      hillshadeExaggeration: json['hillshade-exaggeration'],
      hillshadeShadowColor: json['hillshade-shadow-color'],
      hillshadeHighlightColor: json['hillshade-highlight-color'],
      hillshadeAccentColor: json['hillshade-accent-color'],
      visibility: json['visibility'],
    );
  }
}

class HeatmapLayerProperties implements LayerProperties {
  // Paint Properties
  /// Radius of influence of one heatmap point in pixels. Increasing the
  /// value makes the heatmap smoother, but less detailed.
  ///
  /// Type: number
  ///   default: 30
  ///   minimum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic heatmapRadius;

  /// A measure of how much an individual point contributes to the heatmap.
  /// A value of 10 would be equivalent to having 10 points of weight 1 in
  /// the same spot. Especially useful when combined with clustering.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic heatmapWeight;

  /// Similar to `heatmap-weight` but controls the intensity of the heatmap
  /// globally. Primarily used for adjusting the heatmap based on zoom
  /// level.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic heatmapIntensity;

  /// Defines the color of each pixel based on its density value in a
  /// heatmap.  Should be an expression that uses `["heatmap-density"]` as
  /// input.
  ///
  /// Type: color
  ///   default: [interpolate, [linear], [heatmap-density], 0, rgba(0, 0, 255, 0), 0.1, royalblue, 0.3, cyan, 0.5, lime, 0.7, yellow, 1, red]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic heatmapColor;

  /// The global opacity at which the heatmap layer will be drawn.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic heatmapOpacity;

  // Layout Properties
  /// Whether this layer is displayed.
  ///
  /// Type: enum
  ///   default: visible
  /// Options:
  ///   "visible"
  ///      The layer is shown.
  ///   "none"
  ///      The layer is not shown.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic visibility;

  const HeatmapLayerProperties({
    this.heatmapRadius,
    this.heatmapWeight,
    this.heatmapIntensity,
    this.heatmapColor,
    this.heatmapOpacity,
    this.visibility,
  });

  HeatmapLayerProperties copyWith(HeatmapLayerProperties changes) {
    return HeatmapLayerProperties(
      heatmapRadius: changes.heatmapRadius ?? heatmapRadius,
      heatmapWeight: changes.heatmapWeight ?? heatmapWeight,
      heatmapIntensity: changes.heatmapIntensity ?? heatmapIntensity,
      heatmapColor: changes.heatmapColor ?? heatmapColor,
      heatmapOpacity: changes.heatmapOpacity ?? heatmapOpacity,
      visibility: changes.visibility ?? visibility,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('heatmap-radius', heatmapRadius);
    addIfPresent('heatmap-weight', heatmapWeight);
    addIfPresent('heatmap-intensity', heatmapIntensity);
    addIfPresent('heatmap-color', heatmapColor);
    addIfPresent('heatmap-opacity', heatmapOpacity);
    addIfPresent('visibility', visibility);
    return json;
  }

  factory HeatmapLayerProperties.fromJson(Map<String, dynamic> json) {
    return HeatmapLayerProperties(
      heatmapRadius: json['heatmap-radius'],
      heatmapWeight: json['heatmap-weight'],
      heatmapIntensity: json['heatmap-intensity'],
      heatmapColor: json['heatmap-color'],
      heatmapOpacity: json['heatmap-opacity'],
      visibility: json['visibility'],
    );
  }
}
