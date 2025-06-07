import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'giglitrk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system, // This enables automatic theme switching based on system settings
      home: const TimeTrackerHome(),
    );
  }
}

class ClientTimer {
  final String name;
  bool isRunning = false;
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;

  ClientTimer(this.name);

  void start() {
    if (!isRunning) {
      stopwatch.start();
      isRunning = true;
    }
  }

  void stop() {
    if (isRunning) {
      stopwatch.stop();
      isRunning = false;
    }
  }

  void toggle() {
    if (isRunning) {
      stop();
    } else {
      start();
    }
  }

  String getFormattedTime() {
    final duration = stopwatch.elapsed;
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class TimeTrackerHome extends StatefulWidget {
  const TimeTrackerHome({super.key});

  @override
  State<TimeTrackerHome> createState() => _TimeTrackerHomeState();
}

class _TimeTrackerHomeState extends State<TimeTrackerHome> {
  final List<ClientTimer> timers = List.generate(
    9,
    (index) => ClientTimer('Client ${index + 1}'),
  );

  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Update UI every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });

    // Set up keyboard listeners
    RawKeyboard.instance.addListener(_handleKeyPress);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    RawKeyboard.instance.removeListener(_handleKeyPress);
    for (var timer in timers) {
      timer.timer?.cancel();
    }
    super.dispose();
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey.keyLabel;
      if (RegExp(r'[1-9]').hasMatch(key)) {
        final index = int.parse(key) - 1;
        setState(() {
          timers[index].toggle();
        });
      } else if (key == '0') {
        // Find and stop the currently running timer
        setState(() {
          for (var timer in timers) {
            if (timer.isRunning) {
              timer.stop();
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('giglitrk'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: timers.length,
          itemBuilder: (context, index) {
            final timer = timers[index];
            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  setState(() {
                    timer.toggle();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: timer.isRunning 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timer.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timer.getFormattedTime(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timer.isRunning ? 'Running' : 'Stopped',
                        style: TextStyle(
                          color: timer.isRunning 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Press ${index + 1} to toggle',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
