# Promo video

39 s narrated ad (female voice vi-VN-HoaiMyNeural, rate -6%, pitch -8Hz),
portrait gameplay from the web demo build, the "Đồng quê" theme ducked under
the voice, a few game sound effects and Vietnamese subtitles.

1. `flutter build web --release`, serve `build/web` on :8790.
2. `node capture.js frames all` (NODE_PATH = a Playwright install): records
   each scene at 1080x1920 with the game slowed down (`?slow=5`, see
   lib/main.dart: timeDilation + a slowed Farm.now) so every frame is caught;
   `?ripe=1` makes the fields ripe for the swipe-harvest shot.
3. Voice lines from script.json (needs `npm i node-edge-tts@1.2.11`):
   `node say.js vi-VN-HoaiMyNeural -6% -8Hz voice/<id>.raw.mp3 "<line>"`, then
   ffmpeg `silenceremove ... loudnorm=I=-16:TP=-1.5:LRA=11` → voice/<id>.wav.
   The service answers 429 if called too fast: retry after a pause.
4. `node build.js` (FF points at a local ffmpeg 8.1 build) writes
   out/mua-lua-chin-promo-9x16.mp4 and -16x9.mp4 (copied to store/video/,
   gitignored). Posting texts: store/youtube/promo-youtube.txt.
