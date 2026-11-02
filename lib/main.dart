import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'data/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPrint ủy quyền cho print nên vẫn ghi logcat ở bản release. Tắt nó
  // trong release để stack trace và chi tiết lỗi backend không rơi ra log máy.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await DatabaseHelper.instance.database;
  await SupabaseConfig.initialize();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: PixketApp()));
}
