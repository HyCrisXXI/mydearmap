String generate6DigitCode() {
  final rnd = DateTime.now().millisecondsSinceEpoch % 1000000;
  return rnd.toString().padLeft(6, '0');
}
