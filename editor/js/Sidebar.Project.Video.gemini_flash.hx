import ui.UIBreak;
import ui.UIButton;
import ui.UIInteger;
import ui.UIPanel;
import ui.UIRow;
import ui.UIText;

import app.APP;
import js.Browser;
import js.html.CanvasElement;
import js.html.Element;
import js.html.ProgressEvent;
import js.html.VideoElement;

// Import FFmpeg types
@:native("FFmpeg") extern class FFmpeg {
  public static function createFFmpeg(config: Dynamic): FFmpegInstance;
  public static function fetchFile(url: String): Promise<Blob>;
}

// Define FFmpegInstance interface
@:native("FFmpegInstance") extern interface FFmpegInstance {
  function load(): Promise<Void>;
  function setProgress(callback: { function (data: { ratio: Float }): Void; }): Void;
  function FS(command: String, ?arg1: Dynamic, ?arg2: Dynamic, ?arg3: Dynamic, ?arg4: Dynamic, ?arg5: Dynamic, ?arg6: Dynamic, ?arg7: Dynamic, ?arg8: Dynamic, ?arg9: Dynamic, ?arg10: Dynamic): Dynamic;
  function run(arg1: String, ?arg2: Dynamic, ?arg3: Dynamic, ?arg4: Dynamic, ?arg5: Dynamic, ?arg6: Dynamic, ?arg7: Dynamic, ?arg8: Dynamic, ?arg9: Dynamic, ?arg10: Dynamic): Promise<Void>;
}

class SidebarProjectVideo {

  public function new(editor: Dynamic) {

    final strings = editor.strings;

    final container = new UIPanel();
    container.setId('render');

    // Video

    container.add(new UIText(strings.getKey('sidebar/project/video')).setTextTransform('uppercase'));
    container.add(new UIBreak(), new UIBreak());

    // Resolution

    final resolutionRow = new UIRow();
    container.add(resolutionRow);

    resolutionRow.add(new UIText(strings.getKey('sidebar/project/resolution')).setClass('Label'));

    final videoWidth = new UIInteger(1024).setTextAlign('center').setWidth('28px');
    resolutionRow.add(videoWidth);

    resolutionRow.add(new UIText('×').setTextAlign('center').setFontSize('12px').setWidth('12px'));

    final videoHeight = new UIInteger(1024).setTextAlign('center').setWidth('28px');
    resolutionRow.add(videoHeight);

    final videoFPS = new UIInteger(30).setTextAlign('center').setWidth('20px');
    resolutionRow.add(videoFPS);

    resolutionRow.add(new UIText('fps').setFontSize('12px'));

    // Duration

    final videoDurationRow = new UIRow();
    videoDurationRow.add(new UIText(strings.getKey('sidebar/project/duration')).setClass('Label'));

    final videoDuration = new UIInteger(10);
    videoDurationRow.add(videoDuration);

    container.add(videoDurationRow);

    // Render

    final renderButton = new UIButton(strings.getKey('sidebar/project/render'));
    renderButton.setWidth('170px');
    renderButton.setMarginLeft('120px');
    renderButton.onClick(async () -> {

      final player = new APP.Player();
      player.load(editor.toJSON());
      player.setPixelRatio(1);
      player.setSize(videoWidth.getValue(), videoHeight.getValue());

      //

      final width = videoWidth.getValue() / Browser.window.devicePixelRatio;
      final height = videoHeight.getValue() / Browser.window.devicePixelRatio;

      final canvas = player.canvas;
      canvas.style.width = '${width}px';
      canvas.style.height = '${height}px';

      final left = (Browser.window.screen.width - width) / 2;
      final top = (Browser.window.screen.height - height) / 2;

      final output = Browser.window.open('', '_blank', 'location=no,left=${left},top=${top},width=${width},height=${height}');

      final meta = Browser.document.createElement('meta');
      meta.name = 'viewport';
      meta.content = 'width=device-width, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0';
      output.document.head.appendChild(meta);

      output.document.body.style.background = '#000';
      output.document.body.style.margin = '0px';
      output.document.body.style.overflow = 'hidden';
      output.document.body.appendChild(canvas);

      final progress = Browser.document.createElement('progress');
      progress.style.position = 'absolute';
      progress.style.top = '10px';
      progress.style.left = '${((width - 170) / 2)}px';
      progress.style.width = '170px';
      progress.value = 0;
      output.document.body.appendChild(progress);

      //

      final ffmpeg = FFmpeg.createFFmpeg({log: true});

      await ffmpeg.load();

      ffmpeg.setProgress(({ratio}) -> {
        progress.value = (ratio * 0.5) + 0.5;
      });

      final fps = videoFPS.getValue();
      final duration = videoDuration.getValue();
      final frames = duration * fps;

      var currentTime = 0.0;

      for (i in 0...frames) {

        player.render(currentTime);

        final num = StringTools.lpad(Std.string(i), '0', 5);
        ffmpeg.FS('writeFile', 'tmp.${num}.png', await FFmpeg.fetchFile(cast(canvas, CanvasElement).toDataURL()));
        currentTime += 1 / fps;

        progress.value = (i / frames) * 0.5;

      }

      await ffmpeg.run('-framerate', Std.string(fps), '-pattern_type', 'glob', '-i', '*.png', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'slow', '-crf', Std.string(5), 'out.mp4');

      final data = ffmpeg.FS('readFile', 'out.mp4');

      for (i in 0...frames) {

        final num = StringTools.lpad(Std.string(i), '0', 5);
        ffmpeg.FS('unlink', 'tmp.${num}.png');

      }

      output.document.body.removeChild(canvas);
      output.document.body.removeChild(progress);

      final video = Browser.document.createElement('video');
      video.width = Std.int(width);
      video.height = Std.int(height);
      video.controls = true;
      video.loop = true;
      video.src = Browser.window.URL.createObjectURL(new Blob([cast(data.buffer, js.lib.Uint8Array)], {type: 'video/mp4'}));
      output.document.body.appendChild(video);

      player.dispose();

    });
    container.add(renderButton);

    //

    return container;

  }

}