import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static const String appId = '55865bab6d804edeacdffc4a8621131b';
  RtcEngine? _engine;

  RtcEngine? get engine => _engine;
  
  Future<void> initialize() async {
    await [Permission.microphone, Permission.camera].request();
    
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    
    await _engine!.enableAudio();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }
  
  Future<void> joinChannel(String channelName, String token, int uid) async {
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }
  
  Future<void> leaveChannel() async {
    await _engine!.leaveChannel();
  }
  
  Future<void> muteLocalAudio(bool muted) async {
    await _engine!.muteLocalAudioStream(muted);
  }
  
  Future<void> enableLocalVideo(bool enabled) async {
    if (enabled) {
      await _engine!.enableVideo();
    } else {
      await _engine!.disableVideo();
    }
  }
  
  void dispose() {
    _engine?.release();
  }
}