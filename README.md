# Chart Lib - Trading Dashboard

Ứng dụng Flutter mô phỏng giao diện giao dịch chứng khoán/crypto chuyên nghiệp với biểu đồ phân tích kỹ thuật thời gian thực.

## 🌟 Tính năng nổi bật

*   **Biểu đồ nến tương tác (Interactive Candlestick Chart):**
    *   Hỗ trợ Zoom, Pan, Crosshair, Tooltip tra cứu thông tin nến.
    *   Vẽ biểu đồ nến Nhật Bản (OHLC) mượt mà.
*   **Chỉ báo kỹ thuật (Technical Indicators):**
    *   **Overlay (Vẽ chồng):** EMA (20, 50), Bollinger Bands (BB), Ichimoku Cloud.
    *   **Sub-charts (Biểu đồ phụ):** Volume, RSI, MACD, MFI (Money Flow Index).
    *   Hỗ trợ bật/tắt nhanh các chỉ báo.
*   **Dữ liệu thời gian thực (Real-time):**
    *   Kết nối WebSocket để cập nhật giá (Ticker) và biểu đồ (K-line) ngay lập tức.
    *   **Sổ lệnh (Order Book):** Hiển thị danh sách Chờ Mua/Chờ Bán với trực quan hóa độ sâu (Depth bars).
    *   **Lịch sử khớp lệnh:** Theo dõi các giao dịch mới nhất (Lệnh khớp và Gộp khớp).
*   **Đa khung thời gian (Multi-timeframe):**
    *   Hỗ trợ chuyển đổi nhanh: 5m, 15m, 30m, 1h, 1 Ngày (1d), 1 Tuần, 1 Tháng.
*   **Giao diện linh hoạt (Responsive UI):**
    *   Tự động tối ưu layout cho màn hình Dọc (Portrait) và Ngang (Landscape).
    *   **Dark Mode:** Giao diện tối chuyên nghiệp cho Trader.

## 🛠 Công nghệ sử dụng

*   **Framework:** Flutter (Dart)
*   **State Management:** Provider
*   **Networking:**
    *   `web_socket_channel`: Kết nối dữ liệu thời gian thực.
    *   `http`: Gọi API lấy dữ liệu lịch sử.
*   **Core Logic:**
    *   `IndicatorCalculator`: Module tự xây dựng để tính toán các chỉ số kỹ thuật từ dữ liệu thô.

## 🚀 Cài đặt và chạy

1.  **Yêu cầu:** Đảm bảo đã cài đặt Flutter SDK.

2.  **Cài đặt thư viện:**
    ```bash
    flutter pub get
    ```

3.  **Chạy ứng dụng:**
    ```bash
    flutter run
    ```

## 📂 Cấu trúc dự án chính

*   `lib/candlestick/`: Chứa logic vẽ biểu đồ (Painter) và các Mixin vẽ chỉ báo.
*   `lib/providers/`: Quản lý trạng thái ứng dụng (`TradingViewModel`).
*   `lib/utils/`: Các công cụ tiện ích, đặc biệt là `indicator_calculator.dart` (Logic tính toán chỉ báo).
*   `lib/model/`: Định nghĩa dữ liệu (KlineData, TradeEntry, OrderBookEntry...).
*   `lib/section/`: Các thành phần giao diện lớn (Header, MarketInfo, OrderBook...).
*   `lib/widget/`: Các widget nhỏ tái sử dụng (Controls, Buttons).

---
*Dự án Trading Dashboard Demo.*
