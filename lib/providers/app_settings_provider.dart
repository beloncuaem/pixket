import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/app_settings_repository.dart';

class AppSettingsState {
  final bool isLoading;
  final bool onboardingComplete;

  const AppSettingsState({
    this.isLoading = true,
    this.onboardingComplete = false,
  });

  AppSettingsState copyWith({bool? isLoading, bool? onboardingComplete}) =>
      AppSettingsState(
        isLoading: isLoading ?? this.isLoading,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(const AppSettingsState()) {
    _load();
  }

  final AppSettingsRepository _repository = AppSettingsRepository();

  Future<void> _load() async {
    final complete =
        await _repository.getString('onboarding_complete') == 'true';
    state = state.copyWith(isLoading: false, onboardingComplete: complete);
  }

  Future<void> completeOnboarding() async {
    await _repository.setString('onboarding_complete', 'true');
    state = state.copyWith(onboardingComplete: true);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
      (ref) => AppSettingsNotifier(),
    );

class EffectSettings {
  final bool chartSpendRamp;

  const EffectSettings({this.chartSpendRamp = true});

  EffectSettings copyWith({bool? chartSpendRamp}) =>
      EffectSettings(chartSpendRamp: chartSpendRamp ?? this.chartSpendRamp);
}

class EffectSettingsNotifier extends StateNotifier<EffectSettings> {
  EffectSettingsNotifier({AppSettingsRepository? repository})
    : _repository = repository ?? AppSettingsRepository(),
      super(const EffectSettings()) {
    _load().then((loaded) {
      if (mounted) state = loaded;
      _loadCompleter.complete();
    });
  }

  final AppSettingsRepository _repository;
  final Completer<void> _loadCompleter = Completer<void>();
  Future<void> get loadComplete => _loadCompleter.future;

  static const _keys = (chartSpendRamp: 'chart_spend_ramp');

  Future<EffectSettings> _load() async {
    // Không catch ở đây thì test widget nào pump màn đọc khoá này sẽ dính
    // MissingPluginException của sqflite; trên máy thật thì DB lỗi cũng chỉ
    // nên về mặc định, không crash.
    try {
      return EffectSettings(
        chartSpendRamp: await _repository.getBool(
          _keys.chartSpendRamp,
          fallback: true,
        ),
      );
    } catch (error) {
      debugPrint('Không đọc được khoá biểu đồ, dùng mặc định: $error');
      return const EffectSettings();
    }
  }

  Future<void> set(String key, bool value) async {
    try {
      await _repository.setBool(key, value);
    } catch (error) {
      // Vẫn đổi state: khoá là cosmetic, UI phải phản hồi dù ghi DB hỏng.
      debugPrint('Không lưu được khoá $key: $error');
    }
    if (key != _keys.chartSpendRamp) return;
    state = state.copyWith(chartSpendRamp: value);
  }
}

final effectsProvider =
    StateNotifierProvider<EffectSettingsNotifier, EffectSettings>(
      (ref) => EffectSettingsNotifier(),
    );
