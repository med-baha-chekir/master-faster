class SimulatedCallException implements Exception {
  final String message;
  
  SimulatedCallException(this.message);
  
  @override
  String toString() => 'SimulatedCallException: $message';
}
