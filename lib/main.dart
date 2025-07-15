import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lossjztnhdpcghpyaayd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxvc3NqenRuaGRwY2docHlhYXlkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2MDcxNTIsImV4cCI6MjA2ODE4MzE1Mn0.WO9NwY6buQJtyWp-panMHz700B5lvaULH4J2d72qfj4',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro Visitantes',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
