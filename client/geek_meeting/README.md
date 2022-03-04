# geek_meeting

基于webrtc的视频会议系统前端，目前只支持完整功能发布到web端，其余端待适配

## dependencies
 - flutter_webrtc
 - get

 ## Future
 - [x] SFU_SERVER
 - [x] AddTrack
 - [ ] [P2P to SFU](https://webrtc.org.cn/20191022-sfu-p2p/)

 ## Install
   * 安装flutter环境（项目已兼容NullSafe）
   * 修改项目后端地址：

      * [后端接口服务器地址](./lib/utils/net.dart#L29)
      * [后端信令服务器地址](./lib/models/metting/meeting_room.dart#L19)
      * [iceServer修改（stun/turn服务）](./lib/models/metting/meeting_room.dart#L208)
   * 构建项目到web端：`flutter build web`
   * 由于浏览器安全策略，要求在非本地IP的时候需要前后端必须同为https/wss才可以正常使用

 ## about

 - 此仓库为视频会议前端源码，项目采用flutter web进行开发，故简单修改即可支持对端发布
 - 项目后端采用Go/Rust进行开发，开发优先采用Go语言进行开发，如无特殊需求，暂不考虑使用Rust重构后端项目
 - 因考虑到项目为多人会议系统，而非一对一视频通话，故项目并非采用传统webrtc的p2p架构，而是经由后端sfu服务器进行中转，故对服务器的带宽有一定的要求，后续计划根据参会人数来自动进行协议选择
 - 开发人员：
    - 联系QQ：924417424
