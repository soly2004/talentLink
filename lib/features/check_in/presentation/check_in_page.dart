import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_domain.dart';
import '../../learning/domain/learning_domain.dart';
import '../../learning/presentation/learning_bloc.dart';
import 'check_in_bloc.dart';

class CheckInPage extends StatelessWidget {
  const CheckInPage({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, learning) {
        final sessions = learning.sessions;

        return BlocBuilder<CheckInBloc, CheckInState>(
          builder: (context, checkIn) {
            if (sessions.isEmpty) {
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  const PageHeader(
                    title: 'Event check-in',
                    subtitle: 'Confirm you are at the venue',
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Space.l),
                    child: learning.loading
                        ? const Center(child: CircularProgressIndicator())
                        : Text(
                            'No upcoming events yet. Check your connection and reopen the app.',
                            style: text.bodyMedium,
                          ),
                  ),
                ],
              );
            }

            // Pick the selected session with a plain loop (no orElse).
            CohortSession session = sessions.first;
            for (final s in sessions) {
              if (s.id == checkIn.selectedId) {
                session = s;
                break;
              }
            }

            final busy = checkIn.status == CheckInStatus.busy;
            final center = LatLng(session.latitude, session.longitude);

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const PageHeader(
                  title: 'Event check-in',
                  subtitle: 'Confirm you are at the venue',
                ),
                Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose your event', style: text.titleLarge),
                      const SizedBox(height: Space.m),
                      Wrap(
                        spacing: Space.s,
                        runSpacing: Space.s,
                        children: [
                          for (final s in sessions)
                            ChoiceChip(
                              label: Text(s.title),
                              selected: s.id == session.id,
                              selectedColor:
                                  AppColors.lightPurple.withValues(alpha: 0.5),
                              onSelected: busy
                                  ? null
                                  : (_) => context
                                      .read<CheckInBloc>()
                                      .add(SessionChosen(s.id)),
                            ),
                        ],
                      ),
                      const SizedBox(height: Space.l),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.card),
                        child: SizedBox(
                          height: 240,
                          child: GoogleMap(
                            key: ValueKey(session.id),
                            initialCameraPosition:
                                CameraPosition(target: center, zoom: 15.5),
                            markers: {
                              Marker(
                                markerId: MarkerId(session.id),
                                position: center,
                                infoWindow: InfoWindow(title: session.title),
                              ),
                            },
                            circles: {
                              Circle(
                                circleId: CircleId(session.id),
                                center: center,
                                radius: session.radiusMeters.toDouble(),
                                fillColor:
                                    AppColors.purple.withValues(alpha: 0.2),
                                strokeColor: AppColors.purple,
                                strokeWidth: 2,
                              ),
                            },
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.m),
                      Text(session.title, style: text.titleMedium),
                      const SizedBox(height: Space.xs),
                      Text(
                        '${session.location}  -  check-in within ${session.radiusMeters} m',
                        style: text.bodyMedium,
                      ),
                      if (checkIn.message != null) ...[
                        const SizedBox(height: Space.m),
                        StatusBanner(
                          message: checkIn.message!,
                          isError: checkIn.status != CheckInStatus.success,
                        ),
                      ],
                      const SizedBox(height: Space.l),
                      GradientButton(
                        label: 'Check in here',
                        icon: Icons.my_location,
                        loading: busy,
                        onPressed: () => context
                            .read<CheckInBloc>()
                            .add(CheckInPressed(user.uid, session)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}