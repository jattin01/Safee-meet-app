import 'package:dio/dio.dart';
import 'failures.dart';

/// True for Dio failures caused by lack of connectivity/timeouts rather than
/// a real server response. Every repository's `_map(DioException)` used to
/// list these types itself, and none of them included `connectionError` —
/// the type Dio 5.x actually throws for a plain offline request (no wifi/data
/// at all). That gap made a genuinely-offline call fall through to each
/// repo's generic `ServerFailure('Server error')`/`UnauthorizedFailure`
/// branch instead of the proper "No internet connection" message.
bool isConnectivityError(DioException e) =>
    e.type == DioExceptionType.connectionTimeout ||
    e.type == DioExceptionType.sendTimeout ||
    e.type == DioExceptionType.receiveTimeout ||
    e.type == DioExceptionType.connectionError ||
    e.type == DioExceptionType.unknown;

/// Shared baseline mapping for the common cases (connectivity, 401/403) —
/// repositories that need extra per-status-code handling (404, 409, 422...)
/// should check `isConnectivityError` first, then layer their own status
/// checks on top, same shape as before but sharing the one connectivity
/// check instead of each repo re-listing (and drifting on) the DioException
/// types that count as "offline".
Failure mapDioException(DioException e, {String defaultMessage = 'Server error'}) {
  if (isConnectivityError(e)) return const NetworkFailure();

  final status = e.response?.statusCode;
  final responseData = e.response?.data;
  final message = responseData is Map ? responseData['message'] as String? : null;

  if (status == 401 || status == 403) return const UnauthorizedFailure();
  return ServerFailure(message ?? defaultMessage, statusCode: status);
}
