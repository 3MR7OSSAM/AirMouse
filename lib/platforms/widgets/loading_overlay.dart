import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildLoadingOverlay() {
  return Positioned.fill(
    child: Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );
}
