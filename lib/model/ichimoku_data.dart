class IchimokuData {
  final double tenkanSen;
  final double kijunSen;
  final double senkouSpanA;
  final double senkouSpanB;
  final double chikouSpan;
  final DateTime dateTime;

  IchimokuData({
    required this.tenkanSen,
    required this.kijunSen,
    required this.senkouSpanA,
    required this.senkouSpanB,
    required this.chikouSpan,
    required this.dateTime,
  });
}
