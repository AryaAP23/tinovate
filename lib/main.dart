//-----------------------------------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'views/dashboard.dart';
import 'views/Login.dart';
import 'views/flush.dart';
import 'views/profile.dart';
import 'views/soilmoisture.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinovate/views/updateuser.dart';
import 'services/mqtt_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: 'https://hfpkqozilsjngeksohzl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmcGtxb3ppbHNqbmdla3NvaHpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5MjY5NzYsImV4cCI6MjA2MTUwMjk3Nn0.vb8nAkfsLmbfT2yrJl6uwgayKv7nP_ZNH9w5rlivjXY',
  );
  await MQTTService().connect();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      title: 'Smart Farm App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: session != null ? '/home' : '/login',
      routes: {
        '/login': (context) => Login(),
        '/home': (context) => MainPage(),
        '/updateuser': (context) => const UpdateUser(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    DashboardView(),
    SoilMoisturePage(),
    FlushPage(),
    ProfileView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Beranda',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.eco), label: 'KeTa'),
    BottomNavigationBarItem(icon: Icon(Icons.opacity), label: 'Penyiraman'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xff4A6B3E),
        unselectedItemColor: Color(0xffD2CBCB),
        onTap: _onItemTapped,
        selectedLabelStyle:
            TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
        items: _navItems,
      ),
    );
  }
}
