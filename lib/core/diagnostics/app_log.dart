import 'package:flutter/foundation.dart';

/// Ölçüm değerlerini veya dosya içeriğini günlüğe yazmaz.
void logFailure(String operation, Object error, StackTrace stack) {
  if (kDebugMode) {
    debugPrint('[TansiyonŞeker] $operation başarısız: ${error.runtimeType}');
    if (error is! FormatException) debugPrint('$error');
    debugPrintStack(stackTrace: stack);
  }
}
