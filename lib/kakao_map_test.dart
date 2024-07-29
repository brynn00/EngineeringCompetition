import 'package:flutter/material.dart';
import 'package:kakaomap_webview/kakaomap_webview.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'map_screen.dart';

final String kakaoMapKey = dotenv.env['KAKAO_MAP_KEY']!;
final String kakaoRestApiKey = dotenv.env['KAKAO_REST_API_KEY']!;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kakao Map Multi Locations Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: KakaoMapTest(),
    );
  }
}

class KakaoMapTest extends StatefulWidget {
  @override
  _KakaoMapTestState createState() => _KakaoMapTestState();
}

class _KakaoMapTestState extends State<KakaoMapTest> {
  List<TextEditingController> locationControllers = [TextEditingController()];
  List<List<Map<String, dynamic>>> searchResults = [[]];
  List<int> selectedIndices = [-1];
  List<Map<String, dynamic>> locations = [];
  double centerLat = 0, centerLng = 0;
  String centerAddress = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('여러 장소 지도 표시')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < locationControllers.length; i++) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: locationControllers[i],
                        decoration: InputDecoration(labelText: '장소 ${i + 1}'),
                      ),
                    ),
                    if (locationControllers.length > 1)
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            locationControllers.removeAt(i);
                            searchResults.removeAt(i);
                            selectedIndices.removeAt(i);
                          });
                        },
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                child: Text('장소 ${i + 1} 검색'),
                onPressed: isLoading
                    ? null
                    : () async {
                        await searchLocation(i);
                      },
              ),
              if (searchResults[i].isNotEmpty && selectedIndices[i] == -1)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResults[i].length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(searchResults[i][index]['place_name']),
                      subtitle: Text(searchResults[i][index]['address_name']),
                      onTap: () {
                        setState(() {
                          selectedIndices[i] = index;
                        });
                      },
                    );
                  },
                ),
            ],
            ElevatedButton(
              child: Text('인원 추가'),
              onPressed: () {
                setState(() {
                  locationControllers.add(TextEditingController());
                  searchResults.add([]);
                  selectedIndices.add(-1);
                });
              },
            ),
            ElevatedButton(
              child: Text('지도 표시'),
              onPressed: selectedIndices.contains(-1)
                  ? null
                  : () async {
                      await displayMap();
                    },
            ),
            if (isLoading)
              CircularProgressIndicator()
            else
              Center(child: Text('장소를 검색하세요')),
          ],
        ),
      ),
    );
  }

  Future<void> searchLocation(int locationIndex) async {
    setState(() {
      isLoading = true;
      searchResults[locationIndex].clear();
      selectedIndices[locationIndex] = -1;
    });

    try {
      final results =
          await getCoordinates(locationControllers[locationIndex].text);
      setState(() {
        searchResults[locationIndex] = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소를 찾는 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> displayMap() async {
    setState(() {
      isLoading = true;
      locations.clear();
    });

    try {
      List<double> lats = [];
      List<double> lngs = [];
      for (int i = 0; i < selectedIndices.length; i++) {
        final location = searchResults[i][selectedIndices[i]];
        lats.add(double.parse(location['y']));
        lngs.add(double.parse(location['x']));
        locations.add({
          'name': '장소${i + 1}',
          'x': double.parse(location['x']),
          'y': double.parse(location['y'])
        });
      }
      centerLat = lats.reduce((a, b) => a + b) / lats.length;
      centerLng = lngs.reduce((a, b) => a + b) / lngs.length;

      centerAddress = await getAddress(centerLat, centerLng);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            locations: locations,
            centerLat: centerLat,
            centerLng: centerLng,
            centerAddress: centerAddress,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('지도 표시 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCoordinates(String keyword) async {
    final response = await http.get(
      Uri.parse(
          'https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword'),
      headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['documents'].isNotEmpty) {
        return List<Map<String, dynamic>>.from(data['documents']);
      }
    }
    throw Exception('주소를 찾을 수 없습니다');
  }

  Future<String> getAddress(double lat, double lng) async {
    final response = await http.get(
      Uri.parse(
          'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat'),
      headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['documents'].isNotEmpty) {
        return data['documents'][0]['address']['address_name'];
      }
    }
    throw Exception('주소를 찾을 수 없습니다');
  }
}
