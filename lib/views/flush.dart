import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/mqtt_service.dart';

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
    // fetchCurrentStatus();
    fetchHistory();
  }

  // Future<void> fetchCurrentStatus() async {
  //   // Ambil status manual dari tabel data_kelembapan_tanah
  //   final manualResponse = await supabase
  //       .from('data_kelembapan_tanah')
  //       .select('status')
  //       .order('date', ascending: false)
  //       .order('time', ascending: false)
  //       .limit(1)
  //       .maybeSingle();

  //   // Ambil status auto dari tabel penyiraman_otomatis
  //   final autoResponse = await supabase
  //       .from('penyiraman_otomatis')
  //       .select('status')
  //       .eq('status_id', 1)
  //       .single();

  //   setState(() {
  //     isManualOn = manualResponse?['status'];
  //     isAutoOn = autoResponse['status'];
  //   });
  // }

  // Future<void> toggleManual(bool newValue) async {
  //   final action = !(isManualOn ?? false);
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: Color(0xffCFEBC1),
  //       title: Text(action
  //           ? 'Aktifkan Penyiraman Manual'
  //           : 'Nonaktifkan Penyiraman Manual'),
  //       titleTextStyle: TextStyle(
  //           fontFamily: 'Outfit', color: Color(0xff000000), fontSize: 20.0),
  //       content: Text(
  //         'Apakah kamu yakin ingin ${action ? 'menghidupkan' : 'mematikan'} penyiraman manual?',
  //       ),
  //       contentTextStyle:
  //           TextStyle(fontFamily: 'Outfit', color: Color(0xff000000)),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Batal'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('Ya'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirm != true) return;
  //   final latestHumidity = await supabase
  //       .from('data_kelembapan_tanah')
  //       .select('*')
  //       .order('id', ascending: false)
  //       .limit(1)
  //       .single();

  //   await supabase.from('data_kelembapan_tanah').update({
  //     'status': action,
  //   }).eq('id', latestHumidity['id']);

  //   MQTTService().publishToMQTT(
  //     topic: 'tinovate/getStatusSiram',
  //     message: '{"status": $action}',
  //   );

  //   setState(() {
  //     isManualOn = action;
  //   });
  // }
  Future<void> toggleManual(bool newValue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xffCFEBC1),
        title: Text(newValue
            ? 'Aktifkan Penyiraman Manual'
            : 'Nonaktifkan Penyiraman Manual'),
        titleTextStyle: TextStyle(
            fontFamily: 'Outfit', color: Color(0xff000000), fontSize: 20.0),
        content: Text(
          'Apakah kamu yakin ingin ${newValue ? 'menghidupkan' : 'mematikan'} penyiraman manual?',
        ),
        contentTextStyle:
            TextStyle(fontFamily: 'Outfit', color: Color(0xff000000)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final latestHumidity = await supabase
        .from('data_kelembapan_tanah')
        .select('*')
        .order('id', ascending: false)
        .limit(1)
        .single();

    await supabase.from('data_kelembapan_tanah').update({
      'status': newValue, // ✅ langsung pakai newValue
    }).eq('id', latestHumidity['id']);

    MQTTService().publishToMQTT(
      topic: 'tinovate/getStatusSiram',
      message: '{"status": $newValue}',
    );

    // ❌ Hapus setState manual, karena StreamBuilder akan update otomatis
  }

  Future<void> toggleAuto(bool newValue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xffCFEBC1),
        title: Text(newValue
            ? 'Aktifkan Penyiraman Otomatis'
            : 'Nonaktifkan Penyiraman Otomatis'),
        titleTextStyle: TextStyle(
            fontFamily: 'Outfit', color: Color(0xff000000), fontSize: 20.0),
        content: Text(
          'Apakah kamu yakin ingin ${newValue ? 'menghidupkan' : 'mematikan'} penyiraman otomatis?',
        ),
        contentTextStyle:
            TextStyle(fontFamily: 'Outfit', color: Color(0xff000000)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await supabase
        .from('penyiraman_otomatis')
        .update({'status': newValue}).eq('status_id', 1);

    MQTTService().publishToMQTT(
      topic: 'tinovate/getStatusAuto',
      message: '{"status": $newValue}',
    );

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
    // final theme = Theme.of(context);
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
          // await fetchCurrentStatus();
          await fetchHistory();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: Color(0xffCFEBC1),
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
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text('Penyiraman Manual',
                    //         style: theme.textTheme.bodyLarge),
                    //     Switch(
                    //       value: isManualOn ?? false,
                    //       onChanged: toggleManual,
                    //       activeColor: Colors.green,
                    //     ),
                    //   ],
                    // ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text('Penyiraman Otomatis',
                    //         style: theme.textTheme.bodyLarge),
                    //     Switch(
                    //       value: isAutoOn ?? false,
                    //       onChanged: toggleAuto,
                    //       activeColor: Colors.blue,
                    //     ),
                    //   ],
                    // ),
                    // 🔴 Stream untuk Manual Status
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: Stream.periodic(Duration(seconds: 2))
                          .asyncMap((_) async {
                        final data = await supabase
                            .from('data_kelembapan_tanah')
                            .select('status')
                            .order('date', ascending: false)
                            .order('time', ascending: false)
                            .limit(1)
                            .maybeSingle();

                        return [if (data != null) data];
                      }),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return CircularProgressIndicator();

                        final data = snapshot.data!;
                        final currentStatus =
                            data.isNotEmpty ? data[0]['status'] as bool : false;

                        return SwitchListTile(
                          title: Text('Manual Mode'),
                          value: currentStatus,
                          onChanged: (newValue) {
                            toggleManual(newValue);
                          },
                        );
                      },
                    ),

                    // 🔵 Stream untuk Auto Status
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('penyiraman_otomatis')
                          .stream(primaryKey: ['status_id']).eq('status_id', 1),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return CircularProgressIndicator();
                        final data = snapshot.data!;
                        final currentStatus =
                            data.isNotEmpty ? data[0]['status'] as bool : false;

                        return SwitchListTile(
                          title: Text('Auto Mode'),
                          value: currentStatus,
                          onChanged: (value) {
                            toggleAuto(value);
                          },
                        );
                      },
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
                    color: Color(0xffCFEBC1),
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
                        style: const TextStyle(color: Colors.blue),
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
