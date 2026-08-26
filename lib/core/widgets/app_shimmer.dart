import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSizes.r8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class AppShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double itemWidth;
  final double spacing;

  const AppShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 100,
    this.itemWidth = double.infinity,
    this.spacing = AppSizes.p16,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        return AppShimmer(
          width: itemWidth,
          height: itemHeight,
          borderRadius: AppSizes.r12,
        );
      },
    );
  }
}
