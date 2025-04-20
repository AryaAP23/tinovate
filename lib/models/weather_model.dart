// weather_model.dart
// class Weather {
//   final String weather_desc;
//   final double local_datetime;

//   Weather({
//     required this.weather_desc,
//     required this.local_datetime,
//   });

//   factory Weather.fromJson(Map<String, dynamic> json) {
//     return Weather(
//       weather_desc: json['weather_desc'] ?? 'Tidak diketahui',
//       local_datetime: json['local_datetime'] ?? '',
//     );
//   }
// }

class Weather {
  final String description;
  final String icon;
  final double temperature;
  final String time;
  // final int humidity;

  Weather({
    required this.description,
    required this.icon,
    required this.temperature,
    required this.time,
    // required this.humidity,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      description: json['weather_desc'] ?? 'Tidak diketahui',
      icon: json['image'] ?? '',
      temperature: (json['t'] as num).toDouble(),
      time: json['local_datetime'] ?? '',
      // humidity: json['hu'] ?? 0,
    );
  }
}
