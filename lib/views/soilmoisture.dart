import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SoilMoisturePage extends StatefulWidget {
  const SoilMoisturePage({super.key});

  @override
  State<SoilMoisturePage> createState() => _SoilMoisturePageState();
}

class _SoilMoisturePageState extends State<SoilMoisturePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> moistureHistory = [];
  int? minValue;
  int? maxValue;

  final minController = TextEditingController();
  final maxController = TextEditingController();

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now(); // default hari ini
    fetchData();
  }

  Future<void> fetchData() async {
    final history = await supabase
        .from('data_kelembapan_tanah')
        .select()
        .order('date', ascending: false)
        .order('time', ascending: false);

    final config = await supabase
        .from('parameter_kelembapan')
        .select()
        .eq('parameter_id', 1)
        .single();

    setState(() {
      moistureHistory = history;
      minValue = config['lower_limit'];
      maxValue = config['upper_limit'];
      minController.text = minValue.toString();
      maxController.text = maxValue.toString();
    });
  }

  Future<void> updateConfig() async {
    final min = int.tryParse(minController.text);
    final max = int.tryParse(maxController.text);

    if (min == null || max == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Masukkan angka yang valid untuk minimum dan maksimum')),
      );
      return;
    }

    if (min >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Nilai minimum harus lebih kecil dari maksimum')),
      );
      return;
    }

    final result = await supabase
        .from('parameter_kelembapan')
        .update({
          'lower_limit': min,
          'upper_limit': max,
        })
        .eq('parameter_id', 1)
        .select(); // untuk melihat hasil update

    // print("Hasil update: $result");

    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Gagal memperbarui parameter! Baris tidak ditemukan')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batas kelembapan diperbarui!')),
      );
      fetchData();
    }
  }

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = selectedDate == null
        ? moistureHistory
        : moistureHistory.where((entry) {
            final date = DateTime.parse(entry['date']);
            return date.year == selectedDate!.year &&
                date.month == selectedDate!.month &&
                date.day == selectedDate!.day;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelembapan',
          style: TextStyle(
              color: Color(0xffffffff),
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 28),
        ),
        backgroundColor: Color(0xff4A6B3E),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text("Parameter Kelembapan",
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          TextFormField(
            controller: minController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nilai Minimum (%)',
              labelStyle: TextStyle(fontFamily: 'Outfit'),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: maxController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nilai Maksimum (%)',
              labelStyle: TextStyle(fontFamily: 'Outfit'),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: updateConfig,
            child: Text(
              'Perbarui Parameter',
              style: TextStyle(fontFamily: 'Outfit', color: Color(0xff000000)),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          SizedBox(height: 20),
          Text("Riwayat Kelembapan Tanah",
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: pickDate,
            icon: Icon(Icons.calendar_today),
            label: Text(
              selectedDate != null
                  ? 'Tanggal: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                  : 'Pilih Tanggal',
              style: TextStyle(fontFamily: 'Outfit', color: Color(0xff000000)),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          SizedBox(height: 10),
          if (filteredHistory.isEmpty)
            Center(
                child: Text(
              "Tidak ada data pada tanggal ini.",
              style: TextStyle(fontFamily: 'Outfit'),
            )),
          ...filteredHistory.map((entry) {
            final date = DateTime.parse(entry['date']);
            final timeString = entry['time'];
            final fullDateTime = DateTime.parse('${entry['date']}T$timeString');

            final formatted = '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/'
                '${date.year} | '
                '${fullDateTime.hour.toString().padLeft(2, '0')}:'
                '${fullDateTime.minute.toString().padLeft(2, '0')}';

            return Card(
              color: Color(0xffCFEBC1),
              child: ListTile(
                leading: Icon(Icons.water_drop, color: Colors.blue),
                title: Text(
                  "Kelembapan: ${entry['humidity']}%",
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                subtitle: Text(
                  "Waktu: $formatted",
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
