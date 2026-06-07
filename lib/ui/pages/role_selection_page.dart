import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/ui/theme/app_theme.dart';
import 'package:parkflow/dependency_injection/providers.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  String? _selectedRole;
  bool _loading = false;

  Future<void> _onContinue() async {
    if (_selectedRole == null) return;
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('No active session');

      await Supabase.instance.client
          .from('profiles')
          .update({'role': _selectedRole})
          .eq('id', userId);

      // authStateProvider will re-emit and main.dart router will navigate
      ref.invalidate(authStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    '¿Cómo quieres usar ParkFlow?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes cambiar tu rol más adelante desde tu perfil.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),
                  _RoleCard(
                    title: 'Quiero Estacionar',
                    subtitle: 'Busca cocheras privadas cerca de ti y reserva al instante.',
                    icon: Icons.directions_car_rounded,
                    role: 'driver',
                    selected: _selectedRole == 'driver',
                    onTap: () => setState(() => _selectedRole = 'driver'),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    title: 'Quiero Alquilar mi Cochera',
                    subtitle: 'Publica tu espacio y genera ingresos con conductores verificados.',
                    icon: Icons.garage_rounded,
                    role: 'host',
                    selected: _selectedRole == 'host',
                    onTap: () => setState(() => _selectedRole = 'host'),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed:
                        (_selectedRole != null && !_loading) ? _onContinue : null,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Continuar',
                            style: Theme.of(context).textTheme.labelLarge),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withAlpha(31) : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.dustGray,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withAlpha(15),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.brightSnow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon,
                  size: 28,
                  color: selected ? AppColors.graphite : AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.graphite, size: 22),
          ],
        ),
      ),
    );
  }
}
