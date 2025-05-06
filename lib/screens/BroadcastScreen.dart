import 'package:agora_rtc_engine/agora_rtc_engine.dart';
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
import 'package:twitch_clone/screens/signup_screen.dart';
import 'package:twitch_clone/widgets/chat.dart';
import 'package:twitch_clone/widgets/custom_button.dart';

class BroadcastScreen extends StatefulWidget {
  final bool isBroadCaster;
  final String channelId;
  const BroadcastScreen(
      {super.key, required this.isBroadCaster, required this.channelId});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  late final RtcEngine _engine;
  int? _remoteUid;
  List<int> remoteUid = [];
  bool _localUserJoined = false;
  bool _isLoading = false;
  bool switchCamera = true;
  @override
  void initState() {
    _initAgora();

    super.initState();
  }

  Future<void> _initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
//listner
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );
    if (widget.isBroadCaster) {
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    } else {
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    }

    await _engine.enableVideo();
    await _engine.startPreview();
//join channerl
    // await _engine.joinChannelWithUserAccount(
    //   token: token,
    //   channelId: channel,s
    //   uid: 0,
    //   options: const ChannelMediaOptions(),
    // );
    final userCubit = context.read<FirebaseMethodsCubit>();
    await userCubit.getCurrentUser(FirebaseAuth.instance.currentUser!.uid);
    final user = userCubit.state;
    await _engine.joinChannelWithUserAccount(
        token: tempToken, channelId: "testing123", userAccount: user!.uid);
  }

  @override
  void dispose() {
    super.dispose();

    _dispose();
  }

  void _startScreenShare() {}

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

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  Future<void> _stopScreenShare() async {
    try {
      await _engine.stopScreenCapture();
      setState(() {
        isScreenSharing = false;
      });
      debugPrint('Screen sharing stopped successfully');
    } catch (e) {
      debugPrint('Error stopping screen share: $e');
    }
  }

  String? channelID;
  _leaveChannel() async {
    final firestoreMethod = context.read<FirebaseMethodsCubit>();

    await _engine.leaveChannel();

    final startLivestareCubit = context.read<StartLivestreamCubit>();

    final state = startLivestareCubit.state;

    if (state is StartLivestreamSuccess) {
      channelID = state.channelID;
    }
    if (channelID == widget.channelId) {
      firestoreMethod.endLiveStream(channelID: widget.channelId);
    } else {
      firestoreMethod.updateViewCount(
          channelID: widget.channelId, isIncrease: false);
    }
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  bool isMuted = false;
  bool isScreenSharing = false;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _leaveChannel();
        return Future.value(true);
      },
      child: Scaffold(
        bottomNavigationBar: widget.isBroadCaster
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: CustomButton(
                  text: 'End Stream',
                  onTap: () {},
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
                      // _renderVideo(user, isScreenSharing),
                      // if ("${user.uid}${user.username}" == widget.channelId)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {},
                            child: const Text('Switch Camera'),
                          ),
                          InkWell(
                            onTap: () {},
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
                //     Chat(channelId: widget.channelId),
              ],
            ),
            mobileBody: Column(
              children: [
                // _renderVideo(user, isScreenSharing),
                // if ("${user.uid}${user.username}" == widget.channelId)
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

  Widget _renderVideo() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Local view (for broadcaster)
        if (widget.isBroadCaster && _localUserJoined)
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0), // 0 for local view
            ),
          ),

        // Remote views
        for (final uid in remoteUid)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: uid),
              connection: RtcConnection(channelId: widget.channelId),
            ),
          ),

        // Fallback when no streams are available
        if (!widget.isBroadCaster && remoteUid.isEmpty)
          const Center(child: Text('No broadcast available')),
      ],
    );
  }
}
