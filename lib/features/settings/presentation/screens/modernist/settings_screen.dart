import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:operadorapp/features/settings/domain/entities/app_settings.dart';
import 'package:operadorapp/features/settings/presentation/providers/settings_provider.dart';

/// Configuración, en el sistema Modernist.
///
/// Es la única vista sin export propio: se compuso con las piezas que el
/// sistema ya tenía —cabecera con retroceso, bandas separadas por reglas de
/// 2 px, selector segmentado como el de periodos del ranking— para que no
/// desentone con el resto.
///
/// Se llega por el engrane del perfil: el export cambió la cuarta pestaña por
/// Perfil, así que Ajustes ya no vive en la barra.
class ModernistSettingsScreen extends ConsumerWidget {
  const ModernistSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ModernistPalette.of(context);
    final overlay =
        palette.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: palette.bg,
        systemNavigationBarIconBrightness:
            palette.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          child: Column(
            children: [
              const _SettingsHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: const [
                    _ThemeSection(),
                    _NotificationsSection(),
                    _SyncSection(),
                    _AccountSection(),
                    _VersionNote(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cabecera ───────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/profile'),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: palette.ink,
                  width: ModernistRule.base,
                ),
              ),
              child: Text(
                '←',
                style: ModernistType.of(
                  size: 19,
                  weight: 900,
                  color: palette.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AJUSTES DE LA APP',
                  style: ModernistType.kicker(
                    size: 10,
                    tracking: 0.14,
                    color: palette.kicker,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Configuración',
                  style: ModernistType.of(
                    size: 23,
                    weight: 800,
                    color: palette.ink,
                    tracking: -0.02,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bloque genérico ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ModernistType.of(
              size: 13,
              weight: 900,
              color: palette.ink,
              tracking: 0.16,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Tema ───────────────────────────────────────────────────────────────────

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ModernistPalette.of(context);
    final current = ref.watch(settingsProvider).themeMode;

    return _Section(
      title: 'APARIENCIA',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: palette.ink, width: ModernistRule.base),
        ),
        child: Row(
          children: [
            for (final mode in AppThemeMode.values)
              Expanded(
                child: _ThemeOption(
                  mode: mode,
                  selected: mode == current,
                  onTap: () => unawaited(
                    ref.read(settingsProvider.notifier).setThemeMode(mode),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        alignment: Alignment.center,
        color: selected ? palette.ink : null,
        child: Text(
          mode.displayName.toUpperCase(),
          style: ModernistType.of(
            size: 11,
            weight: 800,
            color: selected ? palette.bg : palette.ink,
            tracking: 0.12,
          ),
        ),
      ),
    );
  }
}

// ─── Notificaciones ─────────────────────────────────────────────────────────

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return _Section(
      title: 'NOTIFICACIONES',
      child: Column(
        children: [
          _ToggleRow(
            label: 'En la app',
            note: 'Avisos dentro de la aplicación',
            value: settings.inAppNotificationsEnabled,
            onChanged: (v) => unawaited(
              notifier.setInAppNotificationsEnabled(enabled: v),
            ),
          ),
          _ToggleRow(
            label: 'Push',
            note: 'Disponibles próximamente',
            value: settings.pushNotificationsEnabled,
            // Se deja apagado hasta que exista la cuenta de Apple Developer y
            // el registro de token en `operador_devices` (Fase 8).
            onChanged: null,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.note,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String note;
  final bool value;

  /// `null` deja la fila inerte.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final enabled = onChanged != null;

    return GestureDetector(
      onTap: enabled ? () => onChanged!(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.rowDivider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: ModernistType.of(
                      size: 15,
                      weight: 700,
                      color: enabled ? palette.ink : palette.kicker,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    note,
                    style: ModernistType.of(
                      size: 12,
                      weight: 600,
                      color: palette.note,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _SquareSwitch(value: value, enabled: enabled),
          ],
        ),
      ),
    );
  }
}

/// Interruptor con las esquinas a 0 y el borde de 2 px del sistema — el
/// `Switch` de Material, con su píldora redondeada, rompería el lenguaje.
class _SquareSwitch extends StatelessWidget {
  const _SquareSwitch({required this.value, required this.enabled});

  final bool value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final border = enabled ? palette.ink : palette.outlineMuted;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: value ? ModernistColors.red : null,
          border: Border.all(color: border, width: ModernistRule.base),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: value ? ModernistColors.onRed : border,
          ),
        ),
      ),
    );
  }
}

// ─── Sincronización ─────────────────────────────────────────────────────────

class _SyncSection extends ConsumerWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ModernistPalette.of(context);
    final online = ref.watch(isOnlineProvider).value ?? true;

    return _Section(
      title: 'SINCRONIZACIÓN',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(top: 3),
            color: online ? palette.positive : palette.outlineMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  online ? 'CONECTADO' : 'SIN CONEXIÓN',
                  style: ModernistType.of(
                    size: 12,
                    weight: 800,
                    color: palette.ink,
                    tracking: 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  online
                      ? 'Los datos se sincronizan solos.'
                      : 'Usando datos locales — se sincroniza al volver la '
                          'red.',
                  style: ModernistType.of(
                    size: 12,
                    weight: 600,
                    color: palette.note,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cuenta ─────────────────────────────────────────────────────────────────

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ModernistPalette.of(context);

    return _Section(
      title: 'CUENTA',
      child: GestureDetector(
        onTap: () => unawaited(_confirmLogout(context, ref)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border.all(
              color: palette.danger,
              width: ModernistRule.base,
            ),
          ),
          child: Text(
            'CERRAR SESIÓN',
            style: ModernistType.of(
              size: 13,
              weight: 800,
              color: palette.danger,
              tracking: 0.12,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutDialog(),
    );

    if (!(confirmed ?? false)) return;

    await ref.read(logoutNotifierProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: palette.bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.ink, width: ModernistRule.base),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CERRAR SESIÓN',
              style: ModernistType.kicker(
                size: 11,
                tracking: 0.14,
                color: palette.kicker,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '¿Seguro que quieres salir?',
              style: ModernistType.of(
                size: 24,
                weight: 900,
                color: palette.ink,
                tracking: -0.02,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tus viajes y puntos quedan guardados. Vas a necesitar tu '
              'número de empleado para volver a entrar.',
              style: ModernistType.of(
                size: 14,
                weight: 500,
                color: palette.bodyStrong,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            _DialogAction(
              label: 'SÍ, CERRAR SESIÓN',
              filled: true,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            _DialogAction(
              label: 'CANCELAR',
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: filled ? ModernistColors.red : null,
          border: filled
              ? null
              : Border.all(color: palette.ink, width: ModernistRule.base),
        ),
        child: Text(
          label,
          style: ModernistType.of(
            size: 13,
            weight: 800,
            color: filled ? ModernistColors.onRed : palette.ink,
            tracking: 0.12,
          ),
        ),
      ),
    );
  }
}

// ─── Pie ────────────────────────────────────────────────────────────────────

class _VersionNote extends StatelessWidget {
  const _VersionNote();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Text(
        'OPERADORAPP v1.0',
        style: modernistMono(size: 10, color: palette.kicker),
      ),
    );
  }
}
