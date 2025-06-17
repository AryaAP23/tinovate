import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MQTTService {
  final supabase = Supabase.instance.client;
  static final MQTTService _instance = MQTTService._internal();
  late MqttServerClient client;
  bool _isConnected = false;

  factory MQTTService() {
    return _instance;
  }

  MQTTService._internal() {
    client = MqttServerClient('test.mosquitto.org', 'Tinovate');
    client.port = 1883;
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.logging(on: true);
  }
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      await client.connect();
      _isConnected = true;
      print("✅ MQTT Connected!");
      subscribeTopics();
    } catch (e) {
      print("❌ MQTT connection failed: $e");
      client.disconnect();
    }
  }

  void subscribeTopics() {
    client.subscribe('tinovate/postHumidity', MqttQos.atMostOnce);
    client.subscribe('tinovate/postStatusSiram', MqttQos.atMostOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = c[0].topic;

      print('Received from $topic: $pt');

      if (topic == 'tinovate/postHumidity') {
        insertHumidity(pt);
      } else if (topic == 'tinovate/postStatusSiram') {
        updateStatus(pt);
      }
    });
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  void publishToMQTT({required String topic, required String message}) {
    if (!_isConnected) {
      print("❌ Gagal publish ke $topic: MQTT belum terhubung");
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print("✅ Published to $topic: $message");
  }

  //======== GET DATA FROM DATABASE =========
  Future<Map<String, dynamic>> getLastData() async {
    try {
      final data = await supabase
          .from('data_kelembapan_tanah')
          .select('id, humidity, parameter_id, status')
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) {
        return {
          'id': null,
          'humidity': 1,
          'parameter_id': 1,
          'status': false,
        };
      }

      return {
        'id': data['id'],
        'humidity': data['humidity'] ?? 1,
        'parameter_id': data['parameter_id'] ?? 1,
        'status': data['status'] ?? false,
      };
    } catch (e) {
      print("❌ Gagal ambil data terakhir: $e");
      return {
        'id': null,
        'humidity': 1,
        'parameter_id': 1,
        'status': false,
      };
    }
  }

  //======== INSERT DATA TO DATABASE =========
  Future<void> insertHumidity(String value) async {
    try {
      final lastData = await getLastData();
      final decoded = jsonDecode(value);
      final humidity = decoded['tanah'];
      if (humidity == lastData['humidity']) {
        print("Data humidity sama, tidak dimasukkan ke database.");
        return;
      }

      final now = DateTime.now();
      final date = now.toIso8601String().split('T')[0];
      final time = now.toIso8601String().split('T')[1].split('.')[0];
      final response = await supabase.from('data_kelembapan_tanah').insert({
        'date': date,
        'time': time,
        'humidity': humidity,
        'parameter_id': lastData['parameter_id'],
        'status': lastData['status'],
      });

      print("✅ Insert humidity response: $response");
    } catch (e) {
      print("❌ Gagal kirim data ke Supabase: $e");
    }
  }

  Future<void> updateStatus(String value) async {
    try {
      final lastData = await getLastData();
      final lastId = lastData['id'];
      final decoded = jsonDecode(value);
      final newStatus = decoded['status'];
      final response = await supabase
          .from('data_kelembapan_tanah')
          .update({'status': newStatus}).eq('id', lastId);

      print("✅ Status siram berhasil diupdate: $response");
    } catch (e) {
      print("❌ Gagal update status siram: $e");
    }
  }

  void _onDisconnected() {
    print("🔌 MQTT Disconnected");
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}
