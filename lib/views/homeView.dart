import 'package:flutter/material.dart';
import 'package:tracker/views/aiView.dart';
import 'package:tracker/views/routineView.dart';
import 'package:tracker/views/taskView.dart';

import 'dashboardView.dart';
import 'moneyView.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    DashboardView(),
    TasksView(),
    RoutineView(),
    MoneyView(),
    const AiView(),
    // const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 72,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: "Tasks",
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: "Routine",
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: "Money",
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: "AI",
          ),
          // NavigationDestination(
          //   icon: Icon(Icons.settings_outlined),
          //   selectedIcon: Icon(Icons.settings),
          //   label: "Settings",
          // ),
        ],
      ),
    );
  }
}
