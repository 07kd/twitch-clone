import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twitch_clone/model/signup_model.dart';

part 'signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit() : super(SignupInitial());

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<void> signupUser(
      {required String email,
      required String password,
      required String username}) async {
    try {
      emit(SignupLoading());

      UserCredential cred = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      SignupModel sinup =
          SignupModel(uid: cred.user!.uid, username: username, email: email);

      await _firebaseFirestore
          .collection("users")
          .doc(cred.user!.uid)
          .set(sinup.toMap());

      emit(SignupSuccess(signupModel: sinup));
    } catch (e) {
      emit(SignupError(error: e.toString()));
    }
  }
}
