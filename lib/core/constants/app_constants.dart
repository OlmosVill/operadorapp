abstract final class AppConstants {
  static const String appName = 'OperadorApp';

  // Convención: el email de Supabase Auth se construye como
  // "{numero_empleado}@operadorapp.internal"
  // RH crea los usuarios con este formato.
  static const String authEmailSuffix = '@operadorapp.internal';

  // Keys de SharedPreferences
  static const String themeKey = 'app_theme_mode';
  static const String pushNotifKey = 'push_notifications_enabled';
  static const String inAppNotifKey = 'in_app_notifications_enabled';

  // Paginación
  static const int tripsPageSize = 20;
  static const int notificationsMaxLocal = 100;

  // Duración de animaciones
  static const Duration shortAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 400);
  static const Duration longAnim = Duration(milliseconds: 800);
}
