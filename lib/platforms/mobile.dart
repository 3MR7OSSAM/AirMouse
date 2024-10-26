import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class MobileApp extends StatefulWidget {
  const MobileApp({super.key});

  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  final TextEditingController _ipController = TextEditingController();
  WebSocketChannel? _channel;
  bool _isCursorMovingEnabled = false;
  double _sensitivity = 0.5;
  String? _connectionStatus;
  Offset _cursorPosition = Offset.zero; // Initial position of the cursor
  final double _containerSize = 200.0; // Size of the "Start Cursor" container
  bool _isConnecting = false; // Add a loading state for connection

  @override
  void initState() {
    super.initState();
    _ipController.text = "192.168.1.4:8765"; // Default IP
  }

  bool _isValidIP(String ip) {
    // A basic check for valid IP address format
    final regex = RegExp(
        r"^(?:[0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{1,5}$");
    return regex.hasMatch(ip);
  }

  Future<void> _connectToWebSocket() async {
    if (!_isValidIP(_ipController.text)) {
      setState(() {
        _connectionStatus = "Invalid IP Address";
      });
      return;
    }

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
    if (kDebugMode) {
      print("Received message: $message");
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
    });
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _moveCursor(double dx, double dy) {
    setState(() {
      _cursorPosition = _cursorPosition.translate(dx, dy);
    });
    _sendMouseMovement(dx, dy);
  }

  void _sendMouseMovement(double dx, double dy) {
    final data = {
      "event": "MouseMotionMove",
      "axis": {"x": dx, "y": dy}
    };
    _sendMessage(data);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Mouse Controller',
                    style: TextStyle(
                        color: Colors.black45,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                  ),
                  const SizedBox(height: 20),
                  _buildIPInputField(),
                  const SizedBox(height: 10),
                  _buildConnectionStatusText(),
                  const SizedBox(height: 20),
                  _buildSensitivitySlider(),
                  const SizedBox(height: 10),
                  _buildMouseControlButtons(),
                  const SizedBox(height: 20),
                  _buildCursorControl(),
                  const SizedBox(height: 20),
                  _buildPresentationControlButtons(),
                ],
              ),
            ),
            if (_isConnecting) _buildLoadingOverlay(), // Add a loader during connection
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
        labelStyle:  TextStyle(color: Colors.blue.shade400),
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
      style:
      const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45),
    );
  }

  Widget _buildSensitivitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sensitivity: ${_sensitivity.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.black45),
        ),
        Slider(
          activeColor: Colors.blue.shade400,
          value: _sensitivity,
          min: 0.01,
          max: 1.0,
          onChanged: (value) {
            setState(() {
              _sensitivity = value;
            });
            _sendMessage({"changeSensitivityEvent": value});
          },
        ),
      ],
    );
  }

  Widget _buildCursorControl() {
    return GestureDetector(
      onPanUpdate: (details) {
        if (_isCursorMovingEnabled) {
          _moveCursor(
              details.delta.dx * _sensitivity, details.delta.dy * _sensitivity);
        }
      },
      onTap: () {
        setState(() {
          _isCursorMovingEnabled = !_isCursorMovingEnabled;
        });
        final event =
        _isCursorMovingEnabled ? "MouseMotionStart" : "MouseMotionStop";
        _sendMessage({"event": event});
      },
      child: Container(
        width: double.infinity,
        height: _containerSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12, width: 3),
          borderRadius: BorderRadius.circular(8),
          color: _isCursorMovingEnabled
              ? Colors.blue.shade200
              : Colors.grey.shade300,
        ),
        child: Center(
          child: Text(
            _isCursorMovingEnabled ? '' : 'Start Cursor',
            style:  const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMouseControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () => _sendMessage({"leftClickEvent": true}),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade300,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
            child:
            Text('Left Click', style: TextStyle(color: Colors.white)),
          ),
        ),
        ElevatedButton(
          onPressed: () => _sendMessage({"rightClickEvent": true}),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade300,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
            child: Text('Right Click', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildPresentationControlButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
          child: Text(
            'Sound Buttons: ',
            style: TextStyle(
                color: Colors.black45,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _sendMessage({"shortcut": "previous_track"}),
                child: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                )),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _sendMessage({"shortcut": "pause_play"}),
                child: const Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    Text(
                      '/',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    Icon(
                      Icons.pause,
                      color: Colors.white,
                    ),
                  ],
                )),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _sendMessage({"shortcut": "next_track"}),
                child: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                )),
          ],
        ),
      ],
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
