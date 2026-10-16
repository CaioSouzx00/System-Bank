import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_theme_extension.dart';

class BankShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const BankShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;

    return Shimmer.fromColors(
      baseColor: bankTheme.shimmerBase,
      highlightColor: bankTheme.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppDimensions.borderRadiusSm,
        ),
      ),
    );
  }
}

class BankShimmerListTile extends StatelessWidget {
  const BankShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          const BankShimmerBox(
            width: 44,
            height: 44,
            borderRadius: AppDimensions.borderRadiusPill,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BankShimmerBox(width: 140, height: 16),
                const SizedBox(height: 6),
                BankShimmerBox(width: 90, height: 12),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          const BankShimmerBox(width: 70, height: 18),
        ],
      ),
    );
  }
}

class BankShimmerCard extends StatelessWidget {
  final double height;

  const BankShimmerCard({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;

    return Shimmer.fromColors(
      baseColor: bankTheme.shimmerBase,
      highlightColor: bankTheme.shimmerHighlight,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDimensions.borderRadiusLg,
        ),
      ),
    );
  }
}
