import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twitch_clone/model/signup_model.dart';

class FirebaseMethodsCubit extends Cubit<SignupModel?> {
  FirebaseMethodsCubit() : super(null);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  Future<void> endLiveStream({required String channelID}) async {
    try {
      QuerySnapshot snap = await _firestore
          .collection("livestream")
          .doc(channelID)
          .collection("comments")
          .get();

      for (int i = 0; i < snap.docs.length; i++) {
        await _firestore
            .collection("livestream")
            .doc(channelID)
            .collection("comments")
            .doc(
              ((snap.docs[i].data()! as dynamic)["commentId"]),
            )
            .delete();
      }
      await _firestore.collection("livestream").doc(channelID).delete();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateViewCount(
      {required String channelID, required bool isIncrease}) async {
    try {
      await _firestore.collection("livestream").doc(channelID).update({
        "viewers": FieldValue.increment(isIncrease ? 1 : -1),
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
