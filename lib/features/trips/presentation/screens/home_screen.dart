import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/profile/presentation/widgets/level_badge.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

// TODO(fase-4): Reemplazar con home dinámico:
//   - Card de viaje activo con mapa miniatura y estado en tiempo real (Realtime)
//   - Animaciones de entrada con flutter_animate o Rive
//   - Indicador de racha de días con buenas métricas
//   - Acceso rápido a escanear QR de inicio/fin de viaje
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OperadorApp'),
        actions: [
          profileAsync.whenOrNull(
                data: (profile) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: LevelBadge(
                    level: profile.level,
                    size: 32,
                    showLabel: false,
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: profileAsync.when(
        loading: () => const AppLoadingWidget(message: 'Cargando...'),
        error: (_, __) => _HomeContent.empty(),
        data: (profile) => _HomeContent(
          greeting: '¡Hola, ${profile.fullName.split(' ').first}!',
          employeeNumber: profile.employeeNumber,
          availablePoints: profile.availablePoints,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.greeting,
    required this.employeeNumber,
    required this.availablePoints,
  });

  factory _HomeContent.empty() => const _HomeContent(
        greeting: '¡Bienvenido!',
        employeeNumber: '',
        availablePoints: 0,
      );

  final String greeting;
  final String employeeNumber;
  final int availablePoints;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Emp. $employeeNumber',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),

          const SizedBox(height: 32),

          // TODO(fase-4): Reemplazar con ActiveTripCard cuando haya viaje activo,
          // o NextTripCard con la próxima ruta asignada. Por ahora es placeholder.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.asphaltCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.asphaltBorder),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.amber,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sin viaje activo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu próxima ruta aparecerá aquí',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Puntos disponibles
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A2800), Color(0xFF2A1800)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.amber.withAlpha(40)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.amber),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$availablePoints pts disponibles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Ve a Premios para canjear',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.amber.withAlpha(180),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Aviso de fase en desarrollo
          Center(
            child: Text(
              'Fase 4 — Home dinámico con animaciones',
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
}
