import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parkflow/data/services/reverse_geocode.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  final _emailCtl = TextEditingController();

  Uint8List? _pendingAvatar;
  String? _pendingAvatarExt;
  bool _loading = false;
  bool _detectingCity = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      _nameCtl.text = user.fullName ?? '';
      _phoneCtl.text = user.phone ?? '';
      _cityCtl.text = user.city ?? '';
      _emailCtl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _cityCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null) return;

    // xFile.path en web es un blob: sin extensión. name sí trae el archivo original.
    final ext = xFile.name.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      _showError('Solo se permiten imágenes JPG o PNG.');
      return;
    }

    final bytes = await xFile.readAsBytes();
    if (bytes.length > 307200) {
      _showError('La imagen debe pesar menos de 0.3 MB.');
      return;
    }

    setState(() {
      _pendingAvatar = bytes;
      _pendingAvatarExt = ext == 'jpeg' ? 'jpg' : ext;
    });
  }

  Future<void> _detectCity() async {
    setState(() => _detectingCity = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError('Permiso de ubicación denegado.');
        return;
      }

      // getLastKnownPosition lanza UnsupportedError en web: solo cache movil.
      Position? pos = kIsWeb ? null : await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 10));

      final place = await reverseGeocode(
        pos.latitude,
        pos.longitude,
      ).timeout(const Duration(seconds: 8));

      if (place != null && place.city.isNotEmpty) {
        _cityCtl.text = place.city;
      } else {
        _showError('Ciudad no detectada. Escríbela manualmente.');
      }
    } on TimeoutException {
      _showError('Tiempo agotado. Activa GPS y verifica conexión.');
    } on LocationServiceDisabledException {
      _showError('GPS desactivado. Actívalo e intenta de nuevo.');
    } catch (e) {
      _showError('No se pudo detectar la ciudad ($e). Escríbela manualmente.');
    } finally {
      if (mounted) setState(() => _detectingCity = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      String? newAvatarUrl;
      if (_pendingAvatar != null && _pendingAvatarExt != null) {
        try {
          newAvatarUrl = await ref.read(profileRepositoryProvider).uploadAvatar(
                userId: userId,
                imageBytes: _pendingAvatar!,
                extension: _pendingAvatarExt!,
              );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'No se pudo subir la foto. Los demás datos se guardarán.'),
                backgroundColor: Colors.orange.shade700,
              ),
            );
          }
        }
      }

      await ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            fullName: _nameCtl.text.trim(),
            phone: _phoneCtl.text.trim(),
            city: _cityCtl.text.trim(),
            avatarUrl: newAvatarUrl,
          );

      ref.invalidate(authStateProvider);
      setState(() => _isEditMode = false);
      _pendingAvatar = null;
      _pendingAvatarExt = null;
    } catch (_) {
      _showError('No se pudo guardar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cuenta',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: const Text(
            '¿Eliminar tu cuenta de forma permanente? No se puede deshacer.',
            style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.graphite)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(fontFamily: 'Inter', color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      ref.invalidate(authStateProvider);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _showError('Error al eliminar: ${e.toString().substring(0, 200)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  void _cancelEdit() {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      _nameCtl.text = user.fullName ?? '';
      _phoneCtl.text = user.phone ?? '';
      _cityCtl.text = user.city ?? '';
    }
    _pendingAvatar = null;
    _pendingAvatarExt = null;
    setState(() => _isEditMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarUrl = ref.watch(authStateProvider).value?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: AppColors.graphite,
          ),
        ),
        backgroundColor: AppColors.brightSnow,
        elevation: 0,
        foregroundColor: AppColors.graphite,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteAccount();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Eliminar cuenta',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAvatar(currentAvatarUrl),
                const SizedBox(height: 32),
                _buildField(
                  controller: _nameCtl,
                  hint: 'Nombre completo',
                  icon: Icons.person_outline_rounded,
                  maxLength: 20,
                  enabled: _isEditMode,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nombre requerido';
                    if (v.trim().length > 20) return 'Máximo 20 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _phoneCtl,
                  hint: 'Celular (9 dígitos)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 9,
                  enabled: _isEditMode,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Teléfono requerido';
                    if (v.trim().length != 9) return 'Debe tener exactamente 9 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildCityField(),
                if (_isEditMode) ...[
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _emailCtl,
                    hint: 'Correo',
                    icon: Icons.email_outlined,
                    enabled: false,
                    validator: null,
                  ),
                ],
                const SizedBox(height: 36),
                if (!_isEditMode)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => setState(() => _isEditMode = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mustard,
                        foregroundColor: AppColors.graphite,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Editar perfil',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: AppColors.graphite,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : _cancelEdit,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.dustGray),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              color: AppColors.graphite,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mustard,
                            foregroundColor: AppColors.graphite,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Guardar',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.graphite,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () async {
                      final buildContext = context;
                      final confirmed = await showDialog<bool>(
                        context: buildContext,
                        builder: (_) => AlertDialog(
                          title: const Text('Cerrar sesión',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700)),
                          content: const Text('¿Estás seguro?',
                              style: TextStyle(fontFamily: 'Inter')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: AppColors.graphite)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Salir',
                                  style: TextStyle(
                                      fontFamily: 'Inter', color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !mounted) return;
                      await ref.read(authRepositoryProvider).signOut();
                      ref.invalidate(authStateProvider);
                      if (mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? currentAvatarUrl) {
    ImageProvider? imageProvider;
    if (_pendingAvatar != null) {
      imageProvider = MemoryImage(_pendingAvatar!);
    } else if (currentAvatarUrl != null) {
      imageProvider = NetworkImage(currentAvatarUrl);
    }

    return GestureDetector(
      onTap: _isEditMode ? _pickImage : null,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: AppColors.dustGray,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person_rounded,
                    size: 56, color: AppColors.graphite)
                : null,
          ),
          if (_isEditMode)
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.mustard,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 18, color: AppColors.graphite),
            ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(fontFamily: 'Inter', color: AppColors.graphite),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontFamily: 'Inter', color: AppColors.textSecondary),
        prefixIcon: Icon(icon,
            color: enabled ? AppColors.textSecondary : AppColors.dustGray),
        filled: true,
        fillColor: enabled ? AppColors.white : AppColors.dustGray.withAlpha(30),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.dustGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.dustGray),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.dustGray),
        ),
      ),
    );
  }

  Widget _buildCityField() {
    return TextFormField(
      controller: _cityCtl,
      enabled: _isEditMode,
      style: const TextStyle(fontFamily: 'Inter', color: AppColors.graphite),
      decoration: InputDecoration(
        hintText: 'Ciudad',
        hintStyle: const TextStyle(
            fontFamily: 'Inter', color: AppColors.textSecondary),
        prefixIcon: Icon(Icons.location_city_outlined,
            color:
                _isEditMode ? AppColors.textSecondary : AppColors.dustGray),
        filled: true,
        fillColor: _isEditMode
            ? AppColors.white
            : AppColors.dustGray.withAlpha(30),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.dustGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.dustGray),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.dustGray),
        ),
        suffixIcon: _isEditMode
            ? (_detectingCity
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location_rounded,
                        color: AppColors.graphite),
                    onPressed: _detectCity,
                    tooltip: 'Detectar ciudad',
                  ))
            : null,
      ),
    );
  }
}
