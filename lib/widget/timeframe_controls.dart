import 'package:flutter/material.dart';
import 'package:chart/chart_screen.dart';

import '../utils/colors.dart';

class TimeframeControls extends StatelessWidget {
  /* ... giữ nguyên ... */
  final TradingViewModel viewModel;
  const TimeframeControls({super.key, required this.viewModel});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.timeframes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final timeframe = viewModel.timeframes[index];
          final bool isActive = viewModel.currentInterval == timeframe;
          return TextButton(
            onPressed: () => viewModel.changeTimeframe(timeframe),
            style:
                TextButton.styleFrom(
                  backgroundColor: isActive
                      ? Color(0xff2EAA7A)
                      : AppColors.controlButton,
                  foregroundColor: isActive
                      ? AppColors.background
                      : AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  minimumSize: const Size(40, 29),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.hovered))
                      return AppColors.controlButtonHover;
                    return null;
                  }),
                ),
            child: Text(
              timeframe,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
