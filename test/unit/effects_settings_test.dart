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

  test('khoá chart_spend_ramp đọc/ghi đúng qua repository', () async {
    final repo = MemorySettingsRepository();
    final notifier = EffectSettingsNotifier(repository: repo);
    await notifier.loadComplete;

    expect(notifier.state.chartSpendRamp, isTrue);

    await notifier.set('chart_spend_ramp', false);
    expect(notifier.state.chartSpendRamp, isFalse);
    expect(repo.store['chart_spend_ramp'], 'false');

    final again = EffectSettingsNotifier(repository: repo);
    await again.loadComplete;
    expect(
      again.state.chartSpendRamp,
      isFalse,
      reason: 'giá trị phải bền qua phiên',
    );
  });

  test('khoá lạ không đổi state', () async {
    final notifier = EffectSettingsNotifier(
      repository: MemorySettingsRepository(),
    );
    await notifier.loadComplete;

    await notifier.set('fx_stars', false);
    expect(notifier.state.chartSpendRamp, isTrue);
  });

  test('repository lỗi thì về mặc định và không ném', () async {
    final notifier = EffectSettingsNotifier(repository: _BrokenSettings());
    await notifier.loadComplete;
    expect(notifier.state.chartSpendRamp, isTrue);

    await notifier.set('chart_spend_ramp', false);
    expect(
      notifier.state.chartSpendRamp,
      isFalse,
      reason: 'UI vẫn đổi dù ghi hỏng',
    );
  });
}
