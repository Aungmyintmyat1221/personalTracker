import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  final List<Widget> _pages = [
    DashboardView(),
    TasksView(),
    ScheduleView(),
    MoneyView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Schedule"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: "Money"),
        ],
      ),
    );
  }
}
