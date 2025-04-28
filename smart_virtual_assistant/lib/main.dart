import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'dart:convert';

void main() {
  runApp(SmartAssistantApp());
}

class SmartAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Virtual Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isLoading = false;
  String _text = 'Tap the mic and start speaking';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult:
              (val) => setState(() {
                _text = val.recognizedWords;
              }),
          pauseFor: Duration(seconds: 5),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_text.isNotEmpty) {
        await _sendTextToAWS(_text);
      }
    }
  }

  Future<void> _sendTextToAWS(String text) async {
    setState(() => _isLoading = true);

    try {
      final url =
          'https://oirw2ll1b8.execute-api.us-east-1.amazonaws.com/?text=${Uri.encodeComponent(text)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String reply = data['response'];

        setState(() {
          _text = reply;
          _isLoading = false;
        });

        await _flutterTts.speak(reply);
      } else {
        setState(() {
          _text = 'Failed to get response';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _text = 'Error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Virtual Assistant')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? CircularProgressIndicator()
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _text,
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
            SizedBox(height: 30),
            AvatarGlow(
              animate: _isListening,
              endRadius: 75.0,
              glowColor: Colors.blue,
              duration: Duration(milliseconds: 2000),
              repeat: true,
              repeatPauseDuration: Duration(milliseconds: 100),
              child: FloatingActionButton(
                onPressed: _listen,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
