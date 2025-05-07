import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FlushPage extends StatefulWidget {
  const FlushPage({Key? key}) : super(key: key);

  @override
  State<FlushPage> createState() => _FlushPageState();
}

class _FlushPageState extends State<FlushPage> {
  final supabase = Supabase.instance.client;
  bool? isManualOn;
  bool? isAutoOn;
  DateTime? selectedDate;

  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    fetchCurrentStatus();
    fetchHistory();
  }

  Future<void> fetchCurrentStatus() async {
    // Ambil status manual dari tabel data_kelembapan_tanah
    final manualResponse = await supabase
        .from('data_kelembapan_tanah')
        .select('status')
        .order('date', ascending: false)
        .order('time', ascending: false)
        .limit(1)
        .maybeSingle();

    // Ambil status auto dari tabel button_auto
    final autoResponse = await supabase
        .from('button_auto')
        .select('status')
        .eq('status_id', 1)
        .single();

    setState(() {
      isManualOn = manualResponse?['status'];
      isAutoOn = autoResponse['status'];
    });
  }

  Future<void> toggleManual(bool newValue) async {
    final newValue = !isManualOn!;
    final latestHumidity = await supabase
        .from('data_kelembapan_tanah')
        .select('*')
        .order('id', ascending: false)
        .limit(1)
        .single();
    print('latest humidity data: $latestHumidity');
    print(newValue);
    print('ID data: ${latestHumidity['id']}');
    print(isManualOn);
    await supabase.from('data_kelembapan_tanah').update({
      'status': newValue,
    }).eq('id', latestHumidity['id']);
    print('Status berhasil diperbarui.');
    setState(() {
      isManualOn = newValue;
    });
  }

  Future<void> toggleAuto(bool newValue) async {
    await supabase
        .from('button_auto')
        .update({'status': newValue}).eq('status_id', 1);

    setState(() {
      isAutoOn = newValue;
    });
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      await fetchHistory(); // refresh data berdasarkan tanggal
    }
  }

  Future<void> fetchHistory() async {
    List<Map<String, dynamic>> data;

    if (selectedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      data = await supabase
          .from('data_kelembapan_tanah')
          .select()
          .eq('date', formattedDate)
          .order('time', ascending: true);
    } else {
      data = await supabase
          .from('data_kelembapan_tanah')
          .select()
          .order('date', ascending: true)
          .order('time', ascending: true);
    }

    // final data = await supabase
    //     .from('data_kelembapan_tanah')
    //     .select()
    //     .order('date', ascending: true)
    //     .order('time', ascending: true);

    List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from(data);

    DateTime? currentStart;
    List<Map<String, dynamic>> newHistory = [];

    for (var log in logs) {
      final date = DateTime.parse(log['date']);
      final timeParts = log['time'].split(':');
      final logTime = date.add(Duration(
        hours: int.parse(timeParts[0]),
        minutes: int.parse(timeParts[1]),
        seconds: int.parse(timeParts[2]),
      ));

      final status = log['status'] == true;

      if (status) {
        if (currentStart == null) {
          currentStart = logTime;
        }
      } else {
        if (currentStart != null) {
          newHistory.add({
            'start': currentStart,
            'end': logTime,
            'duration': logTime.difference(currentStart),
          });
          currentStart = null;
        }
      }
    }

    setState(() {
      history = newHistory.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMM yyyy – HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Penyiraman',
          style: TextStyle(
            color: Color(0xffffffff),
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        backgroundColor: Color(0xff4A6B3E),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchCurrentStatus();
          await fetchHistory();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Kontrol Penyiraman',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Penyiraman Manual',
                            style: theme.textTheme.bodyLarge),
                        Switch(
                          value: isManualOn ?? false,
                          onChanged: toggleManual,
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Penyiraman Otomatis',
                            style: theme.textTheme.bodyLarge),
                        Switch(
                          value: isAutoOn ?? false,
                          onChanged: toggleAuto,
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Riwayat Penyiraman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: pickDate,
              icon: Icon(Icons.calendar_today),
              label: Text(
                selectedDate != null
                    ? 'Tanggal: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                    : 'Pilih Tanggal',
                style:
                    TextStyle(fontFamily: 'Outfit', color: Color(0xff000000)),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('Belum ada data penyiraman.'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      title: Text(
                        'Mulai: ${formatter.format(item['start'])}\n'
                        'Selesai: ${formatter.format(item['end'])}',
                      ),
                      subtitle: Text(
                        'Durasi: ${item['duration'].inMinutes} menit',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      leading: const Icon(Icons.water_drop_outlined,
                          color: Colors.blue),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
