import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _plantsKey = 'cache_plants';
  static const String _chatPrefix = 'cache_chat_';

  /// Guarda la lista de plantas (JSON)
  Future<void> savePlantsData(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_plantsKey, jsonString);
  }

  /// Recupera la lista de plantas (JSON) guardada
  Future<String?> getPlantsData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_plantsKey);
  }

  /// Guarda un JSON string en local para un chat específico
  Future<void> saveChatData(String plantId, String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_chatPrefix$plantId', jsonString);
  }

  /// Recupera el JSON string guardado de un chat específico
  Future<String?> getChatData(String plantId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_chatPrefix$plantId');
  }
  
  /// Limpia la caché (útil para cuando el usuario cierra sesión)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (String key in keys) {
      if (key == _plantsKey || key.startsWith(_chatPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
