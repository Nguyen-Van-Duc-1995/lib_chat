import 'package:chart/chart_screen.dart';
import 'package:chart/utils/colors.dart';
import 'package:chart/utils/format.dart';
import 'package:flutter/material.dart';

class MarketInfoSection extends StatelessWidget {
  final TradingViewModel viewModel;
  const MarketInfoSection({super.key, required this.viewModel});
  Widget _buildInfoRow(
    String label,
    String value, {
    Color valueColor = AppColors.textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ), // Đã sửa: Bỏ const
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticker = viewModel.tickerData;
    if (ticker == null && viewModel.isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentYellow),
      );
    if (ticker == null)
      return const Center(
        child: Text(
          "Không có dữ liệu thị trường.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    final bool isPositiveChange = ticker.priceChange >= 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin ${ticker.symbol}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Giá hiện tại',
            FormatUtils.formatPrice(ticker.currentPrice),
            valueColor: isPositiveChange
                ? AppColors.priceUp
                : AppColors.priceDown,
          ),
          _buildInfoRow(
            'Thay đổi 24h',
            '${isPositiveChange ? '+' : ''}${FormatUtils.formatPrice(ticker.priceChange, decimalPlaces: 2)} (${isPositiveChange ? '+' : ''}${ticker.priceChangePercent.toStringAsFixed(2)}%)',
            valueColor: isPositiveChange
                ? AppColors.priceUp
                : AppColors.priceDown,
          ),
          _buildInfoRow(
            'Cao nhất 24h',
            FormatUtils.formatPrice(ticker.high24h),
          ),
          _buildInfoRow(
            'Thấp nhất 24h',
            FormatUtils.formatPrice(ticker.low24h),
          ),
          _buildInfoRow(
            'KL 24h (${ticker.symbol.replaceAll("USDT", "").replaceAll("BUSD", "")})',
            FormatUtils.formatNumber(ticker.volume24h, decimalPlaces: 3),
          ),
          _buildInfoRow(
            'KL 24h (USDT)',
            FormatUtils.formatNumber(
              ticker.volume24h * ticker.currentPrice,
              decimalPlaces: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mô tả (ví dụ)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ), // Bỏ const
        ],
      ),
    ); // Bỏ const
  }
}
