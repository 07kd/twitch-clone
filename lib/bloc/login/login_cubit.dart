import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> loginUser(
      {required String email, required String password}) async {
    try {
      emit(LoginLoading());
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      emit(LoginSuccess());
    } catch (e) {
      emit(LoginFailed(error: e.toString()));
    }
  }
}
