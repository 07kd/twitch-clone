import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twitch_clone/bloc/firebase/firebase_methods.dart';
import 'package:twitch_clone/bloc/start_livestream/start_livestream_cubit.dart';
import 'package:twitch_clone/config/appid.dart';
import 'package:twitch_clone/responsive/resonsive_layout.dart';
import 'package:twitch_clone/screens/home_screen.dart';
import 'package:twitch_clone/widgets/chat.dart';
import 'package:twitch_clone/widgets/custom_button.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

class BroadcastScreen extends StatefulWidget {
  final bool isBroadcaster;
  final String channelId;

  const BroadcastScreen({
    super.key,
    required this.isBroadcaster,
    required this.channelId,
  });

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  late final RtcEngine _engine;
  List<int> remoteUid = [];
  bool _localUserJoined = false;
  bool _isLoading = true;
  bool switchCamera = true;
  bool isMuted = false;
  bool isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    // _initAgora();
    _initEngine();
  }

  void _initEngine() async {
    _engine = await RtcEngine.createWithContext(RtcEngineContext(appId));
    _addListeners();

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    if (widget.isBroadcaster) {
      _engine.setClientRole(ClientRole.Broadcaster);
    } else {
      _engine.setClientRole(ClientRole.Audience);
    }
    _joinChannel();
  }

  void _addListeners() {
    _engine.setEventHandler(
        RtcEngineEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
      debugPrint('joinChannelSuccess $channel $uid $elapsed');
    }, userJoined: (uid, elapsed) {
      debugPrint('userJoined $uid $elapsed');
      setState(() {
        remoteUid.add(uid);
      });
    }, userOffline: (uid, reason) {
      debugPrint('userOffline $uid $reason');
      setState(() {
        remoteUid.removeWhere((element) => element == uid);
      });
    }, leaveChannel: (stats) {
      debugPrint('leaveChannel $stats');
      setState(() {
        remoteUid.clear();
      });
    }, tokenPrivilegeWillExpire: (token) async {
      //  await getToken();
      await _engine.renewToken(token);
    }));
  }

  void _joinChannel() async {
    // await getToken();
    //if (token != null) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
    // await _engine.joinChannelWithUserAccount(
    //   token,
    //   widget.channelId,
    //   Provider.of<UserProvider>(context, listen: false).user.uid,
    // );
    // }
  }

  void _switchCamera() {
    _engine.switchCamera().then((value) {
      setState(() {
        switchCamera = !switchCamera;
      });
    }).catchError((err) {
      debugPrint('switchCamera $err');
    });
  }

  void onToggleMute() async {
    setState(() {
      isMuted = !isMuted;
    });
    await _engine.muteLocalAudioStream(isMuted);
  }

  // Future<void> _initAgora() async {
  //   await [Permission.microphone, Permission.camera].request();

  //   final cameraStatus = await Permission.camera.status;
  //   final micStatus = await Permission.microphone.status;
  //   if (!cameraStatus.isGranted || !micStatus.isGranted) {
  //     debugPrint("Permissions not granted");
  //     return;
  //   }

  //   _engine = createAgoraRtcEngine();
  //   await _engine.initialize(RtcEngineContext(appId: appId));

  //   _engine.registerEventHandler(
  //     RtcEngineEventHandler(
  //       onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //         debugPrint("Local user ${connection.localUid} joined");
  //         setState(() => _localUserJoined = true);
  //       },
  //       onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  //         debugPrint("Remote user $remoteUid joined");
  //         setState(() => remoteUids.add(remoteUid));
  //       },
  //       onUserOffline: (RtcConnection connection, int remoteUid,
  //           UserOfflineReasonType reason) {
  //         debugPrint("Remote user $remoteUid left channel");
  //         setState(() => remoteUids.remove(remoteUid));
  //       },
  //     ),
  //   );

  //   await _engine.setClientRole(
  //     role: widget.isBroadCaster
  //         ? ClientRoleType.clientRoleBroadcaster
  //         : ClientRoleType.clientRoleAudience,
  //   );

  //   await _engine.enableVideo();
  //   await _engine.startPreview();

  //   final userCubit = context.read<FirebaseMethodsCubit>();
  //   await userCubit.getCurrentUser(FirebaseAuth.instance.currentUser!.uid);
  //   final user = userCubit.state;

  //   try {
  //     await _engine.joinChannelWithUserAccount(
  //       token: tempToken,
  //       channelId: widget.channelId,
  //       userAccount: user!.uid,
  //     );
  //   } catch (e) {
  //     debugPrint("Error joining channel: $e");
  //   }

  //   setState(() => _isLoading = false);
  // }

  Future<void> _leaveChannel() async {
    final firestoreMethod = context.read<FirebaseMethodsCubit>();
    final startLivestreamCubit = context.read<StartLivestreamCubit>();
    final state = startLivestreamCubit.state;

    await _engine.leaveChannel();

    if (state is StartLivestreamSuccess &&
        state.channelID == widget.channelId) {
      await firestoreMethod.endLiveStream(channelID: widget.channelId);
    } else {
      await firestoreMethod.updateViewCount(
          channelID: widget.channelId, isIncrease: false);
    }

    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    // await _engine.release();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _stopScreenShare() async {
    try {
      await _engine.stopScreenCapture();
      setState(() => isScreenSharing = false);
      debugPrint('Screen sharing stopped');
    } catch (e) {
      debugPrint('Error stopping screen share: $e');
    }
  }

  void _startScreenShare() {
    // Add implementation as needed
  }

  @override
  Widget build(BuildContext context) {
    // final user = Provider.of<UserProvider>(context).user;
    final userCubit = context.read<FirebaseMethodsCubit>();
    userCubit.getCurrentUser(FirebaseAuth.instance.currentUser!.uid);
    final state = userCubit.state;
    print("user name ${state?.username}");
    print("user uis ${state?.username}");

    return WillPopScope(
      onWillPop: () async {
        await _leaveChannel();
        return Future.value(true);
      },
      child: Scaffold(
        bottomNavigationBar: widget.isBroadcaster
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: CustomButton(
                  text: 'End Stream',
                  onTap: _leaveChannel,
                ),
              )
            : null,
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: ResponsiveLatout(
            desktopBody: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _renderVideo(state, isScreenSharing),
                      if ("${state!.uid}${state.username}" == widget.channelId)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: _switchCamera,
                              child: const Text('Switch Camera'),
                            ),
                            InkWell(
                              onTap: onToggleMute,
                              child: Text(isMuted ? 'Unmute' : 'Mute'),
                            ),
                            InkWell(
                              onTap: isScreenSharing
                                  ? _stopScreenShare
                                  : _startScreenShare,
                              child: Text(
                                isScreenSharing
                                    ? 'Stop ScreenSharing'
                                    : 'Start Screensharing',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Chat(channelId: widget.channelId),
              ],
            ),
            mobileBody: Column(
              children: [
                _renderVideo(state, isScreenSharing),
                if ("${state.uid}${state.username}" == widget.channelId)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _switchCamera,
                        child: const Text('Switch Camera'),
                      ),
                      InkWell(
                        onTap: onToggleMute,
                        child: Text(isMuted ? 'Unmute' : 'Mute'),
                      ),
                    ],
                  ),
                Expanded(
                  child: Chat(
                    channelId: widget.channelId,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _renderVideo(user, isScreenSharing) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: "${user.uid}${user.username}" == widget.channelId
          ? isScreenSharing
              ? kIsWeb
                  ? const RtcLocalView.SurfaceView.screenShare()
                  : const RtcLocalView.TextureView.screenShare()
              : const RtcLocalView.SurfaceView(
                  zOrderMediaOverlay: true,
                  zOrderOnTop: true,
                )
          : isScreenSharing
              ? kIsWeb
                  ? const RtcLocalView.SurfaceView.screenShare()
                  : const RtcLocalView.TextureView.screenShare()
              : remoteUid.isNotEmpty
                  ? kIsWeb
                      ? RtcRemoteView.SurfaceView(
                          uid: remoteUid[0],
                          channelId: widget.channelId,
                        )
                      : RtcRemoteView.TextureView(
                          uid: remoteUid[0],
                          channelId: widget.channelId,
                        )
                  : Container(),
    );
  }
}
