import 'package:flutter/material.dart';
import 'package:kakaomap_webview/kakaomap_webview.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'webview_screen.dart'; // WebViewScreen 클래스 임포트
import 'package:flutter_dotenv/flutter_dotenv.dart';


final String kakaoMapKey = dotenv.env['KAKAO_MAP_KEY']!;
final String openAiApiKey = dotenv.env['OPENAI_API_KEY']!;

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final double centerLat;
  final double centerLng;
  final String centerAddress;

  MapScreen({
    required this.locations,
    required this.centerLat,
    required this.centerLng,
    required this.centerAddress,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<String>> _activitiesFuture;
  List<String> _activities = [];

  @override
  void initState() {
    super.initState();
    _activitiesFuture = getNearbyActivities(widget.centerAddress);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(title: Text('지도')),
      body: Column(
        children: [
          Container(
            height: 400,
            child: KakaoMapView(
              width: size.width,
              height: 400,
              kakaoMapKey: kakaoMapKey,
              lat: widget.centerLat,
              lng: widget.centerLng,
              showMapTypeControl: true,
              showZoomControl: true,
              markerImageURL:
                  'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
              customScript: '''
                var markers = [];
                ${widget.locations.map((loc) => '''
                  var marker = new kakao.maps.Marker({
                    position: new kakao.maps.LatLng(${loc['y']}, ${loc['x']}),
                    map: map
                  });
                  markers.push(marker);
                ''').join()}
                var centerMarker = new kakao.maps.Marker({
                  position: new kakao.maps.LatLng(${widget.centerLat}, ${widget.centerLng}),
                  map: map,
                  image: new kakao.maps.MarkerImage(
                    'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/markerStar.png',
                    new kakao.maps.Size(24, 35)
                  )
                });
                markers.push(centerMarker);
              ''',
              onTapMarker: (message) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('마커 클릭: $message')));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '중간 지점 주소: ${widget.centerAddress}',
              style: TextStyle(fontFamily: 'Cafe24Supermagic'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _activitiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('주변 놀거리를 찾을 수 없습니다.'));
                } else {
                  _activities = snapshot.data!;
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          snapshot.data![index],
                          style: TextStyle(fontFamily: 'Cafe24Supermagic'),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _activities.isNotEmpty ? _generatePlan : null,
                child: Text('계획 짜기', style: TextStyle(fontFamily: 'Cafe24Supermagic')),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final url = 'https://map.kakao.com/link/map/${widget.centerLat},${widget.centerLng}';
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WebViewScreen(url: url)),
                  );
                },
                child: Text('길찾기', style: TextStyle(fontFamily: 'Cafe24Supermagic')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generatePlan() async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAiApiKey',
      };
      final prompt = '다음 놀거리를 바탕으로 하루 계획을 짜줘: \n' + _activities.join('\n');
      final body = json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 300,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final plan = data['choices'][0]['message']['content'] as String;
        _showPlanDialog(plan);
      } else {
        throw Exception('Failed to get response from OpenAI API');
      }
    } catch (e) {
      throw Exception('Failed to get response from OpenAI API');
    }
  }

  void _showPlanDialog(String plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('생성된 계획', style: TextStyle(fontFamily: 'Cafe24Supermagic')),
          content: SingleChildScrollView(
            child: Text(plan, style: TextStyle(fontFamily: 'Cafe24Supermagic')),
          ),
          actions: [
            TextButton(
              child: Text('확인', style: TextStyle(fontFamily: 'Cafe24Supermagic')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> getNearbyActivities(String address) async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAiApiKey',
      };
      final body = json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': '이 주소 근처에 있는 놀거리를 나열해줘: $address.'}
        ],
        'max_tokens': 150,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final text = data['choices'][0]['message']['content'] as String;
        setState(() {
          _activities = text
              .split('\n')
              .where((element) => element.trim().isNotEmpty)
              .toList();
        });
        return _activities;
      } else {
        throw Exception('Failed to get response from OpenAI API');
      }
    } catch (e) {
      throw Exception('Failed to get response from OpenAI API');
    }
  }
}
