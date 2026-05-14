import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:operadorapp/features/settings/domain/entities/app_settings.dart';
import 'package:operadorapp/features/settings/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(title: 'Apariencia'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: AppThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Oscuro'),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('Auto'),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) =>
                        notifier.setThemeMode(selection.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Notificaciones'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.inAppNotificationsEnabled,
                  onChanged: (v) =>
                      notifier.setInAppNotificationsEnabled(enabled: v),
                  title: const Text('Notificaciones en app'),
                  subtitle: const Text('Alertas dentro de la aplicación'),
                  secondary: const Icon(Icons.notifications_outlined),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // TODO(fase-8): Activar cuando haya Apple Developer account.
                // Al habilitarse debe: registrar FCM/APNs token en Supabase,
                // pedir permiso al sistema operativo (permission_handler),
                // y suscribirse al topic del operador en Firebase.
                SwitchListTile(
                  value: settings.pushNotificationsEnabled,
                  onChanged: (v) =>
                      notifier.setPushNotificationsEnabled(enabled: v),
                  title: const Text('Notificaciones push'),
                  subtitle: const Text('Disponibles próximamente'),
                  secondary: const Icon(Icons.phone_android_outlined),
                  tileColor: Colors.transparent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Sincronización'),
          _SyncStatusCard(),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Cuenta'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'OperadorApp v1.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.asphaltBorder,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(logoutNotifierProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _SyncStatusCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Card(
      child: ListTile(
        leading: Icon(
          isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: isOnline ? AppColors.success : AppColors.asphaltBorder,
        ),
        title: Text(isOnline ? 'Conectado' : 'Sin conexión'),
        subtitle: Text(
          isOnline
              ? 'Los datos se sincronizan automáticamente'
              : 'Usando datos locales — se sincronizará al volver la red',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
