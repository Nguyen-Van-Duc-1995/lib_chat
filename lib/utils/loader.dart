import 'package:flutter/material.dart';
import 'package:chart/utils/colors.dart';

class GlowingLoader extends StatefulWidget {
  const GlowingLoader({super.key});

  @override
  State<GlowingLoader> createState() => _GlowingLoaderState();
}

class _GlowingLoaderState extends State<GlowingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 19; // tổng kích thước
    const double barWidth = 1.5; // độ dày
    const double barHeight = 5; // chiều dài

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 6.283, // 2 * pi
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(5, (i) {
                  // 360 / 5 = 72° mỗi cờ
                  final double rotation = i * (6.283 / 5);
                  return Transform.rotate(
                    angle: rotation,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: barWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1.5),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentYellow.withOpacity(0.85),
                              AppColors.accentYellow.withOpacity(0.15),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentYellow.withOpacity(0.25),
                              blurRadius: 2,
                              spreadRadius: 0.3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}
