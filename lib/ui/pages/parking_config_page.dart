import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkflow/data/services/reverse_geocode.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

// ── Vehicle type chip data ────────────────────────────────────────────────────
const _vehicleOptions = [
  ('auto', 'Auto', Icons.directions_car_rounded),
  ('moto', 'Moto', Icons.two_wheeler_rounded),
  ('camioneta', 'Camioneta', Icons.local_shipping_rounded),
  ('van', 'Van', Icons.airport_shuttle_rounded),
];

// ── Feature toggle data ───────────────────────────────────────────────────────
const _featureOptions = [
  ('covered', 'Techado'),
  ('security_camera', 'Cámara de seguridad'),
  ('lighting', 'Iluminación'),
  ('24h', 'Disponible 24h'),
];

class ParkingConfigPage extends ConsumerStatefulWidget {
  const ParkingConfigPage({super.key});

  @override
  ConsumerState<ParkingConfigPage> createState() => _ParkingConfigPageState();
}

class _ParkingConfigPageState extends ConsumerState<ParkingConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _widthCtl = TextEditingController();
  final _heightCtl = TextEditingController();

  // Photos: index 0 = primary (required), 1 and 2 = optional
  final List<Uint8List?> _photoBytes = [null, null, null];
  final List<String?> _photoExts = [null, null, null];

  final Set<String> _selectedVehicles = {};
  final Map<String, bool> _features = {
    for (final f in _featureOptions) f.$1: false,
  };

  double? _latitude;
  double? _longitude;
  bool _loading = false;
  bool _detectingLocation = false;

  @override
  void dispose() {
    _addressCtl.dispose();
    _priceCtl.dispose();
    _widthCtl.dispose();
    _heightCtl.dispose();
    super.dispose();
  }

  // ── GPS detect ─────────────────────────────────────────────────────────────

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showError('Permiso de ubicación denegado.');
        return;
      }

      // getLastKnownPosition lanza UnsupportedError en web: solo cache movil.
      Position? pos = kIsWeb ? null : await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 12));

      _latitude = pos.latitude;
      _longitude = pos.longitude;

      final place = await reverseGeocode(
        pos.latitude,
        pos.longitude,
      ).timeout(const Duration(seconds: 8));

      if (place != null && place.address.isNotEmpty) {
        _addressCtl.text = place.address;
      }
    } on TimeoutException {
      _showError('Tiempo agotado. Activa GPS y verifica conexión.');
    } on LocationServiceDisabledException {
      _showError('GPS desactivado. Actívalo e intenta de nuevo.');
    } catch (e) {
      _showError('No se pudo detectar la ubicación: $e');
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  // ── Photo picker ────────────────────────────────────────────────────────────

  Future<void> _pickPhoto(int index) async {
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
    if (bytes.length > 3145728) {
      _showError('La imagen debe pesar menos de 3 MB.');
      return;
    }

    setState(() {
      _photoBytes[index] = bytes;
      _photoExts[index] = ext == 'jpeg' ? 'jpg' : ext;
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photoBytes[index] = null;
      _photoExts[index] = null;
    });
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_photoBytes[0] == null) {
      _showError('La foto principal es obligatoria.');
      return;
    }

    if (_selectedVehicles.isEmpty) {
      _showError('Selecciona al menos un tipo de vehículo.');
      return;
    }

    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(garageRepositoryProvider);

      // Upload photos (index 1-based for storage paths)
      final urls = <String>[];
      for (int i = 0; i < 3; i++) {
        final bytes = _photoBytes[i];
        final ext = _photoExts[i];
        if (bytes != null && ext != null) {
          final url = await repo.uploadGaragePhoto(
            hostId: userId,
            index: i + 1,
            imageBytes: bytes,
            extension: ext,
          );
          urls.add(url);
        }
      }

      await repo.saveGarage(
        hostId: userId,
        address: _addressCtl.text.trim(),
        basePricePerHour: double.parse(_priceCtl.text.trim()),
        vehicleTypes: _selectedVehicles.toList(),
        features: Map<String, dynamic>.from(_features),
        width: _widthCtl.text.trim().isNotEmpty
            ? double.tryParse(_widthCtl.text.trim())
            : null,
        height: _heightCtl.text.trim().isNotEmpty
            ? double.tryParse(_heightCtl.text.trim())
            : null,
        photoUrls: urls,
        latitude: _latitude ?? 0,
        longitude: _longitude ?? 0,
      );

      ref.invalidate(authStateProvider);
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        _showError(raw.length > 120 ? raw.substring(0, 120) : raw);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.brightSnow,
        iconTheme: const IconThemeData(color: AppColors.graphite),
        title: const Text(
          'Configura tu cochera',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: AppColors.graphite,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('Fotos de tu cochera'),
                const SizedBox(height: 4),
                const Text(
                  'La foto principal es obligatoria',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPhotoRow(),
                const SizedBox(height: 24),
                _sectionLabel('Dirección'),
                const SizedBox(height: 10),
                _buildAddressField(),
                const SizedBox(height: 20),
                _sectionLabel('Precio por hora (S/)'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _priceCtl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: const TextStyle(
                      fontFamily: 'Inter', color: AppColors.graphite),
                  decoration: _inputDecoration(
                    'Ej. 5.00',
                    Icons.attach_money_rounded,
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Ingresa un precio válido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _sectionLabel('Dimensiones (opcional)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _widthCtl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        style: const TextStyle(
                            fontFamily: 'Inter', color: AppColors.graphite),
                        decoration:
                            _inputDecoration('Ancho (m)', Icons.width_normal_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _heightCtl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        style: const TextStyle(
                            fontFamily: 'Inter', color: AppColors.graphite),
                        decoration:
                            _inputDecoration('Alto (m)', Icons.height_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionLabel('Tipos de vehículo'),
                const SizedBox(height: 10),
                _buildVehicleChips(),
                const SizedBox(height: 24),
                _sectionLabel('Características'),
                const SizedBox(height: 4),
                _buildFeatureToggles(),
                const SizedBox(height: 32),
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
                      : const Text(
                          'Guardar cochera',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Photo row ───────────────────────────────────────────────────────────────

  Widget _buildPhotoRow() {
    return Row(
      children: List.generate(3, (i) {
        final bytes = _photoBytes[i];
        final isPrimary = i == 0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
            child: GestureDetector(
              onTap: _loading ? null : () => _pickPhoto(i),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.dustGray.withAlpha(60),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPrimary && bytes == null
                              ? AppColors.mustard
                              : AppColors.dustGray,
                          width: isPrimary && bytes == null ? 2 : 1,
                        ),
                        image: bytes != null
                            ? DecorationImage(
                                image: MemoryImage(bytes),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: bytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isPrimary
                                      ? Icons.add_a_photo_rounded
                                      : Icons.add_rounded,
                                  color: isPrimary
                                      ? AppColors.mustard
                                      : AppColors.textSecondary,
                                  size: isPrimary ? 28 : 22,
                                ),
                                if (isPrimary) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Principal',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mustard,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : null,
                    ),
                    if (bytes != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(i),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    if (isPrimary && bytes != null)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.mustard,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Principal',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.graphite,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Address field ───────────────────────────────────────────────────────────

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressCtl,
      style:
          const TextStyle(fontFamily: 'Inter', color: AppColors.graphite),
      decoration: InputDecoration(
        hintText: 'Dirección de la cochera',
        hintStyle: const TextStyle(
            fontFamily: 'Inter', color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.location_on_outlined,
            color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.dustGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.dustGray),
        ),
        suffixIcon: _detectingLocation
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
                onPressed: _detectLocation,
                tooltip: 'Detectar ubicación',
              ),
      ),
      validator: (v) =>
          (v?.trim().isEmpty ?? true) ? 'La dirección es requerida' : null,
    );
  }

  // ── Vehicle chips ───────────────────────────────────────────────────────────

  Widget _buildVehicleChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _vehicleOptions.map((opt) {
        final selected = _selectedVehicles.contains(opt.$1);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedVehicles.remove(opt.$1);
            } else {
              _selectedVehicles.add(opt.$1);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.graphite : AppColors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    selected ? AppColors.graphite : AppColors.dustGray,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.graphite.withAlpha(30),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  opt.$3,
                  size: 16,
                  color: selected
                      ? AppColors.mustard
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  opt.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Feature toggles ─────────────────────────────────────────────────────────

  Widget _buildFeatureToggles() {
    // Material, no Container: SwitchListTile pinta su ink en el Material más
    // cercano; un DecoratedBox intermedio con color lo taparía.
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.dustGray),
      ),
      child: Column(
        children: _featureOptions.asMap().entries.map((entry) {
          final i = entry.key;
          final opt = entry.value;
          return Column(
            children: [
              SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: Text(
                  opt.$2,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.graphite,
                  ),
                ),
                value: _features[opt.$1]!,
                activeThumbColor: AppColors.mustard,
                activeTrackColor: AppColors.mustard.withAlpha(100),
                onChanged: (v) =>
                    setState(() => _features[opt.$1] = v),
              ),
              if (i < _featureOptions.length - 1)
                const Divider(
                    height: 1, indent: 16, endIndent: 16,
                    color: AppColors.dustGray),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.graphite,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          fontFamily: 'Inter', color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.dustGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.dustGray),
      ),
    );
  }
}
