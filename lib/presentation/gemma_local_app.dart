import 'package:flutter/material.dart';
import 'package:gemma_local/presentation/screens/chat_screen.dart';

class GemmaLocalApp extends StatelessWidget {
  const GemmaLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma Local',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const ChatScreen(title: 'Gemma AI Assistant'),
    );
  }
}
