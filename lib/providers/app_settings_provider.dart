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
  final bool stars, rainbowRule, captureSweep, confetti, mosaic, chartSpendRamp;

  const EffectSettings({
    this.stars = true,
    this.rainbowRule = true,
    this.captureSweep = true,
    this.confetti = true,
    this.mosaic = false,
    this.chartSpendRamp = true,
  });

  EffectSettings copyWith({
    bool? stars,
    bool? rainbowRule,
    bool? captureSweep,
    bool? confetti,
    bool? mosaic,
    bool? chartSpendRamp,
  }) => EffectSettings(
    stars: stars ?? this.stars,
    rainbowRule: rainbowRule ?? this.rainbowRule,
    captureSweep: captureSweep ?? this.captureSweep,
    confetti: confetti ?? this.confetti,
    mosaic: mosaic ?? this.mosaic,
    chartSpendRamp: chartSpendRamp ?? this.chartSpendRamp,
  );
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

  static const _keys = (
    stars: 'fx_stars',
    rainbowRule: 'fx_rainbow_rule',
    captureSweep: 'fx_capture_sweep',
    confetti: 'fx_confetti',
    mosaic: 'fx_mosaic',
    chartSpendRamp: 'chart_spend_ramp',
  );

  Future<EffectSettings> _load() async {
    // Không catch ở đây thì mọi test widget pump màn có PixelScreenHeader
    // (→ RainbowRule → effectsProvider) sẽ dính MissingPluginException của
    // sqflite; trên máy thật thì DB lỗi cũng chỉ nên về mặc định, không crash.
    try {
      return EffectSettings(
        stars: await _repository.getBool(_keys.stars, fallback: true),
        rainbowRule: await _repository.getBool(
          _keys.rainbowRule,
          fallback: true,
        ),
        captureSweep: await _repository.getBool(
          _keys.captureSweep,
          fallback: true,
        ),
        confetti: await _repository.getBool(_keys.confetti, fallback: true),
        mosaic: await _repository.getBool(_keys.mosaic, fallback: false),
        chartSpendRamp: await _repository.getBool(
          _keys.chartSpendRamp,
          fallback: true,
        ),
      );
    } catch (error) {
      debugPrint('Không đọc được khoá hiệu ứng, dùng mặc định: $error');
      return const EffectSettings();
    }
  }

  Future<void> set(String key, bool value) async {
    try {
      await _repository.setBool(key, value);
    } catch (error) {
      // Vẫn đổi state: khoá là cosmetic, UI phải phản hồi dù ghi DB hỏng.
      debugPrint('Không lưu được khoá hiệu ứng $key: $error');
    }
    final s = state;
    state = s.copyWith(
      stars: key == _keys.stars ? value : null,
      rainbowRule: key == _keys.rainbowRule ? value : null,
      captureSweep: key == _keys.captureSweep ? value : null,
      confetti: key == _keys.confetti ? value : null,
      mosaic: key == _keys.mosaic ? value : null,
      chartSpendRamp: key == _keys.chartSpendRamp ? value : null,
    );
  }
}

final effectsProvider =
    StateNotifierProvider<EffectSettingsNotifier, EffectSettings>(
      (ref) => EffectSettingsNotifier(),
    );
