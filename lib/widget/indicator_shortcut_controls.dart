import 'package:flutter/material.dart';

import '../chart_screen.dart';
import '../utils/colors.dart';

class IndicatorShortcutControls extends StatelessWidget {
  final TradingViewModel viewModel;
  const IndicatorShortcutControls({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 29,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.indicators.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final label = viewModel.indicators[index];
          final isActive = _isIndicatorActive(viewModel, label);
          return TextButton(
            onPressed: () => _onPressed(viewModel, label, context),
            style: TextButton.styleFrom(
              backgroundColor: isActive
                  ? AppColors.accentYellow
                  : AppColors.controlButton,
              foregroundColor: isActive
                  ? AppColors.background
                  : AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: const Size(40, 29),
            ),
            child: Text(
              label,
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

  bool _isIndicatorActive(TradingViewModel vm, String label) {
    switch (label) {
      case 'EMA20':
        return vm.showEMA20;
      case 'EMA50':
        return vm.showEMA50;
      case 'BB':
        return vm.showBB;
      case 'Volume':
        return vm.showVolume;
      case 'RSI':
        return vm.showRSI;
      case 'MACD':
        return vm.showMACD;
      case 'MFI':
        return vm.showMFI;
      case 'Ichimoku':
        return vm.showIchimoku;
      default:
        return false;
    }
  }

  void _onPressed(TradingViewModel vm, String label, BuildContext context) {
    switch (label) {
      case 'EMA20':
        vm.toggleMA20(!vm.showEMA20);
        break;
      case 'EMA50':
        vm.toggleMA50(!vm.showEMA50);
        break;
      case 'BB':
        vm.toggleBB(!vm.showBB);
        break;
      case 'Volume':
        vm.toggleVolume(!vm.showVolume);
        break;
      case 'RSI':
        vm.toggleRSI(!vm.showRSI);
        break;
      case 'MACD':
        vm.toggleMACD(!vm.showMACD);
        break;
      case 'MFI':
        vm.toggleMFI(!vm.showMFI);
        break;
      case 'Ichimoku':
        vm.toggleIchimoku(!vm.showIchimoku);
        break;
      case 'More':
        showMenu(
          context: context,
          position: const RelativeRect.fromLTRB(70, 215, 0, 0),
          items: [
            PopupMenuItem<void>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Đóng menu
                  // xử lý thêm
                  vm.showRSI;
                },
                style: TextButton.styleFrom(
                  minimumSize: Size(40, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text("RSI", style: TextStyle(fontSize: 13)),
              ),
            ),
            PopupMenuItem<void>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Đóng menu
                  // xử lý thêm
                  vm.showMFI;
                },
                style: TextButton.styleFrom(
                  minimumSize: Size(40, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text("MFI", style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        );
        break;
    }
  }
}
