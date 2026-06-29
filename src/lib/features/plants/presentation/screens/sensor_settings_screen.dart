import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_bottom_sheet_container.dart';
import '../../../../core/widgets/garden_icon.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../providers/achievement_providers.dart';
import '../providers/plant_providers.dart';
import '../providers/sensor_setup_providers.dart';
import '../../data/datasources/plant_api_datasource.dart';

// Flujo real del chip IoT y vinculación de estado del sensor a la planta en Supabase.
class SensorSettingsScreen extends ConsumerStatefulWidget {
  final String? initialPlantId;

  const SensorSettingsScreen({super.key, this.initialPlantId});

  @override
  ConsumerState<SensorSettingsScreen> createState() => _SensorSettingsScreenState();
}

class _SensorSettingsScreenState extends ConsumerState<SensorSettingsScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlantId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sensorSelectedPlantIdProvider.notifier).state =
            widget.initialPlantId;
        ref.read(sensorSetupPhaseProvider.notifier).state =
            SensorSetupPhase.overview;
      });
    }
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _resetToOverview() {
    ref.read(sensorSetupPhaseProvider.notifier).state = SensorSetupPhase.overview;
    ref.read(sensorWifiScanningProvider.notifier).state = false;
  }

  void _startConfiguration() {
    ref.read(sensorSetupPhaseProvider.notifier).state = SensorSetupPhase.instruction;
  }

  Future<void> _scanNetworks() async {
    ref.read(sensorWifiErrorProvider.notifier).state = null;
    ref.read(sensorWifiScanningProvider.notifier).state = true;
    
    try {
      final client = ref.read(esp32ApiClientProvider);
      final networks = await client.getWifiNetworks();
      final macAddress = await client.getSystemInfo();
      
      if (!mounted) return;
      ref.read(sensorWifiNetworksProvider.notifier).state = networks;
      ref.read(sensorMacAddressProvider.notifier).state = macAddress;
      ref.read(sensorSetupPhaseProvider.notifier).state = SensorSetupPhase.form;
    } catch (e) {
      if (!mounted) return;
      ref.read(sensorWifiErrorProvider.notifier).state = e.toString().replaceAll('Exception: ', '');
      ref.read(sensorSetupPhaseProvider.notifier).state = SensorSetupPhase.error;
    } finally {
      if (mounted) {
        ref.read(sensorWifiScanningProvider.notifier).state = false;
      }
    }
  }

  void _selectNetwork(WifiNetworkOption network) {
    _ssidController.text = network.ssid;
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
              child: GardenBottomSheetContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      network.ssid.isEmpty ? 'Conectar a red oculta' : 'Conectar a ${network.ssid}',
                      style: GardenTextStyles.title.copyWith(
                        fontWeight: FontWeight.w800,
                        color: GardenColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (network.ssid.isEmpty) ...[
                      TextField(
                        controller: _ssidController,
                        decoration: _inputDecoration('Nombre de la red (SSID)', GardenIcons.wifi),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: _inputDecoration('Contraseña WiFi', GardenIcons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: GardenIcon(
                            asset: _passwordVisible
                                ? GardenIcons.eyeClose
                                : GardenIcons.eyeOpen,
                            size: 22,
                            opacity: 0.6,
                          ),
                          onPressed: () => setModalState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close modal
                          _connectSensor(); // Start connection phase on main screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GardenColors.leafDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Conectar al sensor'),
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

  Future<void> _connectSensor() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text;
    if (ssid.isEmpty) return;

    ref.read(sensorWifiErrorProvider.notifier).state = null;
    ref.read(sensorWifiSsidProvider.notifier).state = ssid;
    ref.read(sensorWifiPasswordProvider.notifier).state = password;
    ref.read(sensorSetupPhaseProvider.notifier).state = SensorSetupPhase.connecting;

    try {
      final client = ref.read(esp32ApiClientProvider);
      final success = await client.connectWifi(ssid, password);
      
      if (!mounted) return;

      if (success) {
        ref.read(sensorSetupPhaseProvider.notifier).state = SensorSetupPhase.connected;
        ref.read(sensorIsLinkedProvider.notifier).state = true;
        ref.read(achievementStatsProvider.notifier).recordSensorSetup();
        
        // Registrar la MAC en el backend (Sprint 4)
        try {
          final macAddress = await client.getSystemInfo();
          final plantIdToLink = widget.initialPlantId ?? ref.read(sensorSelectedPlantIdProvider);
          if (macAddress != null && plantIdToLink != null) {
            final api = PlantApiDatasource();
            await api.updatePlant(plantIdToLink, {'mac_address': macAddress});
            ref.read(plantsProvider.notifier).refresh();
          }
        } catch (e) {
          debugPrint('Error patching MAC address: $e');
        }
      } else {
        ref.read(sensorWifiErrorProvider.notifier).state = 'Contraseña incorrecta o red fuera de alcance.';
        ref.read(sensorSetupPhaseProvider.notifier).state = SensorSetupPhase.error;
      }
    } catch (e) {
      if (!mounted) return;
      ref.read(sensorWifiErrorProvider.notifier).state = e.toString().replaceAll('Exception: ', '');
      ref.read(sensorSetupPhaseProvider.notifier).state = SensorSetupPhase.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(sensorSetupPhaseProvider);
    final plantsAsync = ref.watch(plantsProvider);
    final linkedSsid = ref.watch(sensorWifiSsidProvider);
    final isLinked = ref.watch(sensorIsLinkedProvider);

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const GardenIcon(asset: GardenIcons.back, size: 20),
          onPressed: () {
            if (phase == SensorSetupPhase.overview) {
              Navigator.pop(context);
            } else {
              _resetToOverview();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis sensores',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              phase == SensorSetupPhase.overview
                  ? 'Estado, vinculación y configuración WiFi'
                  : 'Configuración del dispositivo IoT',
              style: GardenTextStyles.label.copyWith(color: GardenColors.inkSoft),
            ),
          ],
        ),
      ),
      body: switch (phase) {
        SensorSetupPhase.overview => _buildOverview(
            plantsAsync: plantsAsync,
            isLinked: isLinked,
            linkedSsid: linkedSsid,
          ),
        SensorSetupPhase.instruction => _buildInstruction(),
        SensorSetupPhase.scanning => _buildScanning(),
        SensorSetupPhase.form => _buildWifiForm(),
        SensorSetupPhase.connecting => _buildConnecting(),
        SensorSetupPhase.connected => _buildConnected(),
        SensorSetupPhase.error => _buildError(),
      },
    );
  }

  Widget _buildOverview({
    required AsyncValue<List<Plant>> plantsAsync,
    required bool isLinked,
    required String linkedSsid,
  }) {
    final selectedPlantId = ref.watch(sensorSelectedPlantIdProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _StatusCard(
          isLinked: isLinked,
          linkedSsid: linkedSsid,
        ),
        plantsAsync.maybeWhen(
          data: (plants) {
            if (selectedPlantId == null) return const SizedBox.shrink();
            final matches =
                plants.where((p) => p.id == selectedPlantId).toList();
            if (matches.isEmpty) return const SizedBox.shrink();
            final plant = matches.first;
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _PlantSensorIssueCard(
                plant: plant,
                onReconnect: () {
                  ref.read(sensorSelectedPlantIdProvider.notifier).state =
                      plant.id;
                  _startConfiguration();
                },
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        Text(
          'PLANTAS Y SENSORES',
          style: GardenTextStyles.label.copyWith(
            color: GardenColors.inkSoft,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        plantsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: GardenColors.leafGreen),
            ),
          ),
          error: (e, _) => Text('Error al cargar plantas: $e'),
          data: (plants) => Column(
            children: plants.map((plant) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlantSensorTile(
                  plant: plant,
                  isHighlighted: plant.id == selectedPlantId,
                  onConfigure: () {
                    ref.read(sensorSelectedPlantIdProvider.notifier).state =
                        plant.id;
                    _startConfiguration();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _startConfiguration,
          icon: const GardenIcon(asset: GardenIcons.logroSensores, size: 20),
          label: const Text('Configurar o reconectar sensor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GardenColors.leafDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GardenColors.creamPaper),
            ),
            child: Column(
              children: [
                const GardenIcon(asset: GardenIcons.logroSensores, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Prepara tu sensor',
                  style: GardenTextStyles.title.copyWith(
                    fontWeight: FontWeight.w800,
                    color: GardenColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Enciende el chip del sensor.\n'
                  '2. Conéctate a la red WiFi del sensor desde los ajustes del móvil.\n'
                  '3. Vuelve aquí y pulsa continuar para elegir la red de tu hogar.',
                  style: GardenTextStyles.bodySmall.copyWith(
                    color: GardenColors.inkSoft,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              ref.read(sensorSetupPhaseProvider.notifier).state =
                  SensorSetupPhase.scanning;
              _scanNetworks();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GardenColors.leafDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanning() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: GardenColors.leafGreen),
          SizedBox(height: 16),
          Text('Buscando redes disponibles...'),
        ],
      ),
    );
  }

  Widget _buildWifiForm() {
    final networks = ref.watch(sensorWifiNetworksProvider);
    final scanning = ref.watch(sensorWifiScanningProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Text(
          'RED WIFI DEL HOGAR',
          style: GardenTextStyles.label.copyWith(
            color: GardenColors.inkSoft,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        ...networks.map((network) {
          final selected = _ssidController.text == network.ssid;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _selectNetwork(network),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? GardenColors.leafGreen : GardenColors.creamPaper,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    GardenIcon(
                      asset: GardenIcons.wifi,
                      size: 22,
                      opacity: selected ? 1.0 : 0.6,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(network.ssid, style: GardenTextStyles.bodySmall)),
                    if (network.secured)
                      const GardenIcon(asset: GardenIcons.lock, size: 16, opacity: 0.6),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: scanning
              ? null
              : () {
                  // Modal para red oculta
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
          ),
        ),
      ],
    );
  }

  Widget _buildConnecting() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: GardenColors.leafGreen),
          SizedBox(height: 16),
          Text('Conectando sensor a la red WiFi...'),
        ],
      ),
    );
  }

  Widget _buildConnected() {
    final ssid = ref.watch(sensorWifiSsidProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GardenIcon(asset: GardenIcons.logroDesbloqueado, size: 64),
          const SizedBox(height: 16),
          Text(
            '¡Conexión exitosa!',
            style: GardenTextStyles.title.copyWith(
              fontWeight: FontWeight.w800,
              color: GardenColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ssid.isNotEmpty ? 'El sensor ahora está conectado a $ssid.' : 'Configuración completada.',
            style: GardenTextStyles.bodySmall.copyWith(color: GardenColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _resetToOverview,
            style: ElevatedButton.styleFrom(
              backgroundColor: GardenColors.leafDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Volver a mis sensores'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    final errorMessage = ref.watch(sensorWifiErrorProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GardenIcon(asset: GardenIcons.info, size: 64),
          const SizedBox(height: 16),
          Text(
            'Error de conexión',
            style: GardenTextStyles.title.copyWith(
              fontWeight: FontWeight.w800,
              color: GardenColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Verifica la contraseña WiFi e intenta de nuevo.',
            style: GardenTextStyles.bodySmall.copyWith(color: GardenColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.read(sensorSetupPhaseProvider.notifier).state = SensorSetupPhase.form;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GardenColors.leafDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, String iconAsset) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: GardenIcon(asset: iconAsset, size: 20),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GardenColors.creamPaper),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GardenColors.creamPaper),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GardenColors.leafGreen, width: 2),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isLinked;
  final String linkedSsid;

  const _StatusCard({required this.isLinked, required this.linkedSsid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GardenIcon(
                asset: isLinked ? GardenIcons.logroSensores : GardenIcons.sensorOffline,
                size: 22,
                opacity: isLinked ? 1.0 : 0.6,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isLinked ? 'Sensor vinculado' : 'Sin sensor vinculado',
                  style: GardenTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GardenColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLinked && linkedSsid.isNotEmpty)
            _InfoRow(label: 'Red WiFi', value: linkedSsid)
          else
            Text(
              'Configura un sensor para recibir datos de humedad, luz y temperatura en tiempo real.',
              style: GardenTextStyles.bodySmall.copyWith(
                color: GardenColors.inkSoft,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GardenTextStyles.label.copyWith(
            color: GardenColors.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GardenTextStyles.bodySmall.copyWith(color: GardenColors.ink),
          ),
        ),
      ],
    );
  }
}

(String, Color, String, String) sensorStatusStyle(SensorStatus status) {
  return switch (status) {
    SensorStatus.online => (
        'En línea',
        GardenColors.okGreen,
        GardenIcons.wifi,
        'El sensor envía datos con normalidad.',
      ),
    SensorStatus.degraded => (
        'Señal débil',
        GardenColors.golden,
        GardenIcons.signal,
        'Las lecturas llegan con retraso o la señal WiFi es inestable.',
      ),
    SensorStatus.offline => (
        'Sin conexión',
        GardenColors.heartRed,
        GardenIcons.sensorOffline,
        'No recibimos datos del sensor. Puede estar apagado o fuera de red.',
      ),
    SensorStatus.unlinked => (
        'Sin sensor vinculado',
        GardenColors.dust,
        GardenIcons.sensorOffline,
        'Esta planta no tiene un sensor configurado.',
      ),
  };
}

class _PlantSensorIssueCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onReconnect;

  const _PlantSensorIssueCard({
    required this.plant,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, icon, description) =
        sensorStatusStyle(plant.sensorStatus);
    // HARDCODE(demo): consejos de diagnóstico estáticos por estado de sensor.
    final tips = switch (plant.sensorStatus) {
      SensorStatus.offline => const [
          'Verifica que el sensor esté encendido y con batería.',
          'Comprueba que el WiFi de tu hogar funcione correctamente.',
          'Reinicia el sensor manteniendo el botón 5 segundos.',
        ],
      SensorStatus.unlinked => const [
          'Toca el botón arriba "Vincular hardware" para empezar.',
          'Asegúrate de estar cerca del sensor al configurarlo.',
        ],
      SensorStatus.degraded => const [
          'Acerca el sensor al router o usa un repetidor WiFi.',
          'Evita obstáculos gruesos entre el sensor y la red.',
          'Si persiste, reconecta el dispositivo.',
        ],
      SensorStatus.online => [
          'El sensor de ${plant.name} funciona correctamente.',
          'Puedes revisar la red vinculada o reconfigurar si cambias de WiFi.',
        ],
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: GardenIcon(asset: icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: GardenTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GardenColors.ink,
                      ),
                    ),
                    Text(
                      label,
                      style: GardenTextStyles.label.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GardenTextStyles.bodySmall.copyWith(
              color: GardenColors.inkSoft,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: GardenTextStyles.bodySmall.copyWith(
                        color: GardenColors.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (plant.sensorStatus != SensorStatus.online) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onReconnect,
                icon: const GardenIcon(asset: GardenIcons.wifiConnect, size: 20),
                label: const Text('Reconectar sensor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GardenColors.leafDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlantSensorTile extends StatelessWidget {
  final Plant plant;
  final bool isHighlighted;
  final VoidCallback onConfigure;

  const _PlantSensorTile({
    required this.plant,
    required this.onConfigure,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, icon, _) = sensorStatusStyle(plant.sensorStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? GardenColors.leafGreen : GardenColors.creamPaper,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: GardenColors.creamLight,
              shape: BoxShape.circle,
            ),
            child: GardenIcon(
              asset: GardenIcons.plantAssetForSpecies(plant.species),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name,
                  style: GardenTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GardenColors.ink,
                  ),
                ),
                Text(
                  plant.species,
                  style: GardenTextStyles.label.copyWith(color: GardenColors.inkSoft),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GardenIcon(asset: icon, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: GardenTextStyles.label.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onConfigure,
            icon: const GardenIcon(asset: GardenIcons.wifiConnect, size: 22),
            tooltip: 'Configurar sensor',
          ),
        ],
      ),
    );
  }
}
