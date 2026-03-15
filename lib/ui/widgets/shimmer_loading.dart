import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerLoading.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.gray200,
      highlightColor: AppTheme.gray100,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: AppTheme.gray400,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class TransactionShimmer extends StatelessWidget {
  const TransactionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border.all(color: AppTheme.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          ShimmerLoading.rectangular(height: 20, width: 60),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerLoading.rectangular(height: 14, width: 120),
                SizedBox(height: 8),
                ShimmerLoading.rectangular(height: 10, width: 80),
              ],
            ),
          ),
          SizedBox(width: 12),
          ShimmerLoading.circular(width: 36, height: 36),
        ],
      ),
    );
  }
}

class OfflineTokenShimmer extends StatelessWidget {
  const OfflineTokenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        border: Border.all(color: AppTheme.gray200),
      ),
      child: const Row(
        children: [
          ShimmerLoading.rectangular(height: 20, width: 60),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.rectangular(height: 14, width: 140),
                SizedBox(height: 8),
                ShimmerLoading.rectangular(height: 10, width: 100),
              ],
            ),
          ),
          SizedBox(width: 16),
          ShimmerLoading.rectangular(height: 12, width: 40),
        ],
      ),
    );
  }
}
