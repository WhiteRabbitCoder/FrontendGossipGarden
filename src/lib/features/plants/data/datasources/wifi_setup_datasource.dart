/// Stub del datasource de configuración WiFi para el ESP32.
/// Implementación real pendiente de desarrollo del hardware.
class WifiSetupDatasource {
  const WifiSetupDatasource();

  Future<List<Map<String, dynamic>>> scanNetworks() async => const [];

  Future<bool> configureDevice({
    required String ssid,
    required String password,
  }) async =>
      false;

  Future<bool> pairDevice() async => false;
}
