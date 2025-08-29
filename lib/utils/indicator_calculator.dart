import 'package:chart/model/indicator_point.dart';
import 'package:chart/model/kline_data.dart';
import '../model/ichimoku_data.dart';

class IndicatorCalculator {
  static List<double> calculateEMA(List<double> values, int period) {
    if (values.isEmpty || values.length < period) return [];

    List<double> ema = [];
    double multiplier = 2.0 / (period + 1);

    // Tính SMA cho giá trị đầu tiên
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += values[i];
    }
    ema.add(sum / period);

    // Tính EMA cho các giá trị tiếp theo
    for (int i = period; i < values.length; i++) {
      double emaValue = (values[i] - ema.last) * multiplier + ema.last;
      ema.add(emaValue);
    }

    return ema;
  }

  static List<double> calculateRSI(List<double> closes, int period) {
    if (closes.length < period) return [];

    List<double> rsi = [];
    double gain = 0, loss = 0;

    for (int i = 1; i <= period; i++) {
      double change = closes[i] - closes[i - 1];
      if (change >= 0)
        gain += change;
      else
        loss -= change;
    }

    gain /= period;
    loss /= period;
    rsi.add(100 - (100 / (1 + gain / (loss == 0 ? 1e-10 : loss))));

    for (int i = period + 1; i < closes.length; i++) {
      double change = closes[i] - closes[i - 1];
      double currentGain = change > 0 ? change : 0;
      double currentLoss = change < 0 ? -change : 0;

      gain = (gain * (period - 1) + currentGain) / period;
      loss = (loss * (period - 1) + currentLoss) / period;

      rsi.add(100 - (100 / (1 + gain / (loss == 0 ? 1e-10 : loss))));
    }

    return rsi;
  }

  static MACDData calculateMACD(
    List<KlineData> klines, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    if (klines.length < slowPeriod + signalPeriod - 1)
      return MACDData(macdLine: [], signalLine: [], histogram: []);
    List<double> closes = klines.map((k) => k.close).toList();
    List<double> emaFast = calculateEMA(closes, fastPeriod);
    List<double> emaSlow = calculateEMA(closes, slowPeriod);
    if (emaFast.isEmpty || emaSlow.isEmpty)
      return MACDData(macdLine: [], signalLine: [], histogram: []);
    List<double> macdValues = [];
    List<IndicatorPoint> macdLine = [];
    int commonLength = emaSlow.length;
    int fastEmaOffset = emaFast.length - commonLength;
    for (int i = 0; i < commonLength; i++) {
      double macd = emaFast[i + fastEmaOffset] - emaSlow[i];
      macdValues.add(macd);
      macdLine.add(IndicatorPoint(klines[slowPeriod - 1 + i].dateTime, macd));
    }
    if (macdValues.length < signalPeriod)
      return MACDData(macdLine: macdLine, signalLine: [], histogram: []);
    List<double> signalValues = calculateEMA(macdValues, signalPeriod);
    if (signalValues.isEmpty)
      return MACDData(macdLine: macdLine, signalLine: [], histogram: []);
    List<IndicatorPoint> signalLinePoints = [], histogramPoints = [];
    int macdStartIndexForSignal = signalPeriod - 1;
    for (int i = 0; i < signalValues.length; i++) {
      DateTime time = macdLine[macdStartIndexForSignal + i].time;
      signalLinePoints.add(IndicatorPoint(time, signalValues[i]));
      histogramPoints.add(
        IndicatorPoint(
          time,
          macdValues[macdStartIndexForSignal + i] - signalValues[i],
        ),
      );
    }
    List<IndicatorPoint> trimmedMacdLine = macdLine.sublist(
      macdStartIndexForSignal,
    );
    return MACDData(
      macdLine: trimmedMacdLine,
      signalLine: signalLinePoints,
      histogram: histogramPoints,
    );
  }

  static List<IndicatorPoint> calculateMFI(List<KlineData> klines, int period) {
    if (klines.length < period + 1) return [];

    List<double> typicalPrices = klines
        .map((e) => (e.high + e.low + e.close) / 3)
        .toList();

    List<double> rawMoneyFlows = List.generate(
      klines.length,
      (i) => typicalPrices[i] * klines[i].volume,
    );

    List<IndicatorPoint> mfiValues = [];

    for (int i = period; i < klines.length; i++) {
      double positiveFlow = 0.0;
      double negativeFlow = 0.0;

      for (int j = i - period + 1; j <= i; j++) {
        if (j == 0) continue;

        double currTP = typicalPrices[j];
        double prevTP = typicalPrices[j - 1];

        if (currTP > prevTP) {
          positiveFlow += rawMoneyFlows[j];
        } else if (currTP < prevTP) {
          negativeFlow += rawMoneyFlows[j];
        }
      }

      double mfi;
      if (positiveFlow == 0 && negativeFlow == 0) {
        mfi = 50.0;
      } else if (negativeFlow == 0) {
        mfi = 100.0;
      } else {
        double moneyRatio = positiveFlow / negativeFlow;
        mfi = 100 - (100 / (1 + moneyRatio));
      }

      mfiValues.add(IndicatorPoint(klines[i].dateTime, mfi));
    }

    return mfiValues;
  }

  // New Ichimoku calculator
  static List<IchimokuData> calculateIchimoku(
    List<KlineData> klines, {
    int tenkanPeriod = 9, // Conversion Line period
    int kijunPeriod = 26, // Base Line period
    int senkouSpanBPeriod = 52, // Leading Span B period
    int displacement = 26, // Displacement for cloud
  }) {
    if (klines.length < senkouSpanBPeriod) return [];

    List<IchimokuData> result = [];

    for (int i = 0; i < klines.length; i++) {
      double tenkanSen = 0;
      double kijunSen = 0;
      double senkouSpanA = 0;
      double senkouSpanB = 0;
      double chikouSpan = klines[i].close;

      // Calculate Tenkan-sen (Conversion Line) - (9-period high + 9-period low) / 2
      if (i >= tenkanPeriod - 1) {
        double highestHigh = klines[i - tenkanPeriod + 1].high;
        double lowestLow = klines[i - tenkanPeriod + 1].low;

        for (int j = i - tenkanPeriod + 2; j <= i; j++) {
          if (klines[j].high > highestHigh) highestHigh = klines[j].high;
          if (klines[j].low < lowestLow) lowestLow = klines[j].low;
        }
        tenkanSen = (highestHigh + lowestLow) / 2;
      }

      // Calculate Kijun-sen (Base Line) - (26-period high + 26-period low) / 2
      if (i >= kijunPeriod - 1) {
        double highestHigh = klines[i - kijunPeriod + 1].high;
        double lowestLow = klines[i - kijunPeriod + 1].low;

        for (int j = i - kijunPeriod + 2; j <= i; j++) {
          if (klines[j].high > highestHigh) highestHigh = klines[j].high;
          if (klines[j].low < lowestLow) lowestLow = klines[j].low;
        }
        kijunSen = (highestHigh + lowestLow) / 2;
      }

      // Calculate Senkou Span A (Leading Span A) - (Tenkan-sen + Kijun-sen) / 2
      if (i >= kijunPeriod - 1) {
        senkouSpanA = (tenkanSen + kijunSen) / 2;
      }

      // Calculate Senkou Span B (Leading Span B) - (52-period high + 52-period low) / 2
      if (i >= senkouSpanBPeriod - 1) {
        double highestHigh = klines[i - senkouSpanBPeriod + 1].high;
        double lowestLow = klines[i - senkouSpanBPeriod + 1].low;

        for (int j = i - senkouSpanBPeriod + 2; j <= i; j++) {
          if (klines[j].high > highestHigh) highestHigh = klines[j].high;
          if (klines[j].low < lowestLow) lowestLow = klines[j].low;
        }
        senkouSpanB = (highestHigh + lowestLow) / 2;
      }

      result.add(
        IchimokuData(
          tenkanSen: tenkanSen,
          kijunSen: kijunSen,
          senkouSpanA: senkouSpanA,
          senkouSpanB: senkouSpanB,
          chikouSpan: chikouSpan,
          dateTime: klines[i].dateTime,
        ),
      );
    }

    return result;
  }

  // Helper method to get high and low over a period
  static Map<String, double> _getHighLowOverPeriod(
    List<KlineData> klines,
    int startIndex,
    int period,
  ) {
    if (startIndex < 0 || startIndex + period > klines.length) {
      return {'high': 0.0, 'low': 0.0};
    }

    double high = klines[startIndex].high;
    double low = klines[startIndex].low;

    for (int i = startIndex + 1; i < startIndex + period; i++) {
      if (klines[i].high > high) high = klines[i].high;
      if (klines[i].low < low) low = klines[i].low;
    }

    return {'high': high, 'low': low};
  }
}
