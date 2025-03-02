import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:air_mouse/platforms/widgets/connection_button.dart';
import 'package:air_mouse/platforms/widgets/game_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GameControlApp extends StatelessWidget {
  const GameControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GameControlScreen(),
        ),
      ),
    );
  }
}

class GameControlScreen extends StatefulWidget {
  const GameControlScreen({super.key});

  @override
  State<GameControlScreen> createState() => _GameControlScreenState();
}

class _GameControlScreenState extends State<GameControlScreen> {
  WebSocketChannel? _channel;
  String? _connectionStatus = "Not connected";
  bool _isConnecting = false;
  String _currentSensitivity = "medium";

  Timer? _arrowTimer;
  String? _currentDirection;
  double _currentJoystickMagnitude = 0.0;

  final double _sensitivity = 0.1; // Default sensitivity value (0.01 to 1.0)

  @override
  void dispose() {
    _arrowTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  void _connectToWebSocketWithIp(String ip) {
    final uri = 'ws://$ip';
    setState(() {
      _connectionStatus = "Connecting...";
      _isConnecting = true;
    });

    try {
      _channel = WebSocketChannel.connect(Uri.parse(uri));
      _channel!.stream.listen(
        _onMessageReceived,
        onDone: _onWebSocketDone,
        onError: _onWebSocketError,
      );

      // Wait a bit to ensure connection is established
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_connectionStatus == "Connecting...") {
          setState(() {
            _connectionStatus = "Connected";
            _isConnecting = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _connectionStatus = "Connection failed: ${e.toString()}";
        _isConnecting = false;
      });
    }
  }

  void _onMessageReceived(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (kDebugMode) {
        print("Received message: $data");
      }

      if (data['event'] == 'ConnectionStatus') {
        setState(() {
          _connectionStatus = data['status'];
          _isConnecting = false;
        });
      }

      if (data['event'] == 'ServerStatus' ||
          data['event'] == 'ConfigResponse' ||
          data['event'] == 'ConnectionStatus') {
        if (data.containsKey('sensitivity')) {
          setState(() {
            _currentSensitivity = data['sensitivity'];
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing message: $e");
      }
    }
  }

  void _onWebSocketDone() {
    setState(() {
      _connectionStatus = "Disconnected";
      _channel = null;
    });
  }

  void _onWebSocketError(Object error) {
    setState(() {
      _connectionStatus = "Connection failed: $error";
      _channel = null;
      _isConnecting = false;
    });
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        if (kDebugMode) {
          print("Error sending message: $e");
        }
      }
    }
  }

  void _startSendingArrowMovement(String direction, double magnitude) {
    if (_currentDirection != direction ||
        (_currentJoystickMagnitude - magnitude).abs() > 0.1) {
      _currentDirection = direction;
      _currentJoystickMagnitude = magnitude;
      _arrowTimer?.cancel();
      _sendArrowMovement(direction, magnitude);

      // Use sensitivity to adjust the message sending frequency
      final interval =
          (1.0 - _sensitivity) * 200 + 50; // Scale between 50ms and 200ms
      _arrowTimer = Timer.periodic(
        Duration(milliseconds: interval.toInt()),
        (_) => _sendArrowMovement(direction, magnitude),
      );
    }
  }

  void _stopArrowMovement() {
    _arrowTimer?.cancel();
    _arrowTimer = null;
    _currentDirection = null;
    _currentJoystickMagnitude = 0.0;

    // Send a stop movement event
    final data = {"event": "JoystickMove", "direction": "stop"};
    _sendMessage(data);
  }

  void _sendArrowMovement(String direction, double magnitude) {
    final data = {
      "event": "JoystickMove",
      "direction": direction,
      "intensity": magnitude
    };

    if (kDebugMode) {
      print("Sending message: $data");
    }
    _sendMessage(data);
  }

  /// Converts joystick movement details into directional strings
  String getDirectionFromJoystick(double x, double y) {
    final double threshold = 0.5; // Adjust threshold for diagonal detection

    if (x.abs() < 0.2 && y.abs() < 0.2) {
      return "stop"; // Small movements are ignored
    }

    if (x.abs() > threshold && y.abs() > threshold) {
      // Diagonal movement
      if (x > 0 && y < 0) return "up_right";
      if (x < 0 && y < 0) return "up_left";
      if (x > 0 && y > 0) return "down_right";
      if (x < 0 && y > 0) return "down_left";
    }

    // Cardinal directions
    if (x.abs() > y.abs()) {
      return x > 0 ? "right" : "left";
    } else {
      return y > 0 ? "down" : "up";
    }
  }

  void _changeSensitivity() {
    String newSensitivity;
    switch (_currentSensitivity) {
      case "low":
        newSensitivity = "medium";
        break;
      case "medium":
        newSensitivity = "high";
        break;
      case "high":
      default:
        newSensitivity = "low";
        break;
    }

    _sendMessage({
      "event": "ConfigRequest",
      "action": "setSensitivity",
      "value": newSensitivity
    });
  }

  Widget buildLoadingOverlay() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConnectToServerButton(
                  onConnect: _connectToWebSocketWithIp,
                  connectionStatus: _connectionStatus ?? "Not connected",
                  isConnecting: _isConnecting,
                ),
                const SizedBox(width: 10),
                if (_connectionStatus == "Connected")
                  ElevatedButton(
                    onPressed: _changeSensitivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Sensitivity: $_currentSensitivity"),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                children: [
                  // L Button
                  GameButton(
                    label: 'L1',
                    onPointerDown: () => _sendMessage(
                      {"event": "ButtonPress", "button": "L", "state": "press"},
                    ),
                    onPointerUp: () => _sendMessage(
                      {
                        "event": "ButtonPress",
                        "button": "L",
                        "state": "release"
                      },
                    ),
                  ),
                  const Spacer(),
                  GameButton(
                    label: 'L2',
                    onPointerDown: () => _sendMessage(
                      {"event": "ButtonPress", "button": "M", "state": "press"},
                    ),
                    onPointerUp: () => _sendMessage(
                      {
                        "event": "ButtonPress",
                        "button": "Y",
                        "state": "release"
                      },
                    ),
                  ),
                  const Spacer(
                    flex: 5,
                  ),
                  GameButton(
                    label: 'R2',
                    onPointerDown: () => _sendMessage(
                      {"event": "ButtonPress", "button": "M", "state": "press"},
                    ),
                    onPointerUp: () => _sendMessage(
                      {
                        "event": "ButtonPress",
                        "button": "M",
                        "state": "release"
                      },
                    ),
                  ),
                  const Spacer(),

                  GameButton(
                    label: 'R1',
                    onPointerDown: () => _sendMessage(
                      {"event": "ButtonPress", "button": "R", "state": "press"},
                    ),
                    onPointerUp: () => _sendMessage(
                      {
                        "event": "ButtonPress",
                        "button": "R",
                        "state": "release"
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Joystick control at the center
                  buildJoystickControl(),
                  // Right control buttons (A, B),
                  const Spacer(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              // Y Button
                              GameButton(
                                size: 60,
                                label: '∆',
                                onPointerDown: () => _sendMessage(
                                  {
                                    "event": "ButtonPress",
                                    "button": "W",
                                    "state": "press"
                                  },
                                ),
                                onPointerUp: () => _sendMessage(
                                  {
                                    "event": "ButtonPress",
                                    "button": "W",
                                    "state": "release"
                                  },
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // X Button
                              GameButton(
                                size: 60,
                                label: '⎕',
                                onPointerDown: () => _sendMessage(
                                  {
                                    "event": "ButtonPress",
                                    "button": "A",
                                    "state": "press"
                                  },
                                ),
                                onPointerUp: () => _sendMessage(
                                  {
                                    "event": "ButtonPress",
                                    "button": "A",
                                    "state": "release"
                                  },
                                ),
                              ),
                              const SizedBox(width: 60),
                              // A Button
                              GameButton(
                                size: 60,
                                label: 'O',
                                onPointerDown: () => _sendMessage(
                                  {
                                    "event": "ButtonPress",
                                    "button": "D",
                                    "state": "press"
                                  },
                                ),
                                onPointerUp: () => _sendMessage(
                                  {
                                    "event": "ButtonPress",
                                    "button": "D",
                                    "state": "release"
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              // B Button
                              GameButton(
                                size: 60,
                                label: 'X',
                                onPointerDown: () => _sendMessage(
                                  {
                                    "event": "ButtonPress",
                                    "button": "S",
                                    "state": "press"
                                  },
                                ),
                                onPointerUp: () => _sendMessage(
                                  {
                                    "event": "ButtonPress",
                                    "button": "S",
                                    "state": "release"
                                  },
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
        if (_isConnecting) buildLoadingOverlay(),
      ],
    );
  }

  Widget buildJoystickControl() {
    return SizedBox(
      height: 180,
      width: 180,
      child: Joystick(
        base: JoystickBase(
          decoration: JoystickBaseDecoration(
            middleCircleColor: Colors.black54,
            drawOuterCircle: true,
            drawInnerCircle: false,
            innerCircleColor: Colors.grey.shade800,
            outerCircleColor: Colors.grey.shade700,
            boxShadowColor: Colors.white10.withOpacity(0.05),
          ),
        ),
        stick: JoystickStick(
          decoration: JoystickStickDecoration(
            color: Colors.grey.shade800,
          ),
        ),
        mode: JoystickMode.all, // Allows movement in all directions
        listener: (details) {
          final magnitude = sqrt(details.x * details.x + details.y * details.y);

          if (magnitude < 0.2) {
            _stopArrowMovement(); // Stop movement when joystick returns to center
          } else {
            // Calculate direction based on joystick's movement
            String direction = getDirectionFromJoystick(details.x, details.y);
            // Normalize magnitude to 0-1 range
            double normalizedMagnitude = min(magnitude, 1.0);
            _startSendingArrowMovement(direction, normalizedMagnitude);
          }
        },
      ),
    );
  }
}

// Make sure to update GameButton widget to use onPointerDown and onPointerUp
class UpdatedGameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;
  final double size;

  const UpdatedGameButton({
    super.key,
    required this.label,
    this.onPointerDown,
    this.onPointerUp,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPointerDown?.call(),
      onPointerUp: (_) => onPointerUp?.call(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
