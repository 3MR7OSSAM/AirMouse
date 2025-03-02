import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GamePad extends StatefulWidget {
  const GamePad({Key? key}) : super(key: key);

  @override
  State<GamePad> createState() => _GamePadState();
}

class _GamePadState extends State<GamePad> {
  final TextEditingController _ipController = TextEditingController();
  WebSocketChannel? _channel;
  double _sensitivity = 0.5;
  String? _connectionStatus;
  bool _isConnecting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ipController.text = "192.168.1.9:8765"; // Default IP
  }

  bool _isValidIP(String ip) {
    final regex = RegExp(r"^(?:[0-9]{1,3}\.){3}[0-9]{1,5}$");
    return regex.hasMatch(ip);
  }

  Future<void> _connectToWebSocket() async {
    // if (!_isValidIP(_ipController.text)) {
    //   setState(() {
    //     _connectionStatus = "Invalid IP Address";
    //   });
    //   return;
    // }

    setState(() {
      _connectionStatus = "Connecting...";
      _isConnecting = true;
    });

    final uri = 'ws://${_ipController.text}';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(uri));
      _channel!.stream.listen(
        _onMessageReceived,
        onDone: _onWebSocketDone,
        onError: _onWebSocketError,
      );
      setState(() {
        _connectionStatus = "Connected";
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = "Connection failed: ${e.toString()}";
        _isConnecting = false;
      });
    }
  }

  void _onMessageReceived(dynamic message) {
    debugPrint("Received message: $message");
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
    });
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _sendDirectionContinuously(String direction) {
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
          (_) {
        final data = {"event": "JoystickMove", "direction": direction};
        _sendMessage(data);
      },
    );
  }

  void _stopSendingDirection() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Gamepad Controller',
                        style: TextStyle(
                          color: Colors.black45,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildIPInputField(),
                      const SizedBox(height: 10),
                      _buildConnectionStatusText(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 40,
                        bottom: 60,
                        child: _buildJoystickControl(),
                      ),
                      Positioned(
                        right: 40,
                        bottom: 60,
                        child: Column(
                          children: [
                            _buildActionButton("A"),
                            const SizedBox(height: 20),
                            _buildActionButton("B"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isConnecting) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildIPInputField() {
    return TextField(
      controller: _ipController,
      style: const TextStyle(color: Colors.black54),
      decoration: InputDecoration(
        labelText: 'Server IP Address',
        labelStyle: TextStyle(color: Colors.blue.shade400),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.connect_without_contact,
            color: Colors.blue.shade400,
          ),
          onPressed: _connectToWebSocket,
        ),
      ),
    );
  }

  Widget _buildConnectionStatusText() {
    return Text(
      'Status: ${_connectionStatus ?? "Not connected"}',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black45,
      ),
    );
  }


  Widget _buildJoystickControl() {
    return Column(
      children: [
        const Text(
          'Arrow Control',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        Container(
          width: 150,
          height: 150,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 50,
                child: _buildArrowButton(Icons.keyboard_arrow_up, "up"),
              ),
              Positioned(
                bottom: 0,
                left: 50,
                child: _buildArrowButton(Icons.keyboard_arrow_down, "down"),
              ),
              Positioned(
                left: 0,
                top: 50,
                child: _buildArrowButton(Icons.keyboard_arrow_left, "left"),
              ),
              Positioned(
                right: 0,
                top: 50,
                child: _buildArrowButton(Icons.keyboard_arrow_right, "right"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArrowButton(IconData icon, String direction) {
    return GestureDetector(
      onTapDown: (_) {
        _sendDirectionContinuously(direction);
      },
      onTapUp: (_) {
        _stopSendingDirection();
      },
      onTapCancel: _stopSendingDirection,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label) {
    return GestureDetector(
      onTap: () {
        final data = {"event": "ButtonPress", "button": label};
        _sendMessage(data);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade800,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
