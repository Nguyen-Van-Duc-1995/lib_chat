class IndicatorPoint {
  final DateTime time;
  final double value;
  IndicatorPoint(this.time, this.value);
}

class MACDData {
  final List<IndicatorPoint> macdLine;
  final List<IndicatorPoint> signalLine;
  final List<IndicatorPoint> histogram;
  MACDData({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}
