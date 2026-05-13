import 'package:flutter_dotenv/flutter_dotenv.dart';

enum MapProvider { osm, google }

final class AppConfig {
  const AppConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.mapProvider,
    this.googleMapsApiKey,
  });

  static late final AppConfig _instance;
  static AppConfig get instance => _instance;

  final String supabaseUrl;
  final String supabaseAnonKey;
  final MapProvider mapProvider;
  final String? googleMapsApiKey;

  static Future<void> initialize() async {
    await dotenv.load();

    _instance = AppConfig._(
      supabaseUrl: dotenv.env['SUPABASE_URL']!,
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      mapProvider: dotenv.env['MAP_PROVIDER'] == 'google'
          ? MapProvider.google
          : MapProvider.osm,
      googleMapsApiKey: dotenv.env['GOOGLE_MAPS_API_KEY'],
    );
  }
}
