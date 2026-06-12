import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/domain/entities/garage.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

/// HU-11 — Configura disponibilidad de una cochera: switch maestro,
/// rango horario y días de la semana.
class AvailabilityPage extends ConsumerStatefulWidget {
  final Garage garage;
  const AvailabilityPage({super.key, required this.garage});

  @override
  ConsumerState<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends ConsumerState<AvailabilityPage> {
  static const _dayLabels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

  late bool _isActive;
  TimeOfDay _start = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 22, minute: 0);
  late Set<int> _days; // 1=Lun .. 7=Dom
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.garage;
    _isActive = g.isActive;
    _start = _parseTime(g.availabilityStart) ?? _start;
    _end = _parseTime(g.availabilityEnd) ?? _end;
    _days = g.availableDays.isNotEmpty
        ? g.availableDays.toSet()
        : {1, 2, 3, 4, 5, 6, 7};
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_days.isEmpty) {
      _snack('Selecciona al menos un día');
      return;
    }
    setState(() => _saving = true);
    try {
      final sortedDays = _days.toList()..sort();
      await ref.read(garageRepositoryProvider).updateAvailability(
            spotId: widget.garage.id,
            isActive: _isActive,
            start: _fmt(_start),
            end: _fmt(_end),
            days: sortedDays,
          );
      ref.invalidate(myGaragesProvider);
      if (!mounted) return;
      _snack('Disponibilidad guardada');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _snack('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      appBar: AppBar(
        title: const Text('Disponibilidad',
            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            widget.garage.address,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),

          // Master switch
          _Card(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cochera activa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.graphite,
                            fontFamily: 'Inter',
                          )),
                      SizedBox(height: 2),
                      Text('Visible para conductores',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          )),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  activeThumbColor: AppColors.graphite,
                  activeTrackColor: AppColors.mustard,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Time range
          _SectionTitle('Horario'),
          const SizedBox(height: 8),
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Desde',
                    value: _fmt(_start),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(
                    label: 'Hasta',
                    value: _fmt(_end),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Days
          _SectionTitle('Días disponibles'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              final active = _days.contains(day);
              return GestureDetector(
                onTap: () => setState(() {
                  if (active) {
                    _days.remove(day);
                  } else {
                    _days.add(day);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AppColors.graphite : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? AppColors.graphite : AppColors.dustGray,
                    ),
                  ),
                  child: Text(
                    _dayLabels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.mustard : AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.graphite,
              foregroundColor: AppColors.mustard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.mustard),
                  )
                : const Text('Guardar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      fontSize: 15,
                    )),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.graphite,
        fontFamily: 'Inter',
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              )),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brightSnow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dustGray),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.graphite,
                      fontFamily: 'Inter',
                    )),
                const Icon(Icons.access_time_rounded,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
