class AppConfig {
  static const appName = 'VyparHub';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vyparhub.onrender.com/api',
  );
  static const publicBaseUrl = String.fromEnvironment(
    'PUBLIC_BASE_URL',
    defaultValue: 'https://vyparhub.onrender.com',
  );
  static bool get useMockData => apiBaseUrl.isEmpty;
  static const freeDeliveryThreshold = 1000;
}
