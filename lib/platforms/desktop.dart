import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';

class DesktopApp extends StatefulWidget {
  const DesktopApp({super.key});

  @override
  _DesktopAppState createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> with SingleTickerProviderStateMixin {
  bool isServerRunning = false;
  bool isLoading = false;
  Process? serverProcess;
  String output = '';
  String? localIp;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // Infinite loop for pulsating effect
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the animation controller
    super.dispose();
  }

  // Function to get local IP address
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      for (var interface in interfaces) {
        // Check if the interface name is related to Wireless LAN
        if (interface.name.toLowerCase().contains('wi-fi') || interface.name.toLowerCase().contains('wlan')) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback) {
              return addr.address; // Return the first non-loopback IPv4 address
            }
          }
        }
      }
    } catch (e) {
      return 'Failed to get IP address: $e';
    }

    return null;
  }
  Future<void> startServer() async {
    setState(() {
      isLoading = true; // Start loading animation
    });

    try {
      String executablePath = 'server/dist/AirMouse.exe'; // Path to your executable

      // Running the executable in a hidden process
      serverProcess = await Process.start(
        executablePath,
        [],
        mode: ProcessStartMode.inheritStdio, // Use inheritStdio to prevent the console window from showing
      );

      // Get the local IP address and update the state
      localIp = await getLocalIpAddress();

      setState(() {
        isServerRunning = true;
        output = 'Server Started \nConnect to the server at $localIp:8765';
      });
    } catch (e) {
      setState(() {
        output = 'Error starting server: $e';
      });
    } finally {
      setState(() {
        isLoading = false; // Stop loading animation
      });
    }
  }

  void stopServer() async {
    if (serverProcess != null) {
      try {
        // Kill the process using taskkill command with the process ID
        await Process.run('taskkill', ['/PID', serverProcess!.pid.toString(), '/F', '/T']);

        setState(() {
          isServerRunning = false;
          output = 'Server stopped successfully.';
        });
        if (kDebugMode) {
          print('Process Killed');
        }
      } catch (e) {
        setState(() {
          output = 'Error stopping server: $e';
        });
        if (kDebugMode) {
          print('Process Kill failed: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedPhone(controller: _controller),
            const SizedBox(height: 20),
            Column(
              children: [
                Text(
                  isLoading
                      ? 'Connecting...'
                      : isServerRunning
                      ? 'Server is running'
                      : 'Start the server to connect',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                if (isLoading) const CircularProgressIndicator(),

                if (!isLoading) ...[
                  SizedBox(height: 20,),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    onPressed: isServerRunning ? null : startServer,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Start Server',style: TextStyle(color: Colors.white),),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    onPressed: isServerRunning ? stopServer : null,
                    child:  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Stop Server',style: TextStyle(color: isServerRunning ? Colors.white : Colors.grey)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(output , style: TextStyle(color: Colors.blue,fontWeight: FontWeight.w500),textAlign: TextAlign.center,), // Display server output here
              ],
            ),
            // Laptop icon at the right side

          ],
        ),
      ),
    );
  }
}

class AnimatedPhone extends StatelessWidget {
  const AnimatedPhone({
    super.key,
    required AnimationController controller,
  }) : _controller = controller;

  final AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,  // Fixing the width of the animated area
      height: 250, // Fixing the height of the animated area
      child: Stack(
        alignment: Alignment.center,
        children: [
          // First animated circle
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 250 * _controller.value,
                height: 250 * _controller.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.2 * (1 - _controller.value)),
                ),
              );
            },
          ),
          // Second animated circle
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 150 + (50 * sin(_controller.value * pi)),
                height: 150 + (50 * sin(_controller.value * pi)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.3 * (1 - _controller.value)),
                ),
              );
            },
          ),
          // Third animated circle
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 100 + (30 * cos(_controller.value * pi)),
                height: 100 + (30 * cos(_controller.value * pi)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.4 * (1 - _controller.value)),
                ),
              );
            },
          ),
          // Static phone icon in the middle (no animation)
          Icon(Icons.phone_iphone, size: 50, color: Colors.blue.shade300),
        ],
      ),
    );
  }
}
