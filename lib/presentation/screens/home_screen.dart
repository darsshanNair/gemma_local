import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemma_local/core/di/di_container.dart';
import 'package:gemma_local/core/services/i_todo_repository.dart';
import 'package:gemma_local/core/utilities/constants/app_strings.dart';
import 'package:gemma_local/presentation/theme/app_colors.dart';
import 'package:gemma_local/presentation/screens/chat_screen.dart';
import 'package:gemma_local/presentation/screens/todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    ChatScreen(),
    TodoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepositoryProvider<ITodoRepository>.value(
        value: serviceLocator<ITodoRepository>(),
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: AppStrings.chatTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            activeIcon: Icon(Icons.checklist),
            label: AppStrings.todosTab,
          ),
        ],
      ),
    );
  }
}
