import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trips/presentation/widgets/trip_card.dart';
import 'package:operadorapp/shared/widgets/app_error_widget.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

class TripsListScreen extends ConsumerWidget {
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Viajes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_shipping_outlined),
            tooltip: 'Mis Tractos',
            onPressed: () => context.push('/trucks'),
          ),
        ],
      ),
      body: tripsAsync.when(
        loading: () => const AppLoadingWidget(message: 'Cargando viajes...'),
        error: (error, _) => AppErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(tripsProvider),
        ),
        data: (trips) => trips.isEmpty
            ? const _EmptyTrips()
            : RefreshIndicator(
                onRefresh: () => _syncTrips(ref),
                child: _GroupedList(trips: trips),
              ),
      ),
    );
  }

  Future<void> _syncTrips(WidgetRef ref) async {
    final operadorId =
        ref.read(authStateProvider).value?.operatorId ?? '';
    if (operadorId.isNotEmpty) {
      await ref.read(syncServiceProvider).syncTrips(operadorId);
    }
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.trips});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    String? currentMonth;

    for (final trip in trips) {
      final month = DateFormat('MMMM yyyy', 'es_MX')
          .format(trip.fechaInicio ?? trip.createdAt);
      if (month != currentMonth) {
        items.add(_MonthHeader(label: month));
        currentMonth = month;
      }
      items.add(
        TripCard(
          key: ValueKey(trip.id),
          trip: trip,
          onTap: () => context.push('/trips/${trip.id}'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: items,
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withAlpha(60),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin viajes registrados',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Tu historial de rutas aparecerá aquí',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
