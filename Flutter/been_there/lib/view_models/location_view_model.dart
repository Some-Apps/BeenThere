// location_view_model.dart
import 'dart:async';
import 'package:been_there/models/chunk.dart';
import 'package:been_there/repositories/location_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(Supabase.instance.client);
});

class LocationViewModel extends StateNotifier<List<Chunk>> {
  final LocationRepository _repository;
  final String userId;
  StreamSubscription? _subscription;

  LocationViewModel(this._repository, this.userId) : super([]) {
    _subscription = _repository.getLocationChunks(userId).listen((chunks) {
      // Debugging: Print fetched chunks
      print('Fetched ${chunks.length} chunks');
      for (var chunk in chunks) {
        print(
            'Chunk: lowLat=${chunk.lowLatitude}, highLat=${chunk.highLatitude}, lowLng=${chunk.lowLongitude}, highLng=${chunk.highLongitude}');
      }
      state = chunks;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final locationViewModelProvider =
    StateNotifierProvider.family<LocationViewModel, List<Chunk>, String>(
        (ref, userId) {
  final repository = ref.read(locationRepositoryProvider);
  return LocationViewModel(repository, userId);
});
