import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/member_entity.dart';

abstract class MemberSearchRepository {
  Future<Either<Failure, MemberEntity>> searchByPIN(String pin);
  Future<Either<Failure, MemberEntity>> searchByQR(String qrCode);
  Future<Either<Failure, List<String>>> getRecentSearches();
}
