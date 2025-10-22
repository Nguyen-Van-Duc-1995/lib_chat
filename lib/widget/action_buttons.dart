import 'package:chart/utils/colors.dart';
import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng Mua chưa cài đặt'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.controlButtonHover,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.priceUp),
            child: const Text(
              'MUA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng Bán chưa cài đặt'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.controlButtonHover,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priceDown,
            ),
            child: const Text(
              'BÁN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
