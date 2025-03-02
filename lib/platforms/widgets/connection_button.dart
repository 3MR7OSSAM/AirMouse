import 'package:flutter/material.dart';

class ConnectToServerButton extends StatelessWidget {
  final Function(String) onConnect;
  final String connectionStatus;
  final bool isConnecting;

  const ConnectToServerButton({
    super.key,
    required this.onConnect,
    required this.connectionStatus,
    required this.isConnecting,
  });

  void _showIpDialog(BuildContext context) {
    final ipController = TextEditingController(text: '192.168.1.5:8765');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          surfaceTintColor: Colors.grey.withValues(alpha: .3),
          backgroundColor: Colors.grey.withValues(alpha: .3),
          title: const Text("Enter Server IP"),
          content: TextField(
            controller: ipController,
            // decoration: const InputDecoration(
            //   hintText: "192.168.x.x:port",
            // ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                final ip = ipController.text.trim();
                if (ip.isNotEmpty) {
                  onConnect(ip);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text(
                "Connect",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: isConnecting ? null : () => _showIpDialog(context),
          icon: const Icon(Icons.connected_tv, color: Colors.white),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            'Status: $connectionStatus',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
