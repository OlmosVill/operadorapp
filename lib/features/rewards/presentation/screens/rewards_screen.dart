import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/premio_card.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  // 0 = Todos, 1 = Disponibles, 2 = Mis Canjes
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.medium(
            title: Text('Premios'),
          ),
          SliverToBoxAdapter(
            child: _BalanceCard()
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.1, end: 0),
          ),
          SliverToBoxAdapter(
            child: _FilterTabs(
              selected: _tabIndex,
              onSelected: (i) => setState(() => _tabIndex = i),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms),
          ),
          if (_tabIndex == 2)
            _CanjesSliver()
          else
            _CatalogSliver(showOnlyAvailable: _tabIndex == 1),
        ],
      ),
    );
  }
}

// ─── Balance card ────────────────────────────────────────────────────────────

class _BalanceCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final points = profile?.availablePoints ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: AppColors.amber,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puntos disponibles',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  Text(
                    '$points pts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filter tabs ─────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        children: [
          _chip(context, 0, 'Todos'),
          _chip(context, 1, 'Disponibles'),
          _chip(context, 2, 'Mis Canjes'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, int index, String label) {
    return FilterChip(
      label: Text(label),
      selected: selected == index,
      onSelected: (_) => onSelected(index),
    );
  }
}

// ─── Catalog grid ────────────────────────────────────────────────────────────

class _CatalogSliver extends ConsumerWidget {
  const _CatalogSliver({required this.showOnlyAvailable});

  final bool showOnlyAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(premiosProvider);

    return async.when(
      loading: () => const SliverFillRemaining(
        child: AppLoadingWidget(message: 'Cargando premios...'),
      ),
      error: (_, __) => const SliverFillRemaining(
        child: Center(child: Text('Error al cargar premios')),
      ),
      data: (premios) {
        final profile = ref.watch(profileProvider).value;
        final filtered = showOnlyAvailable
            ? premios
                .where(
                  (p) =>
                      (profile?.availablePoints ?? 0) >= p.costoPuntos &&
                      (p.nivelMinimo == null ||
                          (profile?.level.index ?? 0) >=
                              p.nivelMinimo!.index),
                )
                .toList()
            : premios;

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyState(
              message: showOnlyAvailable
                  ? 'Acumula más puntos para desbloquear premios'
                  : 'No hay premios disponibles',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid.builder(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) => PremioCard(premio: filtered[i])
                .animate()
                .fadeIn(
                  duration: 350.ms,
                  delay: Duration(milliseconds: 50 * i),
                )
                .slideY(begin: 0.1, end: 0),
          ),
        );
      },
    );
  }
}

// ─── Canjes list ─────────────────────────────────────────────────────────────

class _CanjesSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(canjesProvider);

    return async.when(
      loading: () => const SliverFillRemaining(
        child: AppLoadingWidget(message: 'Cargando canjes...'),
      ),
      error: (_, __) => const SliverFillRemaining(
        child: Center(child: Text('Error al cargar canjes')),
      ),
      data: (canjes) {
        if (canjes.isEmpty) {
          return const SliverFillRemaining(
            child: _EmptyState(message: 'Aún no tienes canjes registrados'),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList.builder(
            itemCount: canjes.length,
            itemBuilder: (_, i) => _CanjeTile(canje: canjes[i])
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: 40 * i),
                ),
          ),
        );
      },
    );
  }
}

class _CanjeTile extends StatelessWidget {
  const _CanjeTile({required this.canje});

  final Canje canje;

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(canje.estado);
    final fmt = DateFormat('dd MMM yyyy', 'es_MX');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(Icons.redeem_rounded, color: color, size: 20),
        ),
        title: Text(
          '${canje.puntosCanjeados} pts canjeados',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(fmt.format(canje.fechaSolicitud.toLocal())),
        trailing: Chip(
          label: Text(
            canje.estado.displayName,
            style: TextStyle(fontSize: 11, color: color),
          ),
          backgroundColor: color.withAlpha(25),
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          labelPadding:
              const EdgeInsets.symmetric(horizontal: 6),
        ),
      ),
    );
  }

  Color _estadoColor(CanjeEstado estado) => switch (estado) {
        CanjeEstado.solicitado => AppColors.amber,
        CanjeEstado.aprobado => Colors.green,
        CanjeEstado.rechazado => Colors.red,
        CanjeEstado.entregado => Colors.blue,
      };
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.redeem_outlined,
            size: 64,
            color: AppColors.textSecondaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
