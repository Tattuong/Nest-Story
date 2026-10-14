import 'dart:io';

import 'package:flutter/material.dart';

class ItemCover extends StatelessWidget {
  const ItemCover({super.key, required this.cover, this.photoPath = ''});

  final int cover;
  final String photoPath;

  static const assets = [
    'assets/covers/remote.jpg',
    'assets/covers/keys.jpg',
    'assets/covers/phone.jpg',
    'assets/covers/wallet.jpg',
    'assets/covers/closet.jpg',
    'assets/covers/plant.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final path = photoPath.trim();
    if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Image.asset(
      assets[cover.clamp(0, assets.length - 1)],
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
