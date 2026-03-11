import 'dart:math';
import 'package:flutter/material.dart';

class RandomProvider with ChangeNotifier {
  final random = Random.secure();
  final num = 1000;
  int get getRandom => random.nextInt(num) - (num/2).toInt();
}
