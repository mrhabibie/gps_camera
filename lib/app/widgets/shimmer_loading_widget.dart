import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoadingWidget extends StatelessWidget {
  const ShimmerLoadingWidget({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  }) : super(key: key);

  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height ?? 20,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: width ?? double.infinity,
            height: height ?? 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  borderRadius ?? BorderRadius.circular((height ?? 20) / 2),
            ),
          ),
        ),
      ),
    );
  }
}
