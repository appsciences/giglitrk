import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:hotkey_manager/hotkey_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize hotkey manager
  await hotKeyManager.unregisterAll();
  
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
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });

    // Set up keyboard listeners
    HardwareKeyboard.instance.addHandler(_handleKeyPress);
    
    // Set up global hotkeys
    _setupHotkeys();
  }

  Future<void> _setupHotkeys() async {
    final keys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    
    // First unregister any existing hotkeys
    await hotKeyManager.unregisterAll();
    
    for (var i = 0; i < timers.length; i++) {
      final hotKey = HotKey(
        key: keys[i],
        modifiers: [HotKeyModifier.control, HotKeyModifier.alt, HotKeyModifier.meta],
        scope: HotKeyScope.system,
        identifier: 'timer-${i + 1}',
      );
      
      try {
        await hotKeyManager.register(
          hotKey,
          keyDownHandler: (_) async {
            print('Hotkey pressed: timer-${i + 1}');
            setState(() {
              // Stop all other timers before toggling this one
              if (!timers[i].isRunning) {
                for (var j = 0; j < timers.length; j++) {
                  if (j != i && timers[j].isRunning) {
                    timers[j].stop();
                  }
                }
              }
              timers[i].toggle();
            });
          },
        );
        print('Successfully registered hotkey: ${hotKey.identifier}');
      } catch (e) {
        print('Failed to register hotkey: ${hotKey.identifier}, error: $e');
      }
    }
    
    // Register hotkey for stopping all timers
    final stopHotKey = HotKey(
      key: LogicalKeyboardKey.digit0,
      modifiers: [HotKeyModifier.fn, HotKeyModifier.meta],
      scope: HotKeyScope.system,
      identifier: 'stop-all',
    );
    
    try {
      await hotKeyManager.register(
        stopHotKey,
        keyDownHandler: (_) async {
          print('Stop all hotkey pressed');
          setState(() {
            for (var timer in timers) {
              if (timer.isRunning) {
                timer.stop();
              }
            }
          });
        },
      );
      print('Successfully registered stop hotkey');
    } catch (e) {
      print('Failed to register stop hotkey: $e');
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyPress);
    hotKeyManager.unregisterAll();
    for (var timer in timers) {
      timer.timer?.cancel();
    }
    super.dispose();
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey.keyLabel;
      if (RegExp(r'[1-9]').hasMatch(key)) {
        final index = int.parse(key) - 1;
        setState(() {
          // Stop all other timers before toggling this one
          if (!timers[index].isRunning) {
            for (var j = 0; j < timers.length; j++) {
              if (j != index && timers[j].isRunning) {
                timers[j].stop();
              }
            }
          }
          timers[index].toggle();
        });
      } else if (key == '0') {
        setState(() {
          for (var timer in timers) {
            if (timer.isRunning) {
              timer.stop();
            }
          }
        });
      }
    }
    return false;
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
                    // Stop all other timers before toggling this one
                    if (!timer.isRunning) {
                      for (var i = 0; i < timers.length; i++) {
                        if (i != index && timers[i].isRunning) {
                          timers[i].stop();
                        }
                      }
                    }
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
                        'Press ^+⎇+⌘+${index + 1}',
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
