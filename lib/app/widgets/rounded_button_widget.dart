import 'package:flutter/material.dart';

class RoundedButtonWidget extends StatelessWidget {
  final String label;
  final double? paddingTop;
  final Color? backgroundColor, textColor;
  final Color? outlineColor;
  final Widget? child;
  final void Function()? onPressed;
  final double? height;
  final double? borderRadius;
  final BorderSide? borderSide;

  RoundedButtonWidget({
    required this.label,
    this.paddingTop,
    this.backgroundColor,
    this.textColor,
    this.outlineColor,
    this.child,
    required this.onPressed,
    this.height,
    this.borderRadius,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: paddingTop ?? 0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: child != null
            ? child
            : Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor ?? Colors.white,
                ),
              ),
        style: ButtonStyle(
          fixedSize: MaterialStateProperty.all(
            Size(MediaQuery.of(context).size.width, height ?? 54),
          ),
          backgroundColor:
              MaterialStateProperty.all(backgroundColor ?? Color(0xff478BFF)),
          elevation: MaterialStateProperty.all(0),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 10),
              side: borderSide != null
                  ? borderSide!
                  : outlineColor != null
                      ? BorderSide(color: outlineColor!)
                      : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
