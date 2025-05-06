import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:twitch_clone/bloc/firebase/firebase_methods.dart';
import 'package:twitch_clone/main.dart';
import 'package:twitch_clone/model/livestream.dart';
import 'package:twitch_clone/supabase/upload_image.dart';
part 'start_livestream_state.dart';

class StartLivestreamCubit extends Cubit<StartLivestreamState> {
  StartLivestreamCubit() : super(StartLivestreamInitial());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//  String photoUrl = await uploadPostsToSupabaseStorage(file!);
  Future<void> startlivestreamMethod({
    required BuildContext context,
    required String title,
    required Uint8List? image,
  }) async {
    try {
      emit(StartLivestreamLoading());
      final userCubit = context.read<FirebaseMethodsCubit>();
      await userCubit.getCurrentUser(FirebaseAuth.instance.currentUser!.uid);
      final user = userCubit.state;
      if (user == null) {
        emit(StartLivestreamFailed('User data not found'));
        return;
      }

      if (!((await _firestore
              .collection("livestream")
              .doc("${user.uid}${user.username}")
              .get())
          .exists)) {
        String channelID = "${user.uid}${user.username}";

        if (title.isNotEmpty && image != null) {
          String downloadUrl = await uploadToSupabaseStorage(image);
          LiveStream liveStream = LiveStream(
              title: title,
              image: downloadUrl,
              uid: user.uid,
              username: user.username,
              viewers: 0,
              channelId: channelID,
              startedAt: DateTime.now());

          await _firestore
              .collection("livestream")
              .doc(channelID)
              .set(liveStream.toMap());
          emit(StartLivestreamSuccess(channelID: channelID));
        } else {
          emit(StartLivestreamFailed("Please enter all the fields"));
        }
      } else {
        emit(StartLivestreamFailed(
            "Two live stream cannot be start at the same time"));
      }
    } catch (e) {
      emit(StartLivestreamFailed(e.toString()));
    }
  }
}
