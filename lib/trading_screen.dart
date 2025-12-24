import 'package:chart/providers/trading_view_model.dart';
import 'package:chart/section/header_section.dart';
import 'package:chart/section/market_info_section.dart';
import 'package:chart/section/trade_history_section.dart';
import 'package:chart/widget/action_buttons.dart';
import 'package:chart/widget/buy_sell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:chart/candlestick/chart_section.dart';
import 'package:chart/widget/indicator_shortcut_controls.dart';
import 'package:chart/widget/timeframe_controls.dart';

import 'utils/colors.dart';

class TradingScreen extends StatefulWidget {
  final String symbol;
  const TradingScreen({super.key, this.symbol = 'AAA'});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Giảm từ 3 còn 2
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        Provider.of<TradingViewModel>(
          context,
          listen: false,
        ).setSelectedTab(_tabController.index);
        HapticFeedback.selectionClick();
      } else if (!_tabController.indexIsChanging &&
          _tabController.index !=
              Provider.of<TradingViewModel>(
                context,
                listen: false,
              ).selectedTab) {
        if (mounted) {
          _tabController.animateTo(
            Provider.of<TradingViewModel>(context, listen: false).selectedTab,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<TradingViewModel>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.updateSymbol(widget.symbol);
    });

    if (_tabController.index != viewModel.selectedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.animateTo(viewModel.selectedTab);
      });
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget block1 = Column(
      children: [
        if (!isLandscape) HeaderSection(viewModel: viewModel),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: AppColors.background,
          child: TimeframeControls(viewModel: viewModel),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: AppColors.background,
          child: IndicatorShortcutControls(viewModel: viewModel),
        ),
        ChartSection(viewModel: viewModel),
      ],
    );

    Widget block2 = Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accentYellow,
            indicatorWeight: 3,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: AppColors.border,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Lệnh khớp'),
              Tab(text: 'Gộp khớp'),
              Tab(text: 'Thông tin'),
            ],
          ),
          SizedBox(height: 8),
          if (_tabController.index != 2)
            BuySellBar(buy: viewModel.latestTrade, sell: viewModel.latestTrade),
          SizedBox(
            height: isLandscape ? 220 : 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                TradeHistorySection(viewModel: viewModel),
                TradeHistorySection(viewModel: viewModel, isGrouped: true),
                MarketInfoSection(viewModel: viewModel),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: AppColors.background,
            child: const ActionButtons(),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLandscape
            ? Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(flex: 6, child: block1),
                        VerticalDivider(width: 0.5, color: AppColors.border),
                        Expanded(flex: 4, child: block2),
                      ],
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    if (!isLandscape) HeaderSection(viewModel: viewModel),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      color: AppColors.background,
                      child: TimeframeControls(viewModel: viewModel),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      color: AppColors.background,
                      child: IndicatorShortcutControls(viewModel: viewModel),
                    ),
                    ChartSection(viewModel: viewModel),
                    block2,
                  ],
                ),
              ),
      ),
    );
  }
}
