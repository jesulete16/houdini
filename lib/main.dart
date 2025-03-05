import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zqujsggupafmmtyqyemu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxdWpzZ2d1cGFmbW10eXF5ZW11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzOTk3MzAsImV4cCI6MjA1NTk3NTczMH0.PLg3iqtpmQ512LMQJttIZXaR0w-3MdrOo60C862odRw', // Reemplaza con tu clave anónima correcta
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
