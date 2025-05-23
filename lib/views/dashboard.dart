// dashboard.dart
import 'package:flutter/material.dart';
import '../../services/weather_service.dart';
import '../../models/weather_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:intl/date_symbol_data_local.dart';

class DashboardView extends StatefulWidget {
  DashboardView({super.key});
  final String datetime =
      DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final supabase = Supabase.instance.client;
  String weatherInfo = "Memuat data cuaca...";
  bool? isAutoIrrigationOn;
  bool? isManualIrrigationOn;
  Weather? currentWeather;
  bool isIrrigationOn = false;
  bool isLoading = true;
  bool isOn = false; // status tombol, default OFF
  List<Map<String, dynamic>> latestSoilMoistureData = [];
  final DateTime now = DateTime.now();
  final String datetime =
      DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());

  Future<void> fetchIrrigationStatus() async {
    // final supabase = Supabase.instance.client;

    final manualData = await supabase
        .from('data_kelembapan_tanah')
        .select('status')
        .order('date', ascending: false)
        .order('time', ascending: false)
        .limit(1)
        .maybeSingle();

    final autoData =
        await supabase.from('button_auto').select('status').maybeSingle();

    setState(() {
      isManualIrrigationOn = manualData?['status'];
      isAutoIrrigationOn = autoData?['status'];
    });
    // print('status dalam database: $manualData');
    // print('status penyiraman manual $isManualIrrigationOn');
    // print('status dalam database auto_button: $autoData');
    // print('Status Penyiraman Otomatis: $isAutoIrrigationOn');
  }

  Future<void> fetchDataKelembapan() async {
    // final supabase = Supabase.instance.client;
    final response = await supabase
        .from('data_kelembapan_tanah')
        .select()
        .order('date', ascending: false)
        .order('time', ascending: false)
        .limit(10);
    setState(() {
      latestSoilMoistureData = response.reversed.toList();
    });
  }

  Future<void> toggleManualIrrigation() async {
    final supabase = Supabase.instance.client;

    if (isManualIrrigationOn == null) {
      print('Status manual irrigation belum diinisialisasi.');
      return;
    }
    final newStatus = !isManualIrrigationOn!;
    try {
      if (isAutoIrrigationOn != null) {
        final latestButton = await supabase
            .from('button_auto')
            .select('status_id')
            .order('status_id', ascending: false)
            .limit(1)
            .single();

        await supabase.from('button_auto').update({
          'status': false,
        }).eq('status_id', latestButton['status_id']);
      }

      final latestHumidity = await supabase
          .from('data_kelembapan_tanah')
          .select('*')
          .order('id', ascending: false)
          .limit(1)
          .single();

      // print('Latest humidity data: $latestHumidity');
      // print('Status lama: ${latestHumidity['status']}');
      // print('status baru:');
      // print(newStatus);
      // print('ID data: ${latestHumidity['id']}');
      await supabase.from('data_kelembapan_tanah').update({
        'status': newStatus,
      }).eq('id', latestHumidity['id']);
      print('Status berhasil diperbarui.');

      await fetchIrrigationStatus();
    } catch (e) {
      print('Terjadi error saat update: $e');
    }
  }

  void toggleButton() {
    setState(() {
      isOn = !isOn; // Toggle status
    });
  }

  @override
  void initState() {
    super.initState();
    fetchIrrigationStatus();
    fetchDataKelembapan();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // tinggi appbar
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            color: Color(0xff4A6B3E), // warna latar belakang
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Kiri: 2 Teks
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hai sahabat tani!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Semoga harimu cerah',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Kanan: Foto Profil
                CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage(
                      'assets/images/profil.png'), // ganti path sesuai foto kamu
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SizedBox(height: 10),
                  Text(
                    'Kelembapan Tanah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 230,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < latestSoilMoistureData.length) {
                                  final rawTime =
                                      latestSoilMoistureData[index]['time'];
                                  final parsedTime = DateFormat.Hms()
                                      .parse(rawTime); // parsing dari HH:mm:ss
                                  final label = DateFormat.Hm()
                                      .format(parsedTime); // format jadi HH:mm
                                  return Text(label,
                                      style: TextStyle(fontSize: 10));
                                }
                                return Text('');
                              },
                              interval: 1,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                            spots: List.generate(
                              latestSoilMoistureData.length,
                              (index) {
                                final kelembapan = latestSoilMoistureData[index]
                                        ['humidity'] ??
                                    0;
                                return FlSpot(
                                    index.toDouble(), kelembapan.toDouble());
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Card(
                    color: Color(0xffCFEBC1),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 2.0, 16.0,
                          16.0), // kiri = 0, atas = 16, kanan = 16, bawah = 16
                      child: Column(
                        children: [
                          //Tabel pertama
                          Table(
                            // border: TableBorder.all(),
                            columnWidths: {
                              0: FixedColumnWidth(180.0),
                              1: FixedColumnWidth(80.0),
                            },
                            children: [
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 1.0, top: 10),
                                  child: Text(
                                    datetime,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Outfit',
                                        color: Color(0xff4A6B3E)),
                                    textAlign: TextAlign.left,
                                  ),
                                )
                              ])
                            ],
                          ),

                          //Tabel kedua
                          Table(
                            // border: TableBorder.all(),
                            columnWidths: {
                              0: FixedColumnWidth(140.0),
                              1: FixedColumnWidth(80.0),
                            },
                            children: [
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 5.0),
                                  child: Text(
                                    currentWeather?.temperature != null
                                        ? '${currentWeather!.temperature.toStringAsFixed(1)} °'
                                        : '-',
                                    style: TextStyle(
                                        fontSize: 45,
                                        fontFamily: 'Outfit-bold',
                                        color: Color(0xff4A6B3E)),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 0.0),
                                  child: currentWeather?.icon != null
                                      ? SvgPicture.network(
                                          currentWeather!.icon,
                                          width: 60,
                                          height: 60,
                                          placeholderBuilder: (context) =>
                                              CircularProgressIndicator(), // opsional
                                        )
                                      : Text(
                                          'No icon',
                                          style: TextStyle(
                                              fontFamily: 'Outfit',
                                              color: Color(0xff4A6B3E)),
                                        ), // fallback jika null
                                ),
                              ]),
                            ],
                          ),

                          // Tabel ketiga
                          Table(
                            // border: TableBorder.all(),
                            columnWidths: {
                              0: FixedColumnWidth(200.0),
                              1: FixedColumnWidth(150.0),
                            },
                            children: [
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 18.0),
                                  child: Text(
                                    currentWeather?.description ?? '-',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Outfit',
                                        color: Color(0xff4A6B3E)),
                                    textAlign: TextAlign.left,
                                  ),
                                )
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Card(
                    color: Color(0xffCFEBC1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Penyiraman:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff4A6B3E),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            isManualIrrigationOn == null
                                ? 'Memuat...'
                                : isManualIrrigationOn!
                                    ? 'Aktif'
                                    : 'Tidak Aktif',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Penyiraman Otomatis:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff4A6B3E),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            isAutoIrrigationOn == null
                                ? 'Memuat...'
                                : isAutoIrrigationOn!
                                    ? 'Aktif'
                                    : 'Tidak Aktif',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (isManualIrrigationOn ?? false)
                                    ? Colors.green
                                    : Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                              ),
                              onPressed: toggleManualIrrigation,
                              child: Text(
                                (isManualIrrigationOn ?? false)
                                    ? 'Matikan Penyiraman'
                                    : 'Hidupkan Penyiraman',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
