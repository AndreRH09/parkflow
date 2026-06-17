import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

const _vehicleOptions = [
  ('auto', 'Auto', Icons.directions_car_rounded),
  ('moto', 'Moto', Icons.two_wheeler_rounded),
  ('camioneta', 'Camioneta', Icons.local_shipping_rounded),
  ('van', 'Van', Icons.airport_shuttle_rounded),
];

class DriverOnboardingPage extends ConsumerStatefulWidget {
  const DriverOnboardingPage({super.key});

  @override
  ConsumerState<DriverOnboardingPage> createState() => _DriverOnboardingPageState();
}

class _DriverOnboardingPageState extends ConsumerState<DriverOnboardingPage> {
  String? _selectedVehicle;
  final _plateCtl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _plateCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedVehicle == null || _plateCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa ambos campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('No autenticado');

      await ref.read(profileRepositoryProvider).updateProfile(
            userId: user.id,
            vehicleType: _selectedVehicle,
            vehiclePlate: _plateCtl.text.toUpperCase(),
          );

      if (mounted) {
        ref.invalidate(authStateProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Listo! Bienvenido a ParkFlow')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Tu vehículo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.graphite,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuéntanos qué tipo de vehículo tienes para poder recomendarte cocheras compatibles.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 32),
              // Vehicle type selection
              const Text(
                'Tipo de vehículo',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _vehicleOptions.map((option) {
                  final (key, label, icon) = option;
                  final isSelected = _selectedVehicle == key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedVehicle = key),
                    child: Card(
                      color: isSelected ? AppColors.mustard : AppColors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              color: isSelected ? AppColors.white : AppColors.dustGray,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isSelected ? AppColors.white : AppColors.graphite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // License plate input
              const Text(
                'Placa del vehículo',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _plateCtl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'ABC-1234',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.directions_car_rounded),
                ),
                maxLength: 10,
              ),
              const SizedBox(height: 32),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
