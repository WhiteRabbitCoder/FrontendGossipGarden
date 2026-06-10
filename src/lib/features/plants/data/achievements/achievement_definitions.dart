import '../models/achievement.dart';

const kAchievementDefinitions = <AchievementDefinition>[
  AchievementDefinition(
    id: 'rey_lluvia',
    icon: '🏅',
    title: 'Rey de la Lluvia',
    description: 'Domina el arte del riego y mantén tus plantas hidratadas.',
    howToEarn:
        'El sensor detecta un riego cuando la humedad del suelo sube de forma notable '
        '(+5% o más) respecto a la lectura anterior. Necesitas 10 riegos detectados.',
    trackingSource:
        'Se captura automáticamente al comparar cada actualización del sensor de la planta '
        '(humedad de suelo y ambiente) con su lectura previa.',
    goal: 10,
    metric: AchievementMetric.waterings,
  ),
  AchievementDefinition(
    id: 'pulgar_verde',
    icon: '🎖️',
    title: 'Pulgar Verde',
    description: 'Demuestra que sabes mantener plantas sanas y felices.',
    howToEarn:
        'Cuenta cuántas plantas de tu jardín tienen un nivel de salud igual o superior al 80%. Necesitas 3 plantas en ese estado.',
    trackingSource:
        'Se calcula automáticamente leyendo la salud de tus plantas desde el backend.',
    goal: 3,
    metric: AchievementMetric.healthyPlants,
  ),
  AchievementDefinition(
    id: 'cientifico_botanico',
    icon: '🔬',
    title: 'Científico Botánico',
    description: 'Conviértete en un experto identificando especies.',
    howToEarn:
        'Identifica plantas con la cámara o la búsqueda manual. Cada identificación exitosa suma 1 punto. Meta: 20 identificaciones.',
    trackingSource:
        'Se registra al completar una identificación en la pantalla "Nueva planta".',
    goal: 20,
    metric: AchievementMetric.identifications,
  ),
  AchievementDefinition(
    id: 'conversador_natural',
    icon: '💬',
    title: 'Conversador Natural',
    description: 'Habla con tus plantas y construye una relación única.',
    howToEarn:
        'Envía mensajes en el chat de cualquier planta. Cada mensaje que envíes suma 1 punto. Necesitas 50 mensajes.',
    trackingSource:
        'Se captura cada vez que envías un mensaje en PlantChatScreen.',
    goal: 50,
    metric: AchievementMetric.chatMessages,
  ),
  AchievementDefinition(
    id: 'primer_brote',
    icon: '🌱',
    title: 'Primer Brote',
    description: 'Da el primer paso en tu jardín digital.',
    howToEarn:
        'Agrega tu primera planta al jardín, ya sea por identificación o manualmente.',
    trackingSource:
        'Se calcula contando las plantas de tu cuenta (GET /api/v1/plants/).',
    goal: 1,
    metric: AchievementMetric.plantsOwned,
  ),
  AchievementDefinition(
    id: 'coleccionista_verde',
    icon: '🪴',
    title: 'Coleccionista Verde',
    description: 'Tu jardín crece y florece con variedad.',
    howToEarn: 'Reúne 5 plantas distintas en tu jardín para desbloquear este logro.',
    trackingSource:
        'Se calcula automáticamente con el total de plantas en tu cuenta.',
    goal: 5,
    metric: AchievementMetric.plantsOwned,
  ),
  AchievementDefinition(
    id: 'maestro_sensor',
    icon: '📡',
    title: 'Maestro del Sensor',
    description: 'Conecta tu chip y entra en el mundo de la telemetría.',
    howToEarn:
        'Completa el onboarding de WiFi y vincula el sensor de al menos una planta.',
    trackingSource:
        'Se registra al finalizar el setup de sensor en el onboarding.',
    goal: 1,
    metric: AchievementMetric.sensorSetup,
  ),
  AchievementDefinition(
    id: 'racha_constante',
    icon: '🔥',
    title: 'Racha Constante',
    description: 'La constancia es la clave de todo jardinero.',
    howToEarn:
        'Abre la app en días consecutivos. Cada día que inicies sesión suma a tu racha. Necesitas 7 días seguidos.',
    trackingSource:
        'Se captura al abrir el perfil o iniciar sesión, comparando la fecha del día anterior.',
    goal: 7,
    metric: AchievementMetric.loginStreak,
  ),
  AchievementDefinition(
    id: 'explorador_jardin',
    icon: '🏡',
    title: 'Explorador del Jardín',
    description: 'Visita tu jardín con frecuencia y vigila cada hoja.',
    howToEarn:
        'Entra a la pantalla "Mi Jardín". Cada día que la visites suma 1 visita. Meta: 30 visitas.',
    trackingSource:
        'Se registra una vez por día al abrir GardenViewScreen.',
    goal: 30,
    metric: AchievementMetric.gardenVisits,
  ),
  AchievementDefinition(
    id: 'corazon_verde',
    icon: '❤️',
    title: 'Corazón Verde',
    description: 'Marca tus plantas preferidas y cuídalas con cariño.',
    howToEarn:
        'Agrega plantas a tu lista de favoritas desde el perfil. Necesitas 3 favoritas.',
    trackingSource:
        'Se calcula con la lista de favoritas guardada en tu perfil local.',
    goal: 3,
    metric: AchievementMetric.favoritePlants,
  ),
];

AchievementDefinition? achievementById(String id) {
  for (final def in kAchievementDefinitions) {
    if (def.id == id) return def;
  }
  return null;
}
