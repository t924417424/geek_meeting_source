// import 'dart:html';
// import 'dart:math';
// import 'dart:async';

// class AudioMaker {
//   List<String> urls;
//   AudioContext context;
//   List<AudioBuffer> buffers;

//   Random random;

//   AudioMaker() {
//     this.urls = <String>[];
//     this.context = AudioContext();
//     this.buffers = <AudioBuffer>[];
//     this.random = Random(0);
//   }

//   void checkAndStart() {
//     if (buffers.length == urls.length) {
//       Timer timer = Timer.repeating(500, this.startAudio);
//     }
//   }

//   void startAudio(Timer timer) {
//     int index = random.nextInt(this.buffers.length);
//     print("Audio played [${index}].");
//     AudioBufferSourceNode source = context.createBufferSource();
//     source.buffer = this.buffers[index];
//     source.connect(context.destination, 0, 0);
//     source.start(0);
//   }

//   void _decodeAudio(url) {
//     HttpRequest hr = new HttpRequest.get(url, (req) {
//       this.context.decodeAudioData(req.response, (audio_buff) {
//         print("${url} decoded.");
//         this.buffers.add(audio_buff);
//         checkAndStart();
//       }, (evt) {
//         print("Error");
//       });
//     });
//     hr.responseType = "arraybuffer";
//   }

//   void loadAndStart() {
//     for (String url in this.urls) {
//       this._decodeAudio(url);
//     }
//   }
// }
