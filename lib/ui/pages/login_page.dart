import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/ui/theme/app_theme.dart';
import 'package:parkflow/dependency_injection/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Login
  final _loginEmailCtl = TextEditingController();
  final _loginPasswordCtl = TextEditingController();
  bool _remember = true;
  bool _obscureLogin = true;

  // Registro
  final _regEmailCtl = TextEditingController();
  final _regPasswordCtl = TextEditingController();
  final _regConfirmCtl = TextEditingController();
  bool _obscureReg = true;
  bool _obscureConfirm = true;

  bool _loadingGoogle = false;
  bool _loadingEmail = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtl.dispose();
    _loginPasswordCtl.dispose();
    _regEmailCtl.dispose();
    _regPasswordCtl.dispose();
    _regConfirmCtl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _onGoogleSignIn() async {
    setState(() => _loadingGoogle = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) _showError('Error al iniciar sesión con Google: $e');
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _onLogin() async {
    final email = _loginEmailCtl.text.trim();
    final password = _loginPasswordCtl.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Completa todos los campos');
      return;
    }
    setState(() => _loadingEmail = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _onRegister() async {
    final email = _regEmailCtl.text.trim();
    final password = _regPasswordCtl.text;
    final confirm = _regConfirmCtl.text;
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError('Completa todos los campos');
      return;
    }
    if (password != confirm) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    if (password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    setState(() => _loadingEmail = true);
    try {
      await ref.read(authRepositoryProvider).registerWithEmail(email, password);
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Image.asset(
                'lib/ui/assets/BannerParkFlow.png',
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Ingresar'),
                  Tab(text: 'Registrarse'),
                ],
                indicatorColor: AppColors.accent,
                indicatorWeight: 3,
                labelColor: AppColors.graphite,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400, fontSize: 15),
                dividerColor: AppColors.dustGray,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_loginTab(), _registerTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleButton() => ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.graphite,
          elevation: 0,
          side: const BorderSide(color: AppColors.dustGray),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: _loadingGoogle
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Image.asset('lib/ui/assets/OficialLogo.jpg',
                width: 20, height: 20),
        label: Text(
          'Continuar con Google',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w600, color: AppColors.graphite),
        ),
        onPressed: _loadingGoogle ? null : _onGoogleSignIn,
      );

  Widget _orDivider() => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.dustGray)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('o'),
          ),
          const Expanded(child: Divider(color: AppColors.dustGray)),
        ],
      );

  Widget _loginTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _googleButton(),
            const SizedBox(height: 16),
            _orDivider(),
            const SizedBox(height: 16),
            TextField(
              controller: _loginEmailCtl,
              decoration:
                  const InputDecoration(hintText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loginPasswordCtl,
              obscureText: _obscureLogin,
              decoration: InputDecoration(
                hintText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(_obscureLogin
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureLogin = !_obscureLogin),
                ),
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? true),
                ),
                Text('Recordarme',
                    style: Theme.of(context).textTheme.bodyLarge),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Olvidé mi contraseña',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadingEmail ? null : _onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loadingEmail
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Iniciar sesión',
                      style: Theme.of(context).textTheme.labelLarge),
            ),
          ],
        ),
      );

  Widget _registerTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _googleButton(),
            const SizedBox(height: 16),
            _orDivider(),
            const SizedBox(height: 16),
            TextField(
              controller: _regEmailCtl,
              decoration:
                  const InputDecoration(hintText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _regPasswordCtl,
              obscureText: _obscureReg,
              decoration: InputDecoration(
                hintText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureReg ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureReg = !_obscureReg),
                ),
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _regConfirmCtl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Confirmar contraseña',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadingEmail ? null : _onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loadingEmail
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Crear cuenta',
                      style: Theme.of(context).textTheme.labelLarge),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Al registrarte aceptas los Términos de Servicio',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}
