import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/core/theme/garden_colors.dart';
import 'package:gossip_garden/core/theme/garden_icons.dart';
import 'package:gossip_garden/core/widgets/garden_icon.dart';
import 'package:gossip_garden/features/plants/presentation/providers/sensor_setup_providers.dart';
import 'package:gossip_garden/features/plants/presentation/providers/achievement_providers.dart';
import 'package:gossip_garden/features/plants/data/datasources/esp32_api_client.dart';
enum WifiPhase {
  instruction,
  verifying,
  scanning,
  form,
  connecting,
  connected,
  error
}

final wifiPhaseProvider = StateProvider<WifiPhase>((ref) => WifiPhase.instruction);
final wifiSsidProvider = StateProvider<String>((ref) => '');
final wifiPasswordProvider = StateProvider<String>((ref) => '');
final wifiScanningProvider = StateProvider<bool>((ref) => false);
final wifiErrorProvider = StateProvider<String?>((ref) => null);
final wifiNetworksProvider = StateProvider<List<WifiNetworkOption>>((ref) => []);
final sensorNetworksProvider = StateProvider<List<String>>((ref) => []);

class SensorSetupView extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  
  const SensorSetupView({super.key, required this.onComplete, required this.onCancel});

  @override
  ConsumerState<SensorSetupView> createState() => _SensorSetupViewState();
}

