/// Rutas de iconos personalizados en `images/`.
class GardenIcons {
  GardenIcons._();

  static const _base = 'images';

  // Navegación principal
  static const home = '$_base/house_icon.png';
  static const garden = '$_base/Icons.eco.png';
  static const chat = '$_base/Icons.chat_bubble.png';
  static const profile = '$_base/Icons.person.png';
  static const profileAlt = '$_base/Icons_perfil.png';

  // Acciones
  static const add = '$_base/Icons_mas.png';
  static const addPlant = '$_base/Icons_add_plant.png';
  static const friendAdd = '$_base/Inos_friend_add.png';
  static const back = 'assets/icons/sensor_icons/arrow_back.png';
  static const forward = '$_base/Icons_arrow_front.png';
  static const settings = '$_base/Icons_configurate.png';
  static const pencil = '$_base/Icons_lapiz.png';
  static const camera = '$_base/Icons_camera.png';
  static const letters = '$_base/Icons_leters.png';
  static const share = '$_base/Icons_shine.png';

  // Vistas
  static const viewList = '$_base/Icons_view_list.png';
  static const viewGrid = '$_base/Icons_view_square.png';

  // Notificaciones
  static const notification = '$_base/Icons_plant_alert.png';
  static const notificationAlt = '$_base/Icons_bolbillo.png';

  // Sensores / conectividad
  static const wifi = '$_base/Icons_wifi.png';
  static const signal = '$_base/Icons_senal.png';
  static const wifiConnect = '$_base/Icons_add_wifi_connect.png';
  static const wrongConexion = '$_base/Icons_wrong_conexion.png';
  static const sensorOffline = wrongConexion;
  static const telemetry2 = '$_base/Icons_telemetry_2.png';
  static const soilHumidity = '$_base/Icons_humedad_suelo.png';

  // Cuidados de planta
  static const water = '$_base/Icons_water_drop.png';
  static const sun = '$_base/Icons_wb_sunny.png';
  static const thermostat = '$_base/Icons_thermostat.png';
  static const humidity = '$_base/Icons_humedad.png';
  static const soil = '$_base/Icons_tierra.png';
  static const potDry = '$_base/Icons_pot_dry.png';
  static const potCold = '$_base/Icons_pot_cold.png';
  static const potSun = '$_base/Icons_pot_sun.png';

  // Plantas / social
  static const plantEco = '$_base/Icons.eco.png';
  static const plantChat = '$_base/Icons_chat_plants.png';
  static const friendPlants = '$_base/Icons_friend_plants.png';

  // Formularios / auth
  static const google = '$_base/Icons_google.png';
  static const email = '$_base/Icons.email_email_outlined.png';
  static const lock = '$_base/Icons_lock.png';
  static const eyeOpen = '$_base/Icons_visibility_outlined_eye_open.png';
  static const eyeClose = '$_base/Icons_visibility_outlined_eye _close.png';
  static const phone = '$_base/Icons_celphone.png';

  // Ajustes / soporte
  static const shield = '$_base/Icons_shield.png';
  static const shieldAlt = '$_base/Icons_shield_2.png';
  static const info = '$_base/Icons_info.png';
  static const bulb = '$_base/Icons_bombillo_2.png';
  static const starOutline = '$_base/icons_start_outline.png';
  static const starFilled = '$_base/Icons_start_fully.png';
  static const helpBooks = '$_base/Icons_add_books.png';

  // Perfil de planta
  static const map = '$_base/Icons_mapa.png';
  static const mountain = '$_base/Icons_montana.png';
  static const calendar = '$_base/Icons_calendar.png';
  static const calendarAlt = '$_base/Icons_calendar_2.png';

  // Logos
  static const logoWithText = '$_base/logo_with_text.png';
  static const logoNoText = '$_base/logo_no_text.png';

  // Logros
  static const logroTrofeo = '$_base/Icons_logro_Trofeo.png';
  static const logroMedalla = '$_base/Icons_logro_Medalla.png';
  static const logroInvestigacion = '$_base/Icons__logroInvestigación.png';
  static const logroComunidad = '$_base/Icons_logro_Comunidad.png';
  static const logroCrecimiento = '$_base/Icons_logro_Crecimiento.png';
  static const logroSensores = '$_base/Icons_logro_sensores.png';
  static const logroRacha = '$_base/Icons_logro_racha.png';
  static const logroExplorador = '$_base/Icons_logro_Logros.png';
  static const logroFavorita = '$_base/Icons_logro_Planta_favorita.png';
  static const logroTrofeo2 = '$_base/Icons_logro_Trofeo_2.png';
  static const logroDesbloqueado = logroTrofeo2;

  static String plantAssetForSpecies(String species) {
    final lower = species.toLowerCase();
    if (lower.contains('echeveria') || lower.contains('suculenta')) {
      return plantEco;
    }
    if (lower.contains('ficus') || lower.contains('monstera')) {
      return plantChat;
    }
    if (lower.contains('sansevieria')) {
      return potSun;
    }
    return plantEco;
  }

  static String sensorStatusAsset(String status) {
    return switch (status) {
      'online' => wifi,
      'degraded' => signal,
      'offline' => sensorOffline,
      _ => sensorOffline,
    };
  }

  static String achievementAsset(String id) {
    return switch (id) {
      'rey_lluvia' => logroTrofeo,
      'pulgar_verde' => logroMedalla,
      'cientifico_botanico' => logroInvestigacion,
      'conversador_natural' => logroComunidad,
      'primer_brote' => logroCrecimiento,
      'coleccionista_verde' => addPlant,
      'maestro_sensor' => logroSensores,
      'racha_constante' => logroRacha,
      'explorador_jardin' => logroExplorador,
      'corazon_verde' => logroFavorita,
      _ => plantEco,
    };
  }
}
