// chunk.dart
class Chunk {
  final double highLatitude;
  final double lowLatitude;
  final double highLongitude;
  final double lowLongitude;

  Chunk({
    required this.highLatitude,
    required this.lowLatitude,
    required this.highLongitude,
    required this.lowLongitude,
  });

  // Add a factory constructor to create a Chunk from a Map
  factory Chunk.fromMap(Map<String, dynamic> map) {
    return Chunk(
      highLatitude: (map['highLatitude'] as num).toDouble(),
      lowLatitude: (map['lowLatitude'] as num).toDouble(),
      highLongitude: (map['highLongitude'] as num).toDouble(),
      lowLongitude: (map['lowLongitude'] as num).toDouble(),
    );
  }
}
