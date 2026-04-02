import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'admin_screen.dart';

class HomeDashboard extends StatefulWidget {
  final bool isAdmin;
  const HomeDashboard({Key? key, required this.isAdmin}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    
    final List<Widget> screens = [
      const ChatScreen(),
      const Scaffold(body: Center(child: Text('Chat History Placeholder'))),
      const Scaffold(body: Center(child: Text('Settings Placeholder'))),
    ];

    if (widget.isAdmin) {
      screens.add(const AdminScreen());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SchoolHub Dashboard'),
        centerTitle: true,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat Assistant'),
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          if (widget.isAdmin)
            const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}
