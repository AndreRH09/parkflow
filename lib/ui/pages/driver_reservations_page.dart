import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/domain/entities/booking.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class DriverReservationsPage extends StatefulWidget {
  const DriverReservationsPage({super.key});

  @override
  State<DriverReservationsPage> createState() => _DriverReservationsPageState();
}

class _DriverReservationsPageState extends State<DriverReservationsPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: initSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      body: Consumer(
        builder: (context, ref, _) {
          final activeBooking = ref.watch(activeBookingProvider);
          final bookings = ref.watch(driverBookingsProvider);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active booking section
                  const Text(
                    'Reserva Activa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.graphite),
                  ),
                  const SizedBox(height: 12),
                  activeBooking.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error: $e'),
                    data: (booking) => booking == null
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('No tienes reservas activas', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : _ActiveBookingTimer(booking: booking),
                  ),
                  const SizedBox(height: 32),
                  // Past bookings
                  const Text(
                    'Historial de Reservas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.graphite),
                  ),
                  const SizedBox(height: 12),
                  bookings.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error: $e'),
                    data: (list) => list.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('No tienes reservas', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : Column(
                            children: list
                                .map((b) => Card(
                                      color: AppColors.white,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(b.spotAddress ?? 'Reserva'),
                                        subtitle: Text(
                                          'Desde: ${b.startTime?.toString().split('.')[0] ?? "N/A"}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: _statusBadge(b.status),
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    switch (status) {
      case 'reserved':
      case 'active':
        bgColor = AppColors.mustard;
        break;
      case 'pending':
        bgColor = Colors.orange;
        break;
      case 'cancelled':
      case 'rejected':
        bgColor = Colors.red;
        break;
      default:
        bgColor = AppColors.dustGray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status,
        style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActiveBookingTimer extends ConsumerStatefulWidget {
  final Booking booking;

  const _ActiveBookingTimer({required this.booking});

  @override
  ConsumerState<_ActiveBookingTimer> createState() => _ActiveBookingTimerState();
}

class _ActiveBookingTimerState extends ConsumerState<_ActiveBookingTimer> {
  late Timer _timer;
  late Duration _remaining;
  bool _notified10Min = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      _check10MinWarning();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.booking.endTime!.difference(now);
    setState(() => _remaining = remaining.isNegative ? Duration.zero : remaining);
  }

  Future<void> _check10MinWarning() async {
    if (_remaining.inMinutes == 10 && !_notified10Min) {
      _notified10Min = true;
      try {
        await flutterLocalNotificationsPlugin.show(
          1,
          'Reserva próxima a vencer',
          'Tu reserva vence en 10 minutos. ¿Deseas extenderla?',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'parkflow_reserva',
              'Notificaciones de Reserva',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _extendBooking(double hours) async {
    try {
      await ref.read(bookingRepositoryProvider).extendBooking(widget.booking.id, hours);
      if (mounted) {
        ref.invalidate(activeBookingProvider);
        ref.invalidate(driverBookingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extensión de $hours hora(s) solicitada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.booking.spotAddress ?? 'Ubicación desconocida',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tiempo restante:', style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  _formatDuration(_remaining),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.mustard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Extension options
            const Text('Extender reserva:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _extendBooking(0.5),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('30 min'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _extendBooking(1.0),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('1 hora'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
