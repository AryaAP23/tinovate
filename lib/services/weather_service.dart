// weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String apiUrl =
      "https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=35.09.21.1004";

  // Future<Weather> fetchWeather() async {
  //   final response = await http.get(Uri.parse(apiUrl));

  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     final weatherJson = data['data'][0]['cuaca'][0]; // Ambil cuaca pertama
  //     return Weather.fromJson(weatherJson);
  //   } else {
  //     throw Exception("Gagal mengambil data cuaca");
  //   }
  // }

  // Future<Weather> fetchWeather() async {
  //   final response = await http.get(Uri.parse(apiUrl));

  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);

  //     // Cetak semua isi data
  //     print("=== DATA API BMKG ===");
  //     print(data);

  //     final weatherJson = data['data'][0]['cuaca'][0];

  //     // Cetak isi cuaca pertama
  //     print("=== cuaca[0] ===");
  //     print(weatherJson);

  //     return Weather.fromJson(weatherJson);
  //   } else {
  //     throw Exception("Gagal mengambil data cuaca");
  //   }
  // }

  Future<List<Weather>> fetchWeather() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final List<dynamic> forecastList = data['data'][0]['cuaca'][0];

      return forecastList.map((item) => Weather.fromJson(item)).toList();
    } else {
      throw Exception("Gagal mengambil data cuaca");
    }
  }
}
