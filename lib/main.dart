import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: DashboardView(title: 'Flutter Demo Home Page'),
    );
  }
}

class DashboardView extends StatefulWidget {
  DashboardView({super.key, required this.title});

  final String title;
  final String datetime =
      DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

// class _MyHomePageState extends State<MyHomePage> {
class _DashboardViewState extends State<DashboardView> {
  String weatherInfo = "Memuat data cuaca...";
  Weather? currentWeather;
  int soilMoisture = 70; // Dummy, nanti dari IoT
  bool isIrrigationOn = false;
  bool isLoading = true;
  bool isOn = false; // status tombol, default OFF
  List<double> soilMoistureData = [60, 62, 63, 65, 68, 65, 63];
  final DateTime now = DateTime.now();
  final String datetime =
      DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());

  void toggleButton() {
    setState(() {
      isOn = !isOn; // Toggle status
    });
  }

  @override
  void initState() {
    super.initState();
    getWeather();
  }

  void getWeather() async {
    try {
      // print("Memulai fetch cuaca...");
      final weatherService = WeatherService();
      final data = await weatherService.fetchWeather();
      // print("Data diterima: $data");

      if (data.isNotEmpty) {
        final current = data[0];
        setState(() {
          currentWeather = current;
          weatherInfo =
              "Cuaca: ${current.description}\nSuhu: ${current.description}°C\nJam: ${current.time}";
          isLoading = false;
        });
      } else {
        setState(() {
          weatherInfo = "Tidak ada data cuaca tersedia.";
          isLoading = false;
        });
      }
    } catch (e) {
      // print("Terjadi error saat ambil data: $e");
      setState(() {
        weatherInfo = "Gagal mendapatkan data cuaca: $e";
        isLoading = false;
      });
    }
  }

  void toggleIrrigation() {
    setState(() {
      isIrrigationOn = !isIrrigationOn;
      // TODO: kirim status ke IoT
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xff4A6B3E),
        title: Text(
          "Dashboard",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text(
                    'Kelembaban Tanah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                    ''); // Kosongkan jika tidak ingin label bawah
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%');
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: soilMoistureData
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    color: Color(0xffCFEBC1),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 2.0, 16.0,
                          16.0), // kiri = 0, atas = 16, kanan = 16, bawah = 16
                      child: Column(
                        children: [
                          // Tabel pertama
                          Table(
                            // border: TableBorder.all(),
                            columnWidths: {
                              0: FixedColumnWidth(50.0),
                              1: FixedColumnWidth(80.0),
                            },
                            children: [
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 2.0),
                                  child: currentWeather?.icon != null
                                      ? SvgPicture.network(
                                          currentWeather!.icon,
                                          width: 60,
                                          height: 60,
                                          placeholderBuilder: (context) =>
                                              CircularProgressIndicator(), // opsional
                                        )
                                      : Text('No icon'), // fallback jika null
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.only(left: 5.0, top: 15.0),
                                  child: Text(
                                    currentWeather?.temperature != null
                                        ? '${currentWeather!.temperature.toStringAsFixed(1)} °C'
                                        : '-',
                                    style: TextStyle(
                                        fontSize: 18, fontFamily: 'Poppins'),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ]),
                            ],
                          ),

                          // Tabel kedua
                          Table(
                            // border: TableBorder.all(),
                            columnWidths: {
                              0: FixedColumnWidth(150.0),
                              1: FixedColumnWidth(150.0),
                            },
                            children: [
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 16.0),
                                  child: Text(
                                    currentWeather?.description ?? '-',
                                    style: TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'),
                                    textAlign: TextAlign.left,
                                  ),
                                )
                              ]),
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 16.0),
                                  child: Text(
                                    datetime,
                                    style: TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'),
                                    textAlign: TextAlign.left,
                                  ),
                                )
                              ])
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: InkWell(
                      onTap: toggleButton,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: isOn ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            isOn ? 'ON' : 'OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
