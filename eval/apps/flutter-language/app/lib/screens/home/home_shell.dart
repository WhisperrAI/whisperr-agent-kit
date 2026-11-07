import 'package:flutter/material.dart';

import 'learn_tab.dart';
import 'profile_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: const [LearnTab(), ProfileTab()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(key: Key('tab-learn'), icon: Icon(Icons.school_outlined), label: 'Learn'),
          NavigationDestination(key: Key('tab-profile'), icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
