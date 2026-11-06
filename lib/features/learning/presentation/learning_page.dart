import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_domain.dart';
import '../domain/learning_domain.dart';
import 'learning_bloc.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, state) {
        int percent(String id) => state.progress[id] ?? 0;
        void advance(String id) =>
            context.read<LearningBloc>().add(ProgressBumped(id));

        final overall = (percent(ModuleIds.fundamentals) +
                percent(ModuleIds.data) +
                percent(ModuleIds.firebase) +
                percent(ModuleIds.patterns)) ~/
            4;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            PageHeader(
              title: 'Hi, ${user.name.split(' ').first}',
              subtitle: 'Your learning hub',
              child: _OverallProgress(percent: overall),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your modules', style: text.titleLarge),
                  const SizedBox(height: Space.m),
                  _ModuleCard(
                    title: 'Flutter Fundamentals',
                    sprint: 'Sprint 1',
                    icon: Icons.widgets_outlined,
                    percent: percent(ModuleIds.fundamentals),
                    onAdvance: () => advance(ModuleIds.fundamentals),
                  ),
                  const SizedBox(height: Space.m),
                  _ModuleCard(
                    title: 'Data & State Management',
                    sprint: 'Sprint 2',
                    icon: Icons.sync_alt,
                    percent: percent(ModuleIds.data),
                    onAdvance: () => advance(ModuleIds.data),
                  ),
                  const SizedBox(height: Space.m),
                  _ModuleCard(
                    title: 'Firebase & Device Features',
                    sprint: 'Sprint 3',
                    icon: Icons.cloud_outlined,
                    percent: percent(ModuleIds.firebase),
                    onAdvance: () => advance(ModuleIds.firebase),
                  ),
                  const SizedBox(height: Space.m),
                  _ModuleCard(
                    title: 'Design Patterns',
                    sprint: 'Sprint 4',
                    icon: Icons.account_tree_outlined,
                    percent: percent(ModuleIds.patterns),
                    onAdvance: () => advance(ModuleIds.patterns),
                  ),
                  const SizedBox(height: Space.xl),
                  Text('Upcoming cohort events', style: text.titleLarge),
                  const SizedBox(height: Space.m),
                  if (state.loading)
                    const Center(child: CircularProgressIndicator()),
                  if (state.error != null) ...[
                    StatusBanner(message: state.error!),
                    const SizedBox(height: Space.m),
                  ],
                  for (final session in state.sessions) ...[
                    _SessionTile(session: session),
                    const SizedBox(height: Space.m),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverallProgress extends StatelessWidget {
  const _OverallProgress({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall progress',
              style: text.titleMedium?.copyWith(color: Colors.white),
            ),
            Text(
              '$percent%',
              style: text.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: Space.s),
        LinearProgressIndicator(
          value: percent / 100,
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          color: Colors.white,
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.sprint,
    required this.icon,
    required this.percent,
    required this.onAdvance,
  });

  final String title;
  final String sprint;
  final IconData icon;
  final int percent;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.m),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.lightPurple.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.indigo),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  Text(sprint, style: text.bodyMedium),
                  const SizedBox(height: Space.s),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: AppColors.mist,
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: Space.s),
                      Text('$percent%', style: text.labelLarge),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.s),
            IconButton.filledTonal(
              tooltip: 'Add 25% progress',
              onPressed: percent >= 100 ? null : onAdvance,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final CohortSession session;

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  String get _time {
    final d = session.startsAt;
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = session.startsAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.m),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppGradients.accent,
                borderRadius: BorderRadius.circular(Radii.button),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${d.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    _months[d.month - 1],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title, style: text.titleMedium),
                  const SizedBox(height: Space.xs),
                  Text('${session.location}  -  $_time', style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