class _SensorSetupViewState extends ConsumerState<SensorSetupView> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _showPasswordField = false;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GardenColors.dustLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: GardenColors.ink.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _primaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: GardenColors.leafDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(wifiPhaseProvider);
    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GardenColors.inkSoft),
          onPressed: widget.onCancel,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: switch (phase) {
            WifiPhase.instruction => _buildWifiInstruction(),
            WifiPhase.verifying => _buildWifiVerifying(),
            WifiPhase.scanning => _buildWifiScanning(),
            WifiPhase.form => _buildWifiForm(),
            WifiPhase.connecting => _buildWifiConnecting(),
            WifiPhase.connected => _buildWifiConnected(),
            WifiPhase.error => _buildWifiError(),
          },
        ),
      ),
    );
  }

  void _startWifiConnection() async {
      final ssid = _ssidController.text.trim();
      final password = _passwordController.text;
      if (ssid.isEmpty) return;
  
      ref.read(wifiErrorProvider.notifier).state = null;
      ref.read(wifiSsidProvider.notifier).state = ssid;
      ref.read(wifiPasswordProvider.notifier).state = password;
      ref.read(wifiPhaseProvider.notifier).state = WifiPhase.connecting;
  
      try {
        final client = ref.read(esp32ApiClientProvider);
        final success = await client.connectWifi(ssid, password);
        
        if (!mounted) return;
  
        if (success) {
          // TODO: [SENSOR-LINK] Aquí debemos llamar al backend (POST /plants/{plant_id}/link-sensor)
          // enviando el `mac_address` que tenemos guardado en `sensorMacAddressProvider`
          // para registrar el sensor en la tabla `sensors` de Supabase.
          ref.read(wifiPhaseProvider.notifier).state = WifiPhase.connected;
          ref.read(achievementStatsProvider.notifier).recordSensorSetup();
        } else {
          ref.read(wifiErrorProvider.notifier).state = 'Contraseña incorrecta o red fuera de alcance.';
          ref.read(wifiPhaseProvider.notifier).state = WifiPhase.error;
        }
      } catch (e) {
        if (!mounted) return;
        ref.read(wifiErrorProvider.notifier).state = e.toString().replaceAll('Exception: ', '');
        ref.read(wifiPhaseProvider.notifier).state = WifiPhase.error;
      }
    }

  void _showWifiForm() {
      ref.read(wifiPhaseProvider.notifier).state = WifiPhase.form;
    }

  void _startPairing() {
      ref.read(wifiPhaseProvider.notifier).state = WifiPhase.instruction;
      ref.read(wifiNetworksProvider.notifier).state = [];
      ref.read(wifiScanningProvider.notifier).state = false;
      ref.read(wifiErrorProvider.notifier).state = null;
      ref.read(wifiSsidProvider.notifier).state = '';
      ref.read(wifiPasswordProvider.notifier).state = '';
      _ssidController.clear();
      _passwordController.clear();
      setState(() {
        _passwordVisible = false;
        _showPasswordField = false;
      });
    }

  void _verifyAndStartScanning() async {
      if (!mounted) return;
      
      // Entramos en modo carga real
      ref.read(wifiPhaseProvider.notifier).state = WifiPhase.verifying;
      ref.read(wifiErrorProvider.notifier).state = null;
      
      try {
        final client = ref.read(esp32ApiClientProvider);
        final networks = await client.getWifiNetworks();
        final macAddress = await client.getSystemInfo();
        
        if (!mounted) return;
        
        // Guardamos las redes pre-cargadas y la MAC
        ref.read(wifiNetworksProvider.notifier).state = networks;
        ref.read(sensorMacAddressProvider.notifier).state = macAddress;
        
        // Ahora SÍ avanzamos a la pantalla de éxito (Chip en línea)
        ref.read(wifiPhaseProvider.notifier).state = WifiPhase.scanning;
      } catch (e) {
        if (!mounted) return;
        ref.read(wifiErrorProvider.notifier).state = e.toString().replaceAll('Exception: ', '');
        ref.read(wifiPhaseProvider.notifier).state = WifiPhase.error;
      }
    }

  void _scanNetworks() async {
      ref.read(wifiErrorProvider.notifier).state = null;
      ref.read(wifiScanningProvider.notifier).state = true;
      
      try {
        final client = ref.read(esp32ApiClientProvider);
        final networks = await client.getWifiNetworks();
        
        if (!mounted) return;
        ref.read(wifiNetworksProvider.notifier).state = networks;
        // Si todo va bien en el refresh manual, nos mantenemos en la vista del form.
      } catch (e) {
        if (!mounted) return;
        ref.read(wifiErrorProvider.notifier).state = e.toString().replaceAll('Exception: ', '');
        ref.read(wifiPhaseProvider.notifier).state = WifiPhase.error;
      } finally {
        if (mounted) {
          ref.read(wifiScanningProvider.notifier).state = false;
        }
      }
    }

  void _selectNetwork(WifiNetworkOption net) {
      _ssidController.text = net.ssid;
      _passwordController.clear();
      _passwordVisible = false;
  
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  decoration: const BoxDecoration(
                    color: GardenColors.creamPaper,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        net.ssid.isEmpty ? 'Conectar a red oculta' : 'Conectar a ${net.ssid}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: GardenColors.ink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (net.ssid.isEmpty) ...[
                        _wifiTextField(
                          controller: _ssidController,
                          label: 'Nombre de la red (SSID)',
                          hint: 'Escribe el nombre de la red',
                          iconAsset: GardenIcons.wifi,
                          obscure: false,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _wifiTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        hint: '••••••••',
                        iconAsset: GardenIcons.lock,
                        obscure: !_passwordVisible,
                        suffixIcon: IconButton(
                          icon: GardenIcon(
                            asset: _passwordVisible
                                ? GardenIcons.eyeClose
                                : GardenIcons.eyeOpen,
                            size: 20,
                            opacity: 0.6,
                          ),
                          onPressed: () => setModalState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: _primaryButton(
                          'Conectar al sensor',
                          () {
                            Navigator.pop(context);
                            _startWifiConnection();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }

  Widget _buildWifiForm() {
      final networks = ref.watch(wifiNetworksProvider);
      final scanning = ref.watch(wifiScanningProvider);
  
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GardenColors.leafDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const GardenIcon(
                      asset: GardenIcons.logroSensores, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Conecta tus sensores',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: GardenColors.ink)),
                      Text('Elige tu red WiFi para configurar el dispositivo IoT',
                          style: TextStyle(
                              fontSize: 12, color: GardenColors.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
  
            // ── Sección redes disponibles ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Redes disponibles',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: GardenColors.inkSoft,
                        letterSpacing: 0.5)),
                TextButton.icon(
                  onPressed: scanning ? null : _scanNetworks,
                  icon: scanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  GardenColors.leafDark)),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(scanning ? 'Buscando...' : 'Buscar'),
                  style: TextButton.styleFrom(
                      foregroundColor: GardenColors.leafDark,
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
  
            // Lista de redes
            if (networks.isEmpty && !scanning)
              GestureDetector(
                onTap: _scanNetworks,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: GardenColors.dustLight, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: GardenColors.ink.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GardenIcon(
                          asset: GardenIcons.wifiConnect,
                          size: 40,
                          opacity: 0.6),
                      const SizedBox(height: 10),
                      Text('Toca para buscar redes',
                          style: TextStyle(
                              color: GardenColors.inkSoft, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else if (scanning)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: GardenColors.leafDark.withValues(alpha: 0.3), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: GardenColors.ink.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(GardenColors.leafDark)),
                    const SizedBox(height: 14),
                    Text('Buscando redes cercanas...',
                        style:
                            TextStyle(color: GardenColors.inkSoft, fontSize: 13)),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GardenColors.dustLight, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: GardenColors.ink.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  children: networks.asMap().entries.map((e) {
                    final i = e.key;
                    final net = e.value;
                    final isLast = i == networks.length - 1;
                    final isSelected = _ssidController.text == net.ssid;
                    return _buildNetworkTile(net, isLast, isSelected);
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: scanning
                  ? null
                  : () {
                      _selectNetwork(const WifiNetworkOption(
                          ssid: 'Ingresar red oculta',
                          signal: 0,
                          secured: true));
                    },
              icon: const GardenIcon(asset: GardenIcons.addPlant, size: 18),
              label: const Text('Conectarse a red oculta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GardenColors.leafDark,
                side: const BorderSide(color: GardenColors.leafDark),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
  }

  Widget _wifiTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String iconAsset,
    required bool obscure,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: GardenIcon(asset: iconAsset, size: 20),
        ),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: GardenColors.leafDark),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: GardenColors.dustLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: GardenColors.dustLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GardenColors.leafDark, width: 2),
        ),
      ),
    );
  }

  Widget _buildNetworkTile(WifiNetworkOption net, bool isLast, bool isSelected) {
      final signalIcon = [
        Icons.network_wifi_1_bar,
        Icons.network_wifi_2_bar,
        Icons.network_wifi_3_bar,
        Icons.signal_wifi_4_bar,
      ][net.signal.clamp(1, 4) - 1];
  
      final signalColor =
          net.signal >= 3 ? GardenColors.leafDark : GardenColors.potOrange;
  
      return GestureDetector(
        onTap: () => _selectNetwork(net),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? GardenColors.leafDark.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isSelected ? 18 : 0),
              bottom: Radius.circular(isSelected ? 18 : 0),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Icon(signalIcon, color: signalColor, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(net.ssid,
                              style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14)),
                          Text(
                            net.secured ? 'Protegida' : 'Abierta',
                            style: TextStyle(
                                fontSize: 11,
                                color: net.secured
                                    ? GardenColors.inkSoft
                                    : GardenColors.potOrange),
                          ),
                        ],
                      ),
                    ),
                    if (net.secured)
                      Icon(Icons.lock_rounded,
                          size: 16, color: GardenColors.inkSoft),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.check_circle_rounded,
                            size: 20, color: GardenColors.leafDark),
                      ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 52, color: GardenColors.dustLight),
            ],
          ),
        ),
      );
    }

  Widget _buildWifiInstruction() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GardenIcon(asset: GardenIcons.wifiConnect, size: 64),
          const SizedBox(height: 24),
          const Text(
            'Configuración del chip',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _card(
            child: const Column(
              children: [
                Text(
                  'Conectate a la red wifi del sensor en los ajustes del dispositivo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  'gossip_garden',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GardenColors.leafDark,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _primaryButton('Verificar conexión', _verifyAndStartScanning),
        ],
      );
    }

  Widget _buildWifiVerifying() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: GardenColors.leafDark),
            const SizedBox(height: 32),
            const Text(
              'Sincronizando con el chip...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Estamos recibiendo informacion, espere un momento'),
          ],
        ),
      );
    }

  Widget _buildWifiScanning() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GardenColors.leafDark.withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.wifi_find_rounded,
                  size: 64, color: GardenColors.leafDark),
            ),
            const SizedBox(height: 32),
            const Text(
              'Chip en linea',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: GardenColors.leafDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Conecta tu dispositivo a redes wifi disponibles en tu entorno para continuar',
              textAlign: TextAlign.center,
              style: TextStyle(color: GardenColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 48),
            _primaryButton('Ver redes disponibles', _showWifiForm),
          ],
        ),
      );
    }

  Widget _buildWifiConnecting() {
      final ssid = ref.watch(wifiSsidProvider);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación de ondas WiFi
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GardenColors.potOrange.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.cloud_upload_rounded,
                    size: 64, color: GardenColors.potOrange),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Configurando chip...',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enviando credenciales de "$ssid" al chip.\nEl chip intentará conectarse a internet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GardenColors.inkSoft, height: 1.5),
            ),
          ],
        ),
      );
    }

  Widget _buildWifiConnected() {
      final ssid = ref.watch(wifiSsidProvider);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GardenColors.leafGreen.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 64, color: GardenColors.leafGreen),
            ),
            const SizedBox(height: 32),
            const Text(
              '¡Conexión exitosa!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: GardenColors.leafGreen),
            ),
            const SizedBox(height: 12),
            Text(
              'El chip se conectó a "$ssid"\ny ya está enviando datos de los sensores.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GardenColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 48),
            _primaryButton('¡Mi planta está lista!', () {
              widget.onComplete();
            }),
          ],
        ),
      );
    }

  Widget _buildWifiError() {
      final errorMessage = ref.watch(wifiErrorProvider);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GardenColors.heartRed.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 64, color: GardenColors.heartRed),
            ),
            const SizedBox(height: 32),
            const Text(
              'Error de configuración',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: GardenColors.heartRed),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'El chip no pudo conectarse a la red WiFi.\nVerifica la contraseña e intenta de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GardenColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 48),
            _primaryButton('Reintentar', () {
              ref.read(wifiPhaseProvider.notifier).state =
                  WifiPhase.instruction;
              _startPairing();
            }),
          ],
        ),
      );
    }

}
