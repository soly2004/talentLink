import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection.dart';
import 'auth/domain/auth_domain.dart';
import 'auth/presentation/profile_page.dart';
import 'check_in/presentation/check_in_bloc.dart';
import 'check_in/presentation/check_in_page.dart';
import 'learning/presentation/learning_bloc.dart';
import 'learning/presentation/learning_page.dart';

/// Signed-in experience: three tabs, one thumb-reach bottom bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});
  final AppUser user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    context.read<LearningBloc>().add(LearningStarted(widget.user.uid));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      LearningPage(user: widget.user),
      CheckInPage(user: widget.user),
      const ProfilePage(),
    ];

    return BlocProvider<CheckInBloc>(
      create: (_) => sl<CheckInBloc>(),
      child: Scaffold(
        body: pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Learn',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on),
              label: 'Check in',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
