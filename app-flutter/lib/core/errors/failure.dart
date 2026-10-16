abstract class Failure {
  final String message;
  final int? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
