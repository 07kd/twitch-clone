import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twitch_clone/model/signup_model.dart';

class FirebaseMethodsCubit extends Cubit<SignupModel?> {
  FirebaseMethodsCubit() : super(null);

  Future<void> getCurrentUser(String? uid) async {
    emit(null);

    try {
      final snap =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      emit(snap.exists ? SignupModel.fromMap(snap.data()!) : null);
    } catch (e) {
      emit(null);
    }
  }
}
