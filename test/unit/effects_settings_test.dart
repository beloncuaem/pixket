import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/data/repositories/app_settings_repository.dart';
import 'package:pixket/providers/app_settings_provider.dart';

import '../support/memory_settings.dart';

/// Repository luôn ném: kiểm chứng nhánh fallback của `_load`/`set`.
class _BrokenSettings extends AppSettingsRepository {
  @override
  Future<String?> getString(String key) async => throw StateError('db hỏng');

  @override
  Future<void> setString(String key, String value) async =>
      throw StateError('db hỏng');
}

void main() {
  test('getBool/setBool round-trip và fallback', () async {
    final repo = MemorySettingsRepository();
    expect(await repo.getBool('k', fallback: true), isTrue);
    await repo.setBool('k', false);
    expect(await repo.getBool('k', fallback: true), isFalse);
    await repo.setBool('k', true);
    expect(await repo.getBool('k', fallback: false), isTrue);
  });

  test('6 key hiệu ứng đọc/ghi đúng qua repository', () async {
    final repo = MemorySettingsRepository();
    final notifier = EffectSettingsNotifier(repository: repo);
    await notifier.loadComplete;

    // Mặc định spec §11: chỉ mosaic tắt.
    expect(notifier.state.stars, isTrue);
    expect(notifier.state.rainbowRule, isTrue);
    expect(notifier.state.captureSweep, isTrue);
    expect(notifier.state.confetti, isTrue);
    expect(notifier.state.mosaic, isFalse);
    expect(notifier.state.chartSpendRamp, isTrue);

    await notifier.set('fx_stars', false);
    expect(notifier.state.stars, isFalse);
    expect(repo.store['fx_stars'], 'false');

    final again = EffectSettingsNotifier(repository: repo);
    await again.loadComplete;
    expect(again.state.stars, isFalse, reason: 'giá trị phải bền qua phiên');
  });

  test('repository lỗi thì về mặc định và không ném', () async {
    final notifier = EffectSettingsNotifier(repository: _BrokenSettings());
    await notifier.loadComplete;
    expect(notifier.state.stars, isTrue);
    expect(notifier.state.mosaic, isFalse);

    await notifier.set('fx_stars', false);
    expect(notifier.state.stars, isFalse, reason: 'UI vẫn đổi dù ghi hỏng');
  });
}
