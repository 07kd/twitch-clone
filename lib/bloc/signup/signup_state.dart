part of 'signup_cubit.dart';

abstract class SignupState {}

final class SignupInitial extends SignupState {}

final class SignupLoading extends SignupState {}

final class SignupSuccess extends SignupState {
  final SignupModel signupModel;

  SignupSuccess({
    required this.signupModel,
  });
}

final class SignupError extends SignupState {
  final String error;
  SignupError({required this.error});
}
