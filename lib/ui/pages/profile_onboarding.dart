import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

class ProfileOnboardingPage extends ConsumerStatefulWidget {
  const ProfileOnboardingPage({super.key});

  @override
  ConsumerState<ProfileOnboardingPage> createState() =>
      _ProfileOnboardingPageState();
}

class _ProfileOnboardingPageState extends ConsumerState<ProfileOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _ageCtl = TextEditingController();
  final _dniCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _ageCtl.dispose();
    _dniCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).saveProfile(
            userId: userId,
            fullName: _nameCtl.text.trim(),
            age: int.parse(_ageCtl.text.trim()),
            dni: _dniCtl.text.trim(),
          );
      ref.invalidate(authStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.brightSnow,
        iconTheme: IconThemeData(color: AppColors.graphite),
        title: Text('Completa tu perfil',
            style: Theme.of(context).textTheme.titleMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text('Datos básicos',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Nombre completo, edad y DNI son obligatorios',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameCtl,
                  decoration: InputDecoration(
                    hintText: 'Nombre completo',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Debe ingresar un nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageCtl,
                  decoration: InputDecoration(
                    hintText: 'Edad',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Edad invalida';
                    if (n < 18) return 'Debes ser mayor de 18 anos';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dniCtl,
                  decoration: InputDecoration(
                    hintText: 'Numero de DNI',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'DNI requerido' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mustard,
                    foregroundColor: AppColors.graphite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Guardar',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(color: AppColors.graphite)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading ? null : () => ref.invalidate(authStateProvider),
                  child: Text('Omitir por ahora',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
