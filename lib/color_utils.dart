import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/base.dart';

double strToHue(String base32Source) {
  //const String base58alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  //final base58 = Base(base58alphabet);

  const String base32alphabet = "abcdefghijklmnopqrstuvwxyz234567";
  final base32 = Base(base32alphabet);
  String short =
      base32Source.substring(base32Source.length - 8, base32Source.length);

  Uint8List decoded = base32.decode(short);

  //int decimalValue = ByteData.view(decoded.buffer).getInt16(0, Endian.little);
  var hex = HEX.encode(decoded);
  int i = int.parse(hex, radix: 16);
  return i * 360 / 1099511627775;
}

Color getBackgroundColor(String source) {
  double saturation = 1; //0 black and white, 1 normal
  double lightness = 0.5; //0 black, 0.5 normal,  1 white
  Color tintColor = Colors.yellow;
  double tintAmount = 0.35; //0 no tint applied, 1 totally tinted
  double opacity = 0.2; //0 transparent, 1 normal
  double hue = strToHue(source);
  HSLColor hsl = HSLColor.fromAHSL(opacity, hue, saturation, lightness);
  Color rgb = hsl.toColor();
  Color tinted = dye(rgb, tintColor, tintAmount);
  return tinted;
}

Color getUnderlineColor(String source) {
  double saturation = 0.8;
  double lightness = 0.5;
  double hue = strToHue(source);
  HSLColor hsl = HSLColor.fromAHSL(1, hue, saturation, lightness);
  Color rgb = hsl.toColor();
  Color tint = Colors.yellow;
  Color tinted = dye(rgb, tint, 0.4);
  return tinted;
}

Color dye(Color original, Color tint, double strength) {
  int red =
      (original.red * (1 - strength)).toInt() + (tint.red * strength).toInt();
  int green = (original.green * (1 - strength)).toInt() +
      (tint.green * strength).toInt();
  int blue =
      (original.blue * (1 - strength)).toInt() + (tint.blue * strength).toInt();
  return Color.fromARGB(original.alpha, red, green, blue);
}
