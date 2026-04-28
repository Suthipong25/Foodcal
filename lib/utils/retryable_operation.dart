// Utilities for implementing retry logic with exponential backoff.
// Handles temporary network failures and Firebase service disruptions.
import '../constants/app_config.dart';
import 'app_logger.dart';

typedef AsyncOperation<T> = Future<T> Function();
typedef ErrorHandler = void Function(String error, int attemptNumber);

class RetryableOperation {
  /// Execute an async operation with automatic retry on failure
  ///
  /// Returns the result if successful, or throws the last exception if all retries fail
  static Future<T> execute<T>({
    required AsyncOperation<T> operation,
    required String operationName,
    int maxAttempts = AppConfig.maxRetryAttempts,
    Duration initialDelay = AppConfig.initialRetryDelay,
    ErrorHandler? onError,
  }) async {
    Duration delay = initialDelay;
    Exception? lastException;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (attempt > 1) {
          AppLogger.warn(
            '[$operationName] Retry attempt $attempt/$maxAttempts after ${delay.inMilliseconds}ms',
          );
          await Future.delayed(delay);
        }

        final result =
            await operation().timeout(AppConfig.firebaseWriteTimeout);

        if (attempt > 1) {
          AppLogger.info('[$operationName] Succeeded on attempt $attempt');
        }

        return result;
      } catch (e) {
        lastException = Exception(e.toString());

        final errorMessage = _categorizeError(e);
        AppLogger.warn(
          '[$operationName] Attempt $attempt failed: $errorMessage',
        );

        onError?.call(errorMessage, attempt);

        // Don't retry on certain errors
        if (_shouldNotRetry(e)) {
          AppLogger.warn(
              '[$operationName] Error is not retryable, stopping attempts');
          rethrow;
        }

        // Double the delay for next attempt (exponential backoff)
        delay = Duration(milliseconds: delay.inMilliseconds * 2);

        // Cap the delay at 10 seconds
        if (delay.inSeconds > 10) {
          delay = const Duration(seconds: 10);
        }

        if (attempt == maxAttempts) {
          AppLogger.error(
            '[$operationName] All $maxAttempts attempts failed',
          );
        }
      }
    }

    throw lastException ??
        Exception('Operation failed after $maxAttempts attempts');
  }

  /// Categorize error type for debugging and user feedback
  static String _categorizeError(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout') || errorString.contains('deadline')) {
      return 'Network timeout - please check your connection';
    }

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return 'Network error - please check your connection';
    }

    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Permission denied - contact support if issue persists';
    }

    if (errorString.contains('not-found') ||
        errorString.contains('not found')) {
      return 'Resource not found';
    }

    if (errorString.contains('invalid') || errorString.contains('malformed')) {
      return 'Invalid data format';
    }

    return error.toString();
  }

  /// Determine if an error should be retried
  static bool _shouldNotRetry(Object error) {
    final errorString = error.toString().toLowerCase();

    // Don't retry authentication errors
    if (errorString.contains('invalid-credential') ||
        errorString.contains('permission-denied') ||
        errorString.contains('authentication')) {
      return true;
    }

    // Don't retry validation errors
    if (errorString.contains('invalid') && errorString.contains('argument')) {
      return true;
    }

    // Don't retry not found errors (they won't change on retry)
    if (errorString.contains('not-found') ||
        errorString.contains('not found')) {
      return true;
    }

    return false;
  }
}
