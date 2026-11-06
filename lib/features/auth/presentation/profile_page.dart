import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/failures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/photo_service.dart';
import '../../../core/widgets/widgets.dart';
import 'auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<AuthBloc>();
    try {
      final bytes = await sl<PhotoService>().pick(source);
      if (bytes != null) bloc.add(PhotoSelected(bytes));
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, now) => now is Authenticated && now.message != null,
      listener: (context, state) {
        final s = state as Authenticated;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.message!)));
      },
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox.shrink();
        final user = state.user;
        final photo = user.photoBase64;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const PageHeader(
              title: 'Profile',
              subtitle: 'Your account and photo',
            ),
            Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.accent,
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.mist,
                        backgroundImage:
                            photo == null ? null : MemoryImage(base64Decode(photo)),
                        child: photo == null
                            ? const Icon(
                                Icons.person,
                                size: 56,
                                color: AppColors.indigo,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.m),
                  Text(
                    user.name,
                    textAlign: TextAlign.center,
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: Space.xl),
                  GradientButton(
                    label: 'Take a photo',
                    icon: Icons.photo_camera_outlined,
                    onPressed: () => _pick(context, ImageSource.camera),
                  ),
                  const SizedBox(height: Space.m),
                  OutlinedButton.icon(
                    onPressed: () => _pick(context, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose from gallery'),
                  ),
                  const SizedBox(height: Space.l),
                  TextButton.icon(
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(const SignOutRequested()),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
