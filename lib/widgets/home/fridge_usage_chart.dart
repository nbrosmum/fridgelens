import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FridgeUsageChart extends StatelessWidget {
  final List<FlSpot> usedSpots;
  final List<FlSpot> clearSpots;
  final String filterLabel; // e.g. 'Week', 'Month', 'Year'
  final List<String> xLabels;
  final List<String> xDates; // new: for tooltip date

  const FridgeUsageChart({
    super.key,
    required this.usedSpots,
    required this.clearSpots,
    required this.filterLabel,
    required this.xLabels,
    this.xDates = const [], // optional, fallback to xLabels if not provided
  });

  @override
  Widget build(BuildContext context) {
    final hasData =
        usedSpots.any((s) => s.y > 0) || clearSpots.any((s) => s.y > 0);
    if (!hasData) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.12),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    clipData: FlClipData(
                      left: false,
                      top: false,
                      right: false,
                      bottom: false,
                    ),
                    minY: 0,
                    maxY: _getMaxY(usedSpots, clearSpots),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ), // Hide x-axis labels
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: usedSpots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.08),
                        ),
                        isStrokeCapRound: true,
                        showingIndicators: List.generate(
                          usedSpots.length,
                          (i) => i,
                        ),
                      ),
                      LineChartBarData(
                        spots: clearSpots,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.red.withOpacity(0.08),
                        ),
                        isStrokeCapRound: true,
                        showingIndicators: List.generate(
                          clearSpots.length,
                          (i) => i,
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches:
                          true, // Allow tooltip to show on tap as well as long press
                      touchSpotThreshold: 20, // Improve touch sensitivity
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.white,
                        showOnTopOfTheChartBoxArea:
                            true, // Show tooltip above chart area (if supported)
                        tooltipMargin:
                            -100, // Lower the tooltip closer to the point
                        getTooltipItems: (touchedSpots) {
                          if (touchedSpots.isEmpty) return [];
                          final idx = touchedSpots.first.x.toInt();
                          final dateStr =
                              (xDates.isNotEmpty && idx < xDates.length)
                              ? xDates[idx]
                              : (idx < xLabels.length ? xLabels[idx] : '');
                          // Show both used and waste for the same date
                          return touchedSpots.map((spot) {
                            final label = spot.barIndex == 0 ? 'Used' : 'Waste';
                            return LineTooltipItem(
                              '$dateStr\n$label: ${spot.y.toInt()}',
                              TextStyle(
                                color: spot.barIndex == 0
                                    ? Colors.blue
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24), // Space between chart and legend
              Row(
                children: [
                  _buildLegendDot(Colors.blue),
                  const SizedBox(width: 4),
                  const Text('Used', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  _buildLegendDot(Colors.red),
                  const SizedBox(width: 4),
                  const Text('Waste', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      filterLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getMaxY(List<FlSpot> a, List<FlSpot> b) {
    final maxA = a.isNotEmpty
        ? a.map((e) => e.y).reduce((v, e) => v > e ? v : e)
        : 0;
    final maxB = b.isNotEmpty
        ? b.map((e) => e.y).reduce((v, e) => v > e ? v : e)
        : 0;
    return (maxA > maxB ? maxA : maxB) + 1;
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
