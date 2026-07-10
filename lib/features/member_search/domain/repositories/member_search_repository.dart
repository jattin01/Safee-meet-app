import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/member_entity.dart';

abstract class MemberSearchRepository {
  Future<Either<Failure, MemberEntity>> searchByPIN(String pin);
  Future<Either<Failure, MemberEntity>> searchByQR(String qrCode);

  /// Members previously found via PIN/QR search, most recent first.
  /// Tracked server-side, so this survives app reinstalls.
  Future<Either<Failure, List<MemberEntity>>> getRecentSearches();
}
