import 'dart:ffi';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

enum TtsState {
  playing,
  stopped,
  paused,
  continued
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image to Speech',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'Image to Speech'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class LocaleEntity {
  String Name;
  String Value;
  LocaleEntity(this.Name, this.Value);
}

class ImageModel {
  String? imagePath;
  ImageModel({required this.imagePath});
}

class _MainPageState extends State<MainPage> {
  FilePickerResult? result;

  @override
  void initState() {
    super.initState();
    initTTS();
  }

  @override
  void dispose() {
    flutterTts.stop();
  }

  final List supportedLocaleList = [
    LocaleEntity("English", "en-US"),
    LocaleEntity("Bahasa Indonesia", "id-ID"),
    LocaleEntity("Dutch", "nl-NL"),
  ];
  String selectedLocaleValue = "en-US";
  ImageModel? image;
  String resultText = "";

  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  String? _newVoiceText;
  int? _inputLength;

  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  initTTS() {
    flutterTts = FlutterTts();
    _setAwaitOptions();
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future _speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await flutterTts.speak(_newVoiceText!);
      }
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  void _changeLocale(String newLocaleValue) {
    setState(() {
      selectedLocaleValue = newLocaleValue;
      flutterTts.setLanguage(newLocaleValue);
      flutterTts.isLanguageInstalled(newLocaleValue).then((value) => isCurrentLanguageInstalled = (value as bool));
    });
    print(selectedLocaleValue);
  }

  void _setImageModel(String path) {
    setState(() {
      ImageModel(imagePath: path);
    });
  }

  void _setResultText(String result) {
    setState(() {
      resultText = result;
      _newVoiceText = result;
    });
  }

  Future<List<String>> getText(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognisedText = await textDetector.processImage(inputImage);

    List<String> recognizedList = [];

    for (TextBlock block in recognisedText.blocks) {
      for (TextLine textline in block.lines) {
        recognizedList.add(textline.text);
      }
    }
    print(recognizedList.toString());
    return recognizedList;
  }

  List<DropdownMenuItem<String>> _getDropdownMenuItems() {
    List<DropdownMenuItem<String>> menuItems = supportedLocaleList
        .map((e) => DropdownMenuItem<String>(
              value: e.Value,
              child: Text(e.Name),
            ))
        .toList();
    return menuItems;
  }

  String buildTextResult(List<String> listResult) {
    String result = "";
    for (int i = 0; i < listResult.length; i++) {
      if (i == 0) {
        result += listResult[i];
      } else {
        result += "\n" + listResult[i];
      }
    }
    return result;
  }

  Future<dynamic> _getEngines() async => await flutterTts.getEngines;

  Widget _engineSection() {
    return FutureBuilder<dynamic>(
        future: _getEngines(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return _enginesDropDownSection(snapshot.data);
          } else if (snapshot.hasError) {
            return Text('Error loading engines...');
          } else
            return Text('Loading engines...');
        });
  }

  Widget _btnSection() {
    return Container(
      padding: EdgeInsets.only(top: 50.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButtonColumn(Colors.green, Colors.greenAccent, Icons.play_arrow, 'PLAY', _speak),
          _buildButtonColumn(Colors.red, Colors.redAccent, Icons.stop, 'STOP', _stop),
          _buildButtonColumn(Colors.blue, Colors.blueAccent, Icons.pause, 'PAUSE', _pause),
        ],
      ),
    );
  }

  Column _buildButtonColumn(Color color, Color splashColor, IconData icon, String label, Function func) {
    return Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(icon: Icon(icon), color: color, splashColor: splashColor, onPressed: () => func()),
      Container(margin: const EdgeInsets.only(top: 8.0), child: Text(label, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: color)))
    ]);
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(dynamic engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(value: type as String?, child: Text(type as String)));
    }
    return items;
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    await flutterTts.setEngine(selectedEngine!);
    language = null;
    setState(() {
      engine = selectedEngine;
    });
  }

  Widget _enginesDropDownSection(dynamic engines) => Container(
        padding: EdgeInsets.only(top: 50.0),
        child: DropdownButton(
          value: engine,
          items: getEnginesDropDownMenuItems(engines),
          onChanged: changedEnginesDropDownItem,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton<String>(
              value: selectedLocaleValue,
              icon: const Icon(Icons.arrow_drop_down_sharp),
              elevation: 16,
              style: const TextStyle(color: Colors.brown),
              underline: Container(
                height: 2,
                color: Colors.brown,
              ),
              onChanged: (String? value) {
                _changeLocale(value!);
              },
              items: _getDropdownMenuItems(),
            ),
            if (result != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected file:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Image.file(
                      File(result!.files[0].path ?? ""),
                      fit: BoxFit.cover,
                    ),
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: result?.files.length ?? 0,
                        itemBuilder: (context, index) {
                          return Text(result?.files[index].name ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
                        })
                  ],
                ),
              ),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await FilePicker.platform.pickFiles(allowMultiple: false);
                  if (result == null) {
                    print("No file selected");
                  } else {
                    _setImageModel(result?.files[0].path ?? "");
                    String resultText = buildTextResult(await getText(result?.files[0].path ?? ""));
                    _setResultText(resultText);
                  }
                },
                child: const Text("Pick an Image"),
              ),
            ),
            Center(
              child: SizedBox(
                width: 150,
                child: Text(resultText),
              ),
            ),
            _btnSection(),
          ],
        ),
      ),
    );
  }
}
