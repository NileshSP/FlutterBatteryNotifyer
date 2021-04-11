import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Service Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AudioServiceWidget(child: MainScreen()),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Example")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(child: Text("Start"), onPressed: start),
            ElevatedButton(child: Text("Stop"), onPressed: stop),
          ],
        ),
      ),
    );
  }

  start() =>
      AudioService.start(backgroundTaskEntrypoint: _backgroundTaskEntrypoint);

  stop() => AudioService.stop();
}

_backgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class AudioPlayerTask extends BackgroundAudioTask {
  // final _audioPlayer = AudioPlayer();
  // final _completer = Completer();

  late StreamSubscription streamSubscription;

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    // Connect to the URL
    //await _audioPlayer.setUrl("https://exampledomain.com/song.mp3");
    // Now we're ready to play
    // _audioPlayer.play();
    const oneSec = const Duration(seconds: 1);
    streamSubscription = new Stream.periodic(oneSec).listen((event) {
      print(DateFormat.yMMMMd("en_US").add_jms().format(DateTime.now()));
    });

    AudioServiceBackground.setState(playing: true);
  }

  @override
  Future<void> onStop() async {
    // Stop playing audio
    //await _audioPlayer.stop();
    // Shut down this background task
    streamSubscription.cancel();
    AudioServiceBackground.setState(playing: false);
    await super.onStop();
  }
}
