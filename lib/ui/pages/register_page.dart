import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/ui/theme/app_theme.dart';
import 'package:parkflow/dependency_injection/providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final VoidCallback? onLoginTap;

  const RegisterPage({super.key, this.onLoginTap});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _loadingGoogle = false;
  bool _loadingEmail = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket') || msg.contains('host lookup')) {
      return 'No se pudo conectar a Supabase. Proyecto pausado o sin red.\n${e.toString().substring(0, e.toString().length.clamp(0, 120))}';
    }
    if (msg.contains('email already') || msg.contains('already registered') || msg.contains('already exists')) {
      return 'Este correo ya está registrado.';
    }
    if (msg.contains('invalid') || msg.contains('malformed')) {
      return 'Correo o contraseña inválidos.';
    }
    return 'Error: ${e.toString().substring(0, e.toString().length.clamp(0, 200))}';
  }

  Future<void> _onGoogleSignUp() async {
    if (_loadingGoogle) return;
    setState(() => _loadingGoogle = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) _showError(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _onRegister() async {
    if (_loadingEmail) return;
    final email = _emailCtl.text.trim();
    final password = _passwordCtl.text;
    final confirm = _confirmCtl.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError('Completa todos los campos');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showError('Ingresa un correo válido');
      return;
    }
    if (password != confirm) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    if (password.length < 8) {
      _showError('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    setState(() => _loadingEmail = true);
    try {
      await ref.read(authRepositoryProvider).registerWithEmail(email, password);
    } catch (e) {
      if (mounted) _showError(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildMainContent(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    const SizedBox(height: 48),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
        children: [
          Image.asset(
            'lib/ui/assets/BannerParkFlow.png',
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            'ParkFlow',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.graphite,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Park & Pay',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
          ),
        ],
      );

  Widget _buildMainContent() => Column(
        children: [
          Text(
            'Crear cuenta',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.graphite,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Regístrate para comenzar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      );

  Widget _buildForm() => Column(
        spacing: 16,
        children: [
          _googleButton(),
          _orDivider(),
          TextField(
            controller: _emailCtl,
            decoration: InputDecoration(
              hintText: 'Correo electrónico',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.dustGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.dustGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 1.5,
                ),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          TextField(
            controller: _passwordCtl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Contraseña',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.dustGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.dustGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 1.5,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          TextField(
            controller: _confirmCtl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Confirmar contraseña',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.dustGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.dustGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 1.5,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loadingEmail ? null : _onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _loadingEmail
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.graphite,
                        ),
                      ),
                    )
                  : Text(
                      'Crear cuenta',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
            ),
          ),
          Center(
            child: Text(
              'Al registrarte aceptas los Términos de Servicio',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      );

  Widget _googleButton() => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.graphite,
            elevation: 0,
            side: const BorderSide(color: AppColors.dustGray),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          icon: _loadingGoogle
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.graphite,
                    ),
                  ),
                )
              : Image.asset(
                  'lib/ui/assets/Google.png',
                  width: 20,
                  height: 20,
                ),
          label: Text(
            'Continuar con Google',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          onPressed: _loadingGoogle ? null : _onGoogleSignUp,
        ),
      );

  Widget _orDivider() => Row(
        children: [
          const Expanded(
            child: Divider(
              color: AppColors.dustGray,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'o',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const Expanded(
            child: Divider(
              color: AppColors.dustGray,
              height: 1,
            ),
          ),
        ],
      );

  Widget _buildFooter() => Column(
        children: [
          Text(
            '¿Ya tienes cuenta?',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.graphite,
                ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              _emailCtl.clear();
              _passwordCtl.clear();
              _confirmCtl.clear();
              widget.onLoginTap?.call();
            },
            child: Text(
              'Inicia sesión',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ],
      );
}
