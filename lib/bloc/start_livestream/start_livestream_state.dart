part of 'start_livestream_cubit.dart';

abstract class StartLivestreamState {}

final class StartLivestreamInitial extends StartLivestreamState {}

final class StartLivestreamLoading extends StartLivestreamState {}

final class StartLivestreamSuccess extends StartLivestreamState {}

final class StartLivestreamFailed extends StartLivestreamState {
  final String error;
  StartLivestreamFailed(this.error);
}
