import "dart:convert";
import "dart:ui";
import 'package:http/http.dart' as http;
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:weather_app/secrets.dart";
import 'package:google_generative_ai/google_generative_ai.dart'; // Import Gemini API

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<String> outfitSuggestion;

  @override
  void initState() {
    super.initState();
    getWeather();
  }

  Future<Map<String, dynamic>> getWeather() async {
    try {
      String cityName = "Chennai";
      final res = await http.get(
        Uri.parse(
          "https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIKey",
        ),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw "An Unexpected Error Occured";
      }

      final currentTemp = data['list'][0]['main']['temp'];
      outfitSuggestion = generateOutfit(currentTemp);

      return data;
      //temp = data['list'][0]['main']['temp'];
    } catch (e) {
      throw e.toString();
    }
  }

  Future<String> generateOutfit(double temperature) async {
    try {
      
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: geminiAPIKey,
      );

      final prompt =
          'Suggest an outfit for a day with a temperature of $temperature K.';
      final response = await model.generateContent([Content.text(prompt)]);

      return response.text ?? 'Failed to generate outfit suggestion';
    } catch (e) {
      return 'Error: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weather App",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder(
          future: getWeather(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }

            final data = snapshot.data!;
            final currentWeather = data['list'][0];
            final currentTemp = currentWeather['main']['temp'];
            final currentSky = currentWeather['weather'][0]['main'];
            final currentPressure = currentWeather['main']['pressure'];
            final currentHumidity = currentWeather['main']['humidity'];
            final currentWind = currentWeather['wind']['speed'];
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  "$currentTemp K",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Icon(
                                  currentSky == "Clouds" || currentSky == "Rain"
                                      ? Icons.cloud
                                      : Icons.sunny,
                                  size: 64,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  currentSky,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Hourly Forecast",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 8),
                  // const SingleChildScrollView(
                  //   scrollDirection: Axis.horizontal,
                  //   child: Row(
                  //     children: [
                  //       HourlyWeatherCard(
                  //           time: "4:00", icon: Icons.thunderstorm, temp: "300"),
                  //       HourlyWeatherCard(
                  //           time: "5:00", icon: Icons.thunderstorm, temp: "300"),
                  //       HourlyWeatherCard(
                  //           time: "6:00", icon: Icons.cloud, temp: "310"),
                  //       HourlyWeatherCard(
                  //           time: "7:00", icon: Icons.cloud, temp: "315"),
                  //       HourlyWeatherCard(
                  //           time: "8:00", icon: Icons.sunny, temp: "320"),
                  //       HourlyWeatherCard(
                  //           time: "9:00", icon: Icons.sunny, temp: "320"),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                        itemCount: 5,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final hourlyForecast = data['list'][index + 1];
                          final hourlySky =
                              hourlyForecast['weather'][0]['main'];
                          final hourlyTemp =
                              hourlyForecast['main']['temp'].toString();
                          final time = DateTime.parse(hourlyForecast['dt_txt']);
                          return HourlyWeatherCard(
                            time: DateFormat.j().format(time),
                            icon: hourlySky == "Clouds" || hourlySky == "Rain"
                                ? Icons.cloud
                                : Icons.sunny,
                            temp: hourlyTemp,
                          );
                        }),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Additional Information",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AddiInfo(
                        icon: Icons.water_drop,
                        label: "Humidity",
                        value: currentHumidity.toString(),
                      ),
                      AddiInfo(
                        icon: Icons.air,
                        label: "Wind Speed",
                        value: currentWind.toString(),
                      ),
                      AddiInfo(
                        icon: Icons.beach_access,
                        label: "Pressure",
                        value: currentPressure.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Outfit Recommendation",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder(
                    future: outfitSuggestion,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      return Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            snapshot.data ?? 'No outfit suggestion generated',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddiInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AddiInfo({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300)),
      ],
    );
  }
}

class HourlyWeatherCard extends StatelessWidget {
  final IconData icon;
  final String time;
  final String temp;

  const HourlyWeatherCard({
    super.key,
    required this.time,
    required this.icon,
    required this.temp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(
              time,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Icon(
              icon,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              temp,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }
}
