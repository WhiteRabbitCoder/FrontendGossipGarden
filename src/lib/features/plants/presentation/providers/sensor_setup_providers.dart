import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/esp32_api_client.dart';

enum SensorSetupPhase {
  overview,
  instruction,
  scanning,
  form,
  connecting,
  connected,
  error,
}

class WifiNetworkOption {
  final String ssid;
  final int signal;
  final bool secured;

  const WifiNetworkOption({
    required this.ssid,
    required this.signal,
    required this.secured,
  });
}

final sensorSetupPhaseProvider =
    StateProvider<SensorSetupPhase>((ref) => SensorSetupPhase.overview);

final esp32ApiClientProvider = Provider<Esp32ApiClient>((ref) => Esp32ApiClient());

final sensorWifiErrorProvider = StateProvider<String?>((ref) => null);

final sensorWifiSsidProvider = StateProvider<String>((ref) => '');

final sensorWifiPasswordProvider = StateProvider<String>((ref) => '');

final sensorWifiNetworksProvider =
    StateProvider<List<WifiNetworkOption>>((ref) => []);

final sensorWifiScanningProvider = StateProvider<bool>((ref) => false);

// MAC Address temporal del sensor que se lee antes de crear la planta
final sensorMacAddressProvider = StateProvider<String?>((ref) => null);

/// Planta seleccionada para vincular o reconfigurar el sensor.
final sensorSelectedPlantIdProvider = StateProvider<String?>((ref) => null);

// HARDCODE(demo): estado de vinculación solo en memoria. TODO(backend): persistir por planta/dispositivo.
final sensorIsLinkedProvider = StateProvider<bool>((ref) => false);
