import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/domain/entities/bid.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

/// HU-12 — Solicitudes (pujas) entrantes para el anfitrión. Aceptar / rechazar.
/// Sirve como página completa o embebida en la pestaña "Reservas" del Home.
class RequestsPage extends ConsumerStatefulWidget {
  /// Si true, oculta el AppBar (para usar dentro de un IndexedStack/tab).
  final bool embedded;
  const RequestsPage({super.key, this.embedded = false});

  @override
  ConsumerState<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends ConsumerState<RequestsPage> {
  String? _busyBidId;

  Future<void> _act(Bid bid, {required bool accept}) async {
    setState(() => _busyBidId = bid.id);
    try {
      final repo = ref.read(bidRepositoryProvider);
      if (accept) {
        await repo.acceptBid(bid.id);
      } else {
        await repo.rejectBid(bid.id);
      }
      ref.invalidate(incomingBidsProvider);
      if (accept) ref.invalidate(hostBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Puja aceptada' : 'Puja rechazada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busyBidId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bidsAsync = ref.watch(incomingBidsProvider);

    final body = RefreshIndicator(
      onRefresh: () async => ref.invalidate(incomingBidsProvider),
      child: bidsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text('Error al cargar solicitudes\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontFamily: 'Inter')),
            ),
          ],
        ),
        data: (bids) {
          if (bids.isEmpty) return _empty();
          final pending = bids.where((b) => b.isPending && !b.isExpired).toList();
          final history = bids.where((b) => !(b.isPending && !b.isExpired)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionLabel('Pendientes', pending.length),
                const SizedBox(height: 12),
                ...pending.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _BidCard(
                        bid: b,
                        busy: _busyBidId == b.id,
                        onAccept: () => _act(b, accept: true),
                        onReject: () => _act(b, accept: false),
                      ),
                    )),
              ],
              if (history.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionLabel('Historial', history.length),
                const SizedBox(height: 12),
                ...history.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _BidCard(bid: b, busy: false),
                    )),
              ],
            ],
          );
        },
      ),
    );

    if (widget.embedded) {
      return SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Solicitudes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.graphite,
                    fontFamily: 'Inter',
                  )),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      appBar: AppBar(
        title: const Text('Solicitudes',
            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter')),
      ),
      body: body,
    );
  }

  Widget _sectionLabel(String text, int count) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.graphite,
              fontFamily: 'Inter',
            )),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.mustard,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.graphite,
                fontFamily: 'Inter',
              )),
        ),
      ],
    );
  }

  Widget _empty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.inbox_rounded, size: 56, color: AppColors.dustGray),
        const SizedBox(height: 12),
        const Center(
          child: Text('No hay solicitudes',
              style: TextStyle(
                color: AppColors.graphite,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                fontFamily: 'Inter',
              )),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text('Las pujas de conductores aparecerán aquí',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Inter')),
        ),
      ],
    );
  }
}

class _BidCard extends StatelessWidget {
  final Bid bid;
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  const _BidCard({
    required this.bid,
    required this.busy,
    this.onAccept,
    this.onReject,
  });

  String _fmtDateTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final actionable = onAccept != null && onReject != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.dustGray,
                backgroundImage: bid.driverAvatarUrl != null
                    ? NetworkImage(bid.driverAvatarUrl!)
                    : null,
                child: bid.driverAvatarUrl == null
                    ? const Icon(Icons.person_rounded,
                        color: AppColors.graphite, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bid.driverName ?? 'Conductor',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.graphite,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bid.driverRating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(bid.driverRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              )),
                        ],
                      ),
                  ],
                ),
              ),
              if (!actionable) _StatusChip(status: bid.status),
            ],
          ),
          const SizedBox(height: 14),
          if (bid.spotAddress != null) ...[
            _row(Icons.location_on_outlined, bid.spotAddress!),
            const SizedBox(height: 6),
          ],
          _row(Icons.schedule_rounded,
              '${_fmtDateTime(bid.startTime)} · ${bid.hoursRequested.toStringAsFixed(bid.hoursRequested % 1 == 0 ? 0 : 1)} h'),
          if (bid.vehiclePlate != null) ...[
            const SizedBox(height: 6),
            _row(Icons.directions_car_rounded, bid.vehiclePlate!),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brightSnow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Oferta',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        )),
                    Text(
                      'S/ ${bid.proposedPricePerHour.toStringAsFixed(2)}/hr',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.graphite,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        )),
                    Text(
                      'S/ ${bid.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.graphite,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (actionable) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.graphite,
                      side: const BorderSide(color: AppColors.dustGray),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Rechazar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.graphite,
                      foregroundColor: AppColors.mustard,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.mustard),
                          )
                        : const Text('Aceptar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            )),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.graphite,
                fontFamily: 'Inter',
              )),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (status) {
      case 'accepted':
        color = Colors.green;
        label = 'Aceptada';
        break;
      case 'rejected':
        color = Colors.redAccent;
        label = 'Rechazada';
        break;
      case 'expired':
        color = AppColors.textSecondary;
        label = 'Expirada';
        break;
      case 'countered':
        color = Colors.orange;
        label = 'Contraoferta';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Inter',
          )),
    );
  }
}
