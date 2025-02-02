/*
 * Copyright (c) 2021 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:math';

import 'package:flutter/material.dart';

import '../showcase_tutorial.dart';
import 'get_position.dart';
import 'measure_size.dart';

const _kDefaultPaddingFromParent = 14.0;

class ToolTipWidget extends StatefulWidget {
  final GetPosition? position;
  final Offset? offset;
  final Size? screenSize;
  final String? title;
  final TextAlign? titleAlignment;
  final String? description;
  final TextAlign? descriptionAlignment;
  final TextStyle? titleTextStyle;
  final TextStyle? descTextStyle;
  final Widget? container;
  final Color? tooltipBackgroundColor;
  final Color? textColor;
  final bool showArrow;
  final double? contentHeight;
  final double? contentWidth;
  final VoidCallback? onTooltipTap;
  final EdgeInsets? tooltipPadding;
  final Duration movingAnimationDuration;
  final bool disableMovingAnimation;
  final bool disableScaleAnimation;
  final BorderRadius? tooltipBorderRadius;
  final Duration scaleAnimationDuration;
  final Curve scaleAnimationCurve;
  final Alignment? scaleAnimationAlignment;
  final bool isTooltipDismissed;
  final TooltipPosition? tooltipPosition;
  final TooltipHorizontalPosition? tooltipHorizontalPosition;
  final EdgeInsets? titlePadding;
  final EdgeInsets? descriptionPadding;
  final Widget? actions;
  final ActionsSettings? actionSettings;
  final ActionButtonsPosition? actionButtonsPosition;
  final Widget? overlayWidget;
  final AlignmentGeometry? overlayAlignment;

  //final GlobalKey key;

  const ToolTipWidget({
    Key? key,
    required this.position,
    required this.offset,
    required this.screenSize,
    required this.title,
    required this.titleAlignment,
    required this.description,
    required this.titleTextStyle,
    required this.descTextStyle,
    required this.container,
    required this.tooltipBackgroundColor,
    required this.textColor,
    required this.showArrow,
    required this.contentHeight,
    required this.contentWidth,
    required this.onTooltipTap,
    required this.movingAnimationDuration,
    required this.descriptionAlignment,
    this.tooltipPadding = const EdgeInsets.symmetric(vertical: 8),
    required this.disableMovingAnimation,
    required this.disableScaleAnimation,
    required this.tooltipBorderRadius,
    required this.scaleAnimationDuration,
    required this.scaleAnimationCurve,
    this.scaleAnimationAlignment,
    this.isTooltipDismissed = false,
    this.tooltipPosition,
    this.tooltipHorizontalPosition,
    this.titlePadding,
    this.descriptionPadding,
    this.actions,
    this.actionSettings,
    this.actionButtonsPosition,
    this.overlayWidget,
    this.overlayAlignment,
  }) : super(key: key);

  @override
  State<ToolTipWidget> createState() => _ToolTipWidgetState();
}

class _ToolTipWidgetState extends State<ToolTipWidget> with TickerProviderStateMixin {
  Offset? position;

  bool isArrowUp = false;

  late final AnimationController _movingAnimationController;
  late final Animation<double> _movingAnimation;
  late final AnimationController _scaleAnimationController;
  late final Animation<double> _scaleAnimation;

  double tooltipWidth = 0;
  double tooltipHeight = 0;
  double actionWidgetHeight = 0;
  double tooltipScreenEdgePadding = 20;
  double tooltipTextPadding = 15;

  TooltipPosition findPositionForContent(Offset position) {
    var height = 120.0;
    height = widget.contentHeight ?? height;
    final bottomPosition = position.dy + ((widget.position?.getHeight() ?? 0) / 2);
    final topPosition = position.dy - ((widget.position?.getHeight() ?? 0) / 2);
    final hasSpaceInTop = topPosition >= height;
    final EdgeInsets viewInsets =
        EdgeInsets.fromViewPadding(View.of(context).viewInsets, View.of(context).devicePixelRatio);
    final double actualVisibleScreenHeight =
        (widget.screenSize?.height ?? MediaQuery.of(context).size.height) - viewInsets.bottom;
    final hasSpaceInBottom = (actualVisibleScreenHeight - bottomPosition) >= height;
    return widget.tooltipPosition ??
        (hasSpaceInTop && !hasSpaceInBottom ? TooltipPosition.top : TooltipPosition.bottom);
  }

  void _getTooltipWidth() {
    final titleStyle = widget.titleTextStyle ??
        Theme.of(context).textTheme.titleLarge!.merge(TextStyle(color: widget.textColor));
    final descriptionStyle = widget.descTextStyle ??
        Theme.of(context).textTheme.titleSmall!.merge(TextStyle(color: widget.textColor));
    final titleLength = widget.title == null
        ? 0
        : _textSize(widget.title!, titleStyle).width +
            widget.tooltipPadding!.right +
            widget.tooltipPadding!.left +
            (widget.titlePadding?.right ?? 0) +
            (widget.titlePadding?.left ?? 0);
    final descriptionLength = widget.description == null
        ? 0
        : (_textSize(widget.description!, descriptionStyle).width +
            widget.tooltipPadding!.right +
            widget.tooltipPadding!.left +
            (widget.descriptionPadding?.right ?? 0) +
            (widget.descriptionPadding?.left ?? 0));
    var maxTextWidth = max(titleLength, descriptionLength);
    if (maxTextWidth > widget.screenSize!.width - tooltipScreenEdgePadding) {
      tooltipWidth = widget.screenSize!.width - tooltipScreenEdgePadding;
    } else {
      tooltipWidth = maxTextWidth + tooltipTextPadding;
    }
  }

  void _getTooltipHeight() {
    final titleStyle = widget.titleTextStyle ??
        Theme.of(context).textTheme.titleLarge!.merge(TextStyle(color: widget.textColor));
    final descriptionStyle = widget.descTextStyle ??
        Theme.of(context).textTheme.titleSmall!.merge(TextStyle(color: widget.textColor));
    final titleLength = widget.title == null
        ? 0
        : _textSize(widget.title!, titleStyle).height +
            widget.tooltipPadding!.bottom +
            widget.tooltipPadding!.top;
    final descriptionLength = widget.description == null
        ? 0
        : (_textSize(widget.description!, descriptionStyle).height +
            widget.tooltipPadding!.bottom +
            widget.tooltipPadding!.top);
    var maxTextHeight = titleLength + descriptionLength;
    if (maxTextHeight > widget.screenSize!.height - tooltipScreenEdgePadding) {
      tooltipHeight = widget.screenSize!.height - tooltipScreenEdgePadding;
    } else {
      tooltipHeight = maxTextHeight + tooltipTextPadding;
    }
  }

  double? _getLeft() {
    if (widget.position != null) {
      return widget.position!.getCenter();
      final width = widget.container != null ? _customContainerWidth.value : tooltipWidth;
      double leftPositionValue = widget.position!.getCenter() - (width * 0.5);
      if ((leftPositionValue + width) > MediaQuery.of(context).size.width) {
        return null;
      } else if ((leftPositionValue) < _kDefaultPaddingFromParent) {
        return _kDefaultPaddingFromParent;
      } else {
        return leftPositionValue;
      }
    }
    return null;
  }

  double? _getRight() {
    if (widget.position != null) {
      final width = widget.container != null ? _customContainerWidth.value : tooltipWidth;

      final left = _getLeft();
      if (left == null || (left + width) > MediaQuery.of(context).size.width) {
        final rightPosition = widget.position!.getCenter() + (width * 0.5);

        return (rightPosition + width) > MediaQuery.of(context).size.width
            ? _kDefaultPaddingFromParent
            : null;
      } else {
        return null;
      }
    }
    return null;
  }

  double _getSpace() {
    final horizontalPosition = widget.tooltipHorizontalPosition ?? TooltipHorizontalPosition.center;
    switch(horizontalPosition) {
      case TooltipHorizontalPosition.left:
        return widget.position!.getCenter();
      case TooltipHorizontalPosition.center:
        return widget.position!.getCenter() - (widget.contentWidth! / 2);
      case TooltipHorizontalPosition.right:
        return widget.position!.getCenter() - widget.contentWidth!;
    }
    // var space = widget.position!.getCenter() - (widget.contentWidth! / 2);
    // if (space + widget.contentWidth! > widget.screenSize!.width) {
    //   space = widget.screenSize!.width - widget.contentWidth! - 8;
    // } else if (space < (widget.contentWidth! / 2)) {
    //   space = 16;
    // }
    // return space;
  }

  double _getAlignmentX() {
    final calculatedLeft = _getLeft();
    var left = calculatedLeft == null ? 0 : (widget.position!.getCenter() - calculatedLeft);
    var right = _getLeft() == null
        ? (MediaQuery.of(context).size.width - widget.position!.getCenter()) - (_getRight() ?? 0)
        : 0;
    final containerWidth = widget.container != null ? _customContainerWidth.value : tooltipWidth;

    if (left != 0) {
      return (-1 + (2 * (left / containerWidth)));
    } else {
      return (1 - (2 * (right / containerWidth)));
    }
  }

  double _getAlignmentY() {
    var dy = isArrowUp
        ? -1.0
        : (MediaQuery.of(context).size.height / 2) < widget.position!.getTop()
            ? -1.0
            : 1.0;
    return dy;
  }

  final GlobalKey _customContainerKey = GlobalKey();
  final ValueNotifier<double> _customContainerWidth = ValueNotifier<double>(1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.container != null &&
          _customContainerKey.currentContext != null &&
          _customContainerKey.currentContext?.size != null) {
        setState(() {
          _customContainerWidth.value = _customContainerKey.currentContext!.size!.width;
        });
      }
    });
    _movingAnimationController = AnimationController(
      duration: widget.movingAnimationDuration,
      vsync: this,
    );
    _movingAnimation = CurvedAnimation(
      parent: _movingAnimationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimationController = AnimationController(
      duration: widget.scaleAnimationDuration,
      vsync: this,
      lowerBound: widget.disableScaleAnimation ? 1 : 0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleAnimationController,
      curve: widget.scaleAnimationCurve,
    );
    if (widget.disableScaleAnimation) {
      movingAnimationListener();
    } else {
      _scaleAnimationController
        ..addStatusListener((scaleAnimationStatus) {
          if (scaleAnimationStatus == AnimationStatus.completed) {
            movingAnimationListener();
          }
        })
        ..forward();
    }
    if (!widget.disableMovingAnimation) {
      _movingAnimationController.forward();
    }
  }

  void movingAnimationListener() {
    _movingAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _movingAnimationController.reverse();
      }
      if (_movingAnimationController.isDismissed) {
        if (!widget.disableMovingAnimation) {
          _movingAnimationController.forward();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    _getTooltipWidth();
    _getTooltipHeight();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _movingAnimationController.dispose();
    _scaleAnimationController.dispose();

    super.dispose();
  }

  double _getContentOffsetMultiplier(TooltipPosition position) {
    switch (position) {
      case TooltipPosition.top:
        return -1;
      case TooltipPosition.bottom:
        return 1;
      case TooltipPosition.center:
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    position = widget.offset;
    final contentOrientation = findPositionForContent(position!);
    final contentOffsetMultiplier = _getContentOffsetMultiplier(contentOrientation);
    isArrowUp = contentOffsetMultiplier == 1.0;

    final contentY = widget.tooltipPosition == TooltipPosition.center
        ? widget.position!.getVerticalCenter()
        : isArrowUp
        ? widget.position!.getBottom() + (contentOffsetMultiplier * 3)
        : widget.position!.getTop() + (contentOffsetMultiplier * 3);

    final num contentFractionalOffset = contentOffsetMultiplier.clamp(-1.0, 0.0);

    var paddingTop = isArrowUp ? 22.0 : 0.0;
    var paddingBottom = isArrowUp ? 0.0 : 27.0;

    if (!widget.showArrow) {
      paddingTop = 10;
      paddingBottom = 10;
    }

    const arrowWidth = 18.0;
    const arrowHeight = 9.0;

    if (!widget.disableScaleAnimation && widget.isTooltipDismissed) {
      _scaleAnimationController.reverse();
    }

    var actionTopPos = isArrowUp
        ? (contentY + tooltipHeight + widget.position!.getHeightContainer())
        : contentY - (tooltipHeight + widget.position!.getHeightContainer());
    var actionTopPosWithContainer = isArrowUp
        ? (contentY + arrowHeight + tooltipHeight + widget.position!.getHeightContainer())
        : contentY - (arrowHeight + tooltipHeight + widget.position!.getHeightContainer());

    final offsetWhenCentered = (contentOrientation == TooltipPosition.center)
        ? widget.position!.getWidthContainer() / 2 : 0.0;

    if (widget.container == null) {
      return Stack(
        children: [
          Positioned(
            top: contentY,
            left: _getLeft(),
            right: _getRight(),
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: widget.scaleAnimationAlignment ??
                  Alignment(
                    _getAlignmentX(),
                    _getAlignmentY(),
                  ),
              child: FractionalTranslation(
                translation: Offset(0.0, contentFractionalOffset as double),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.0, contentFractionalOffset / 10),
                    end: const Offset(0.0, 0.100),
                  ).animate(_movingAnimation),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      padding: widget.showArrow
                          ? EdgeInsets.only(
                              top: paddingTop - (isArrowUp ? arrowHeight : 0),
                              bottom: paddingBottom - (isArrowUp ? 0 : arrowHeight),
                            )
                          : null,
                      child: Stack(
                        alignment: isArrowUp
                            ? Alignment.topLeft
                            : _getLeft() == null
                                ? Alignment.bottomRight
                                : Alignment.bottomLeft,
                        children: [
                          if (widget.showArrow)
                            Positioned(
                              left: _getArrowLeft(arrowWidth),
                              right: _getArrowRight(arrowWidth),
                              child: CustomPaint(
                                painter: _Arrow(
                                  strokeColor: widget.tooltipBackgroundColor!,
                                  strokeWidth: 10,
                                  paintingStyle: PaintingStyle.fill,
                                  isUpArrow: isArrowUp,
                                ),
                                child: const SizedBox(
                                  height: arrowHeight,
                                  width: arrowWidth,
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: isArrowUp ? arrowHeight - 1 : 0,
                              bottom: isArrowUp ? 0 : arrowHeight - 1,
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  widget.tooltipBorderRadius ?? BorderRadius.circular(8.0),
                              child: GestureDetector(
                                onTap: widget.onTooltipTap,
                                child: Container(
                                  width: tooltipWidth,
                                  padding: widget.tooltipPadding,
                                  color: widget.tooltipBackgroundColor,
                                  child: Column(
                                    crossAxisAlignment: widget.title != null
                                        ? CrossAxisAlignment.start
                                        : CrossAxisAlignment.center,
                                    children: <Widget>[
                                      if (widget.title != null)
                                        Padding(
                                          padding: widget.titlePadding ?? EdgeInsets.zero,
                                          child: Text(
                                            widget.title!,
                                            textAlign: widget.titleAlignment,
                                            style: widget.titleTextStyle ??
                                                Theme.of(context).textTheme.titleLarge!.merge(
                                                      TextStyle(
                                                        color: widget.textColor,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      Padding(
                                        padding: widget.descriptionPadding ?? EdgeInsets.zero,
                                        child: Text(
                                          widget.description!,
                                          textAlign: widget.descriptionAlignment,
                                          style: widget.descTextStyle ??
                                              Theme.of(context).textTheme.titleSmall!.merge(
                                                    TextStyle(
                                                      color: widget.textColor,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.actions != null)
            Positioned(
              left: widget.actionButtonsPosition?.left ?? _getLeft(),
              right: widget.actionButtonsPosition?.right ?? _getRight(),
              top: widget.actionButtonsPosition?.top ?? actionTopPos,
              bottom: widget.actionButtonsPosition?.bottom,
              height: min((tooltipHeight - arrowHeight), 40),
              width: tooltipWidth,
              child: Container(
                height: 200,
                color: Colors.white,
                child: widget.actions,
              ),
            ),
        ],
      );
    }
    final targetWidth = widget.position!.getWidth();
    final targetHeight = widget.position!.getHeight();
    return Stack(
      children: <Widget>[
        Positioned(
          left: _getSpace() + offsetWhenCentered,
          top: contentY - 10,
          child: FractionalTranslation(
            translation: Offset(0.0, contentFractionalOffset as double),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, contentFractionalOffset / 10),
                end: !widget.showArrow && !isArrowUp
                    ? const Offset(0.0, 0.0)
                    : const Offset(0.0, 0.100),
              ).animate(_movingAnimation),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTooltipTap,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: paddingTop,
                    ),
                    color: Colors.transparent,
                    child: Center(
                      child: MeasureSize(
                        onSizeChange: onSizeChange,
                        child: widget.container,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.actions != null)
          Positioned(
            top: widget.actionButtonsPosition?.top ?? actionTopPosWithContainer,
            left: widget.actionButtonsPosition?.left ?? _getSpace(),
            right: widget.actionButtonsPosition?.right ?? _getRight(),
            bottom: widget.actionButtonsPosition?.bottom,
            child: Padding(
              padding: widget.actionSettings?.containerPadding ?? EdgeInsets.zero,
              child: Container(
                color: Colors.lightBlueAccent /*widget.actionSettings?.containerColor ?? */,
                height: widget.actionSettings?.containerHeight,
                width: widget.actionSettings?.containerWidth,
                child: widget.actions!,
              ),
            ),
          ),
        if (widget.overlayWidget != null) 
          Positioned(
            left: widget.position!.getCenter() - targetWidth / 2,
            top: widget.position!.getVerticalCenter() - targetHeight / 2,
            child: Container(
              alignment: widget.overlayAlignment,
              constraints: BoxConstraints(
                minWidth: targetWidth,
                minHeight: targetHeight,
              ),
              child: widget.overlayWidget!,
            ),
          ),
      ],
    );
  }

  void onSizeChange(Size? size) {
    var tempPos = position;
    tempPos = Offset(position!.dx, position!.dy + size!.height);
    setState(() => position = tempPos);
  }

  Size _textSize(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size;
  }

  double? _getArrowLeft(double arrowWidth) {
    final left = _getLeft();
    if (left == null) return null;
    return (widget.position!.getCenter() - (arrowWidth / 2) - left);
  }

  double? _getArrowRight(double arrowWidth) {
    if (_getLeft() != null) return null;
    return (MediaQuery.of(context).size.width - widget.position!.getCenter()) -
        (_getRight() ?? 0) -
        (arrowWidth / 2);
  }
}

class _Arrow extends CustomPainter {
  final Color strokeColor;
  final PaintingStyle paintingStyle;
  final double strokeWidth;
  final bool isUpArrow;
  final Paint _paint;

  _Arrow({
    this.strokeColor = Colors.black,
    this.strokeWidth = 3,
    this.paintingStyle = PaintingStyle.stroke,
    this.isUpArrow = true,
  }) : _paint = Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = paintingStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(getTrianglePath(size.width, size.height), _paint);
  }

  Path getTrianglePath(double x, double y) {
    if (isUpArrow) {
      return Path()
        ..moveTo(0, y)
        ..lineTo(x / 2, 0)
        ..lineTo(x, y)
        ..lineTo(0, y);
    }
    return Path()
      ..moveTo(0, 0)
      ..lineTo(x, 0)
      ..lineTo(x / 2, y)
      ..lineTo(0, 0);
  }

  @override
  bool shouldRepaint(covariant _Arrow oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.paintingStyle != paintingStyle ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
