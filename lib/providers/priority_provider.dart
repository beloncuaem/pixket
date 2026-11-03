import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/priority_level.dart';
import '../data/repositories/priority_repository.dart';

class PriorityState {
  final List<PriorityLevel> levels;
  final bool isLoading;

  const PriorityState({this.levels = const [], this.isLoading = false});

  PriorityState copyWith({List<PriorityLevel>? levels, bool? isLoading}) =>
      PriorityState(
        levels: levels ?? this.levels,
        isLoading: isLoading ?? this.isLoading,
      );
}

class PriorityNotifier extends StateNotifier<PriorityState> {
  PriorityNotifier() : super(const PriorityState()) {
    loadLevels();
  }

  final PriorityRepository _repository = PriorityRepository();

  Future<void> loadLevels() async {
    state = state.copyWith(isLoading: true);
    try {
      final levels = await _repository.getAll();
      state = state.copyWith(levels: levels, isLoading: false);
    } catch (error) {
      // Supabase chưa kết nối hoặc chưa đăng nhập: giữ danh sách rỗng để UI
      // hiện placeholder thay vì để lỗi lan lên làm sập màn hình.
      state = state.copyWith(isLoading: false);
    }
  }
}

final priorityProvider = StateNotifierProvider<PriorityNotifier, PriorityState>(
  (ref) => PriorityNotifier(),
);
