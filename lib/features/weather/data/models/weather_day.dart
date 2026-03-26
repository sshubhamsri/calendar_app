class WeatherDay {
  final DateTime date;
  final String iconCode;
  final double tempMin;
  final double tempMax;
  final String description;

  const WeatherDay({
    required this.date,
    required this.iconCode,
    required this.tempMin,
    required this.tempMax,
    required this.description,
  });

  /// Returns the OpenWeatherMap icon URL for this day.
  String get iconUrl =>
      'https://openweathermap.org/img/wn/$iconCode@2x.png';

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'iconCode': iconCode,
        'tempMin': tempMin,
        'tempMax': tempMax,
        'description': description,
      };

  factory WeatherDay.fromJson(Map<String, dynamic> json) => WeatherDay(
        date: DateTime.parse(json['date'] as String),
        iconCode: json['iconCode'] as String,
        tempMin: (json['tempMin'] as num).toDouble(),
        tempMax: (json['tempMax'] as num).toDouble(),
        description: json['description'] as String,
      );

  factory WeatherDay.fromApiEntry(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    return WeatherDay(
      date: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
        isUtc: true,
      ).toLocal(),
      iconCode: weather['icon'] as String,
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      description: weather['description'] as String,
    );
  }
}
