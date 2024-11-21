// location_repository.dart
import 'package:been_there/models/chunk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationRepository {
  final SupabaseClient _supabase;

  LocationRepository(this._supabase);

  Stream<List<Chunk>> getLocationChunks(String userId) {
    return _supabase
        .from('locations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
      return data.map((item) => Chunk.fromMap(item)).toList();
    });
  }
}
