import 'package:chart/chart_screen.dart';
import 'package:chart/utils/colors.dart';
import 'package:chart/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HeaderSection extends StatelessWidget {
  final TradingViewModel viewModel;
  const HeaderSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final ticker = viewModel.tickerData;
    if (ticker == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.cardBackground,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accentYellow),
        ),
      );
    }

    final bool isPositiveChange = ticker.priceChangePercent >= 0;

    // Get exchange data
    final vnindexData = _getExchangeData('VNINDEX');
    final vn30Data = _getExchangeData('VN30');

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.gridLine.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Back button + Symbol + Star + Notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HOSE',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ticker.symbol,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      FormatUtils.formatPrice(
                        ticker.currentPrice / 1000,
                        decimalPlaces: 2,
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPositiveChange
                            ? AppColors.priceUp
                            : AppColors.priceDown,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isPositiveChange
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                      color: isPositiveChange
                          ? AppColors.priceUp
                          : AppColors.priceDown,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositiveChange ? '+' : ''}${FormatUtils.formatPrice(ticker.priceChange / 1000, decimalPlaces: 2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPositiveChange
                            ? AppColors.priceUp
                            : AppColors.priceDown,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${isPositiveChange ? '+' : ''}${ticker.priceChangePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPositiveChange
                            ? AppColors.priceUp
                            : AppColors.priceDown,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.accentYellow, size: 24),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Subtitle (Ngân hàng TMCP Quân đội)
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              'Ngân hàng TMCP Quân đội',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          // Row 2: New layout - 2 columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Price info
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoItem(
                                'Cao:',
                                FormatUtils.formatPrice(
                                  ticker.high24h / 1000,
                                  decimalPlaces: 2,
                                ),
                                AppColors.textSecondary,
                              ),
                              const SizedBox(height: 6),
                              _buildInfoItem(
                                'Thấp:',
                                FormatUtils.formatPrice(
                                  ticker.low24h / 1000,
                                  decimalPlaces: 2,
                                ),
                                AppColors.textSecondary,
                              ),
                              const SizedBox(height: 6),
                              _buildInfoItem(
                                'KL:',
                                formatValue(ticker.volume24h),
                                AppColors.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(width: 21),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoItem(
                                'Trần:',
                                FormatUtils.formatPrice(
                                  ticker.ceiling / 1000,
                                  decimalPlaces: 2,
                                ),
                                AppColors.priceUp,
                              ),
                              const SizedBox(height: 6),
                              _buildInfoItem(
                                'Sàn:',
                                FormatUtils.formatPrice(
                                  ticker.floor / 1000,
                                  decimalPlaces: 2,
                                ),
                                AppColors.priceDown,
                              ),
                              const SizedBox(height: 6),
                              _buildInfoItem(
                                'TC:',
                                FormatUtils.formatPrice(
                                  ticker.refPrice / 1000,
                                  decimalPlaces: 2,
                                ),
                                AppColors.accentYellow,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Right Column: Change percentage and index info
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // VNINDEX row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoItem(
                            'VNINDEX',
                            (vnindexData?['IndexValue'] ?? 1140.0)
                                .toStringAsFixed(2),
                            AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoItem(
                            '',
                            '${(vnindexData?['Change'] ?? 0.0) >= 0 ? '+' : ''}${(vnindexData?['Change'] ?? 0.0).toStringAsFixed(2)}',
                            (vnindexData?['Change'] ?? 0.0) >= 0
                                ? AppColors.priceUp
                                : AppColors.priceDown,
                            showLabel: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // VN30 row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoItem(
                            'VN30',
                            (vn30Data?['IndexValue'] ?? 1540.0).toStringAsFixed(
                              2,
                            ),
                            AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoItem(
                            '',
                            '${(vn30Data?['Change'] ?? 0.0) >= 0 ? '+' : ''}${(vn30Data?['Change'] ?? 0.0).toStringAsFixed(2)}',
                            (vn30Data?['Change'] ?? 0.0) >= 0
                                ? AppColors.priceUp
                                : AppColors.priceDown,
                            showLabel: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildInfoItem(
                        'Ngành',
                        'ACB, CTG, VCB, TCB',
                        AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get exchange data by IndexId
  Map<String, dynamic>? _getExchangeData(String indexId) {
    if (viewModel.exchange == null) return null;

    try {
      final Map<String, dynamic> data = (viewModel.exchange as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((item) => item['IndexId'] == indexId, orElse: () => {});
      return data;
    } catch (e) {
      return null;
    }
  }

  Widget _buildInfoItem(
    String label,
    String value,
    Color valueColor, {
    bool showLabel = true,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        if (showLabel) const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: valueColor,
            fontWeight: showLabel ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String formatValue(num value) {
    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(1)}K tỷ';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
    return value.toString();
  }
}
