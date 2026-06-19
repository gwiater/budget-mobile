class Config {
  // Zmień na IP NAS gdy testujesz na fizycznym urządzeniu w sieci lokalnej
  // Emulator Android: 10.0.2.2 (host machine localhost)
  // NAS: 192.168.100.2:8090
  static const String baseUrl = 'http://192.168.100.126:8090';
  static const String apiUrl  = '$baseUrl/api';
}
