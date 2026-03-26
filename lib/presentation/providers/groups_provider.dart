import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/miner_group.dart';

const _uuid = Uuid();

class MinerGroupsNotifier extends Notifier<List<MinerGroup>> {
  @override
  List<MinerGroup> build() => [];

  MinerGroup addGroup(String name) {
    final group = MinerGroup(
      id: _uuid.v4(),
      name: name,
      sortOrder: state.length,
    );
    state = [...state, group];
    return group;
  }

  void removeGroup(String id) {
    state = state.where((g) => g.id != id).toList();
  }

  void renameGroup(String id, String newName) {
    state = [
      for (final g in state)
        if (g.id == id) g.copyWith(name: newName) else g,
    ];
  }
}

final minerGroupsProvider =
    NotifierProvider<MinerGroupsNotifier, List<MinerGroup>>(
        MinerGroupsNotifier.new);
