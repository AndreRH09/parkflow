import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/domain/entities/booking.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

/// HU-13 — Ganancias del anfitrión. Resumen + gráfico de barras (últimos 7 días).
/// Solo cuenta reservas no canceladas.
class EarningsPage extends ConsumerWidget {
  const EarningsPage({super.key});

  static const _dayLabels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(hostBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      appBar: AppBar(
        title: const Text('Ganancias',
            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter')),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(hostBookingsProvider),
        child: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text('Error al cargar ganancias\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontFamily: 'Inter')),
              ),
            ],
          ),
          data: (bookings) => _content(context, bookings),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<Booking> bookings) {
    final valid = bookings.where((b) => !b.isCancelled).toList();
    final total = valid.fold<double>(0, (s, b) => s + b.totalAmount);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Últimos 7 días: index 0 = hace 6 días, 6 = hoy.
    final dailyTotals = List<double>.filled(7, 0);
    final weekStart = today.subtract(const Duration(days: 6));
    double weekTotal = 0;
    for (final b in valid) {
      final d = DateTime(b.startTime.year, b.startTime.month, b.startTime.day);
      final diff = d.difference(weekStart).inDays;
      if (diff >= 0 && diff < 7) {
        dailyTotals[diff] += b.totalAmount;
        weekTotal += b.totalAmount;
      }
    }
    final maxVal = dailyTotals.fold<double>(0, (m, v) => v > m ? v : m);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total acumulado',
                value: 'S/ ${total.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_rounded,
                highlight: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Esta semana',
                value: 'S/ ${weekTotal.toStringAsFixed(2)}',
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Reservas',
                value: '${valid.length}',
                icon: Icons.event_available_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Promedio',
                value: valid.isEmpty
                    ? 'S/ 0.00'
                    : 'S/ ${(total / valid.length).toStringAsFixed(2)}',
                icon: Icons.bar_chart_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Últimos 7 días',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.graphite,
              fontFamily: 'Inter',
            )),
        const SizedBox(height: 16),
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.graphite.withAlpha(10),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: maxVal == 0
              ? const Center(
                  child: Text('Sin ganancias esta semana',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontFamily: 'Inter')),
                )
              : BarChart(_barData(dailyTotals, maxVal, weekStart)),
        ),
      ],
    );
  }

  BarChartData _barData(List<double> totals, double maxVal, DateTime weekStart) {
    return BarChartData(
      maxY: maxVal * 1.2,
      alignment: BarChartAlignment.spaceAround,
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i > 6) return const SizedBox.shrink();
              final day = weekStart.add(Duration(days: i));
              final label = _dayLabels[(day.weekday - 1) % 7];
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    )),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            'S/ ${rod.toY.toStringAsFixed(2)}',
            const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
      barGroups: List.generate(7, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: totals[i],
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              color: AppColors.mustard,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal * 1.2,
                color: AppColors.dustGray.withAlpha(40),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? AppColors.graphite : AppColors.white;
    final fg = highlight ? AppColors.white : AppColors.graphite;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withAlpha(highlight ? 30 : 10),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: highlight ? AppColors.mustard : AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFamily: 'Inter',
              )),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: highlight
                    ? AppColors.white.withAlpha(180)
                    : AppColors.textSecondary,
                fontFamily: 'Inter',
              )),
        ],
      ),
    );
  }
}
