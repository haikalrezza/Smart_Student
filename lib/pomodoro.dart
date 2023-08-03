import 'dart:async';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

class PomodoroScreen extends StatefulWidget {
  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  AudioPlayer player = AudioPlayer();
  int _minutes = 25;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isBreakTime = false;
  double _percent = 1.0;
  Timer? _timer;

  AudioCache audioCache = AudioCache();

  @override
  void initState() {
    super.initState();
  }

  void _startTimer() {
    if (!_isRunning) {
      setState(() {
        _isRunning = true;
      });

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_minutes == 0 && _seconds == 0) {
          if (_isBreakTime) {
            _isBreakTime = false;
            _minutes = 25;
          } else {
            _playSound();
            _isBreakTime = true;
            _minutes = 5;
          }
          _seconds = 0;
        } else {
          setState(() {
            if (_seconds > 0) {
              _seconds--;
            } else {
              _minutes--;
              _seconds = 59;
            }
            _updateTimerProgress();
          });
        }
      });
    }
  }

  void _pauseTimer() {
    if (_isRunning) {
      setState(() {
        _isRunning = false;
      });
      _timer?.cancel();
    }
  }

  void _resetTimer() {
    setState(() {
      _minutes = 0;
      _seconds = 3;
      _percent = 1.0;
      _isRunning = false;
      _isBreakTime = false;
    });
    _timer?.cancel();
  }

  void _updateTimerProgress() {
    int totalSeconds = (_minutes * 60) + _seconds;
    double percent = totalSeconds / (_isBreakTime ? 5 * 60 : 25 * 60);
    setState(() {
      _percent = percent;
    });
  }

  void _playSound() {
    player.play(AssetSource("timer.mp3"));
  }

  void _stopSound() {
    player.stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String timerText = _isBreakTime ? "Take a short break" : "Focus Up!!";

    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 16.0),
                Text(
                  'Pomodoro Timer',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 10,),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tips',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text('The Pomodoro Technique is a time management method based on 25-minute stretches of focused work broken by five-minute breaks.'), // Replace with your desired tips content
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 70),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timerText,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,

                  ),
                ),
              ],
            ),
            SizedBox(height: 70),
            Center(
              child: CircularPercentIndicator(
                radius: 200.0,
                lineWidth: 10.0,
                percent: _percent,
                center: Text(
                  '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                progressColor: _isBreakTime ? Colors.blue : Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning)
                  IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: _startTimer,
                  )
                else
                  IconButton(
                    icon: Icon(Icons.pause),
                    onPressed: _pauseTimer,
                  ),
                IconButton(
                  icon: Icon(Icons.replay),
                  onPressed: _resetTimer,
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/plant.json', height: 150, width: 150),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
