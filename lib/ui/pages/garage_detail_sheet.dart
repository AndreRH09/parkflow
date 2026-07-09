import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/domain/entities/garage.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

class GarageDetailSheet extends ConsumerStatefulWidget {
  final Garage garage;

  const GarageDetailSheet({required this.garage, super.key});

  @override
  ConsumerState<GarageDetailSheet> createState() => _GarageDetailSheetState();
}

class _GarageDetailSheetState extends ConsumerState<GarageDetailSheet> {
  late TimeOfDay _startTime = TimeOfDay.now();
  double _hoursRequested = 1.0;
  late double _proposedPrice = widget.garage.basePricePerHour;
  final _platController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _platController.dispose();
    super.dispose();
  }

  double get _totalAmount => _proposedPrice * _hoursRequested;

  Future<void> _submitBid() async {
    if (_platController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa placa del vehículo')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        _startTime.hour,
        _startTime.minute,
      );

      await ref.read(bidRepositoryProvider).createBid(
            hostId: widget.garage.hostId,
            spotId: widget.garage.id,
            proposedPricePerHour: _proposedPrice,
            startTime: startTime,
            hoursRequested: _hoursRequested,
            vehiclePlate: _platController.text,
          );

      if (mounted) {
        ref.invalidate(driverBidsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puja enviada!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.brightSnow,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(16),
          children: [
            // Photo
            if (widget.garage.primaryPhotoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.garage.primaryPhotoUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, st) => Container(
                    height: 200,
                    color: AppColors.dustGray.withValues(alpha: 0.2),
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Address
            Text(
              widget.garage.address,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.graphite),
            ),
            const SizedBox(height: 8),
            // Rating
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.mustard, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${widget.garage.rating.toStringAsFixed(1)} (${widget.garage.ratingCount})',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Nombre dueño (HU-07)
            if (widget.garage.hostName != null)
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    widget.garage.hostName!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.graphite),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // Dimensiones (HU-07)
            if (widget.garage.width != null || widget.garage.height != null)
              Row(
                children: [
                  const Icon(Icons.straighten_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Dimensiones: ${widget.garage.width?.toStringAsFixed(1) ?? "?"}m x ${widget.garage.height?.toStringAsFixed(1) ?? "?"}m',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Tipos de vehículo
            if (widget.garage.vehicleTypes.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.garage.vehicleTypes
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.dustGray.withValues(alpha: 0.15),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 16),
            // Base price
            Text(
              'S/ ${widget.garage.basePricePerHour.toStringAsFixed(2)} / hora',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.mustard),
            ),
            const SizedBox(height: 24),
            // Form
            const Text('Detalles de la puja:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            // Time picker
            ListTile(
              title: const Text('Hora de inicio'),
              trailing: TextButton(
                onPressed: () async {
                  final time = await showTimePicker(context: context, initialTime: _startTime);
                  if (time != null) setState(() => _startTime = time);
                },
                child: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
              ),
            ),
            // Hours
            ListTile(
              title: const Text('Horas solicitadas'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _hoursRequested > 0.5
                        ? () => setState(() => _hoursRequested = (_hoursRequested * 2 - 1) / 2)
                        : null,
                  ),
                  Text('${_hoursRequested.toStringAsFixed(1)}h'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _hoursRequested += 0.5),
                  ),
                ],
              ),
            ),
            // Price stepper
            ListTile(
              title: const Text('Precio propuesto / hora'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _proposedPrice > widget.garage.basePricePerHour * 0.5
                        ? () => setState(() => _proposedPrice -= 1)
                        : null,
                  ),
                  Text('S/ ${_proposedPrice.toStringAsFixed(2)}'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _proposedPrice += 1),
                  ),
                ],
              ),
            ),
            // Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.dustGray.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total estimado:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    'S/ ${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.mustard),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Vehicle plate
            TextField(
              controller: _platController,
              decoration: InputDecoration(
                hintText: 'Placa del vehículo (p.e. ABC-1234)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            // Submit button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBid,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Solicitar Reserva'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
