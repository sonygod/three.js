import js.Browser.window;
import js.html.Blob;
import js.html.Document;
import js.html.HTMLElement;
import js.html.HTMLImageElement;
import js.html.HTMLVideoElement;
import js.html.HTMLProgressElement;
import js.html.CanvasElement;

class SidebarProjectVideo {
    static public function new(editor:Editor) {
        var container = new UIPanel();
        container.setId('render');

        // Video
        container.add(new UIText(editor.strings.getKey('sidebar/project/video')).setTextTransform('uppercase'));
        container.add(new UIBreak());
        container.add(new UIBreak());

        // Resolution
        var resolutionRow = new UIRow();
        container.add(resolutionRow);

        resolutionRow.add(new UIText(editor.strings.getKey('sidebar/project/resolution')).setClass('Label'));

        var videoWidth = new UIInteger(1024).setTextAlign('center').setWidth('28px');
        resolutionRow.add(videoWidth);

        resolutionRow.add(new UIText('×').setTextAlign('center').setFontSize('12px').setWidth('12px'));

        var videoHeight = new UIInteger(1024).setTextAlign('center').setWidth('28px');
        resolutionRow.add(videoHeight);

        var videoFPS = new UIInteger(30).setTextAlign('center').setWidth('20px');
        resolutionRow.add(videoFPS);

        resolutionRow.add(new UIText('fps').setFontSize('12px'));

        // Duration
        var videoDurationRow = new UIRow();
        videoDurationRow.add(new UIText(editor.strings.getKey('sidebar/project/duration')).setClass('Label'));

        var videoDuration = new UIInteger(10);
        videoDurationRow.add(videoDuration);

        container.add(videoDurationRow);

        // Render
        var renderButton = new UIButton(editor.strings.getKey('sidebar/project/render'));
        renderButton.setWidth('170px');
        renderButton.setMarginLeft('120px');
        renderButton.onClick(function() {
            var player = new APP.Player();
            player.load(editor.toJSON());
            player.setPixelRatio(1);
            player.setSize(videoWidth.getValue(), videoHeight.getValue());

            var width = videoWidth.getValue() / window.devicePixelRatio;
            var height = videoHeight.getValue() / window.devicePixelRatio;

            var canvas = player.canvas;
            canvas.style.width = Std.string(width) + 'px';
            canvas.style.height = Std.string(height) + 'px';

            var left = (window.screen.width - width) / 2;
            var top = (window.screen.height - height) / 2;

            var output = window.open('', '_blank', 'location=no,left=$left,top=$top,width=$width,height=$height');

            var meta = new Document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0';
            output.document.head.appendChild(meta);

            output.document.body.style.background = '#000';
            output.document.body.style.margin = '0px';
            output.document.body.style.overflow = 'hidden';
            output.document.body.appendChild(canvas);

            var progress = new Document.createElement('progress');
            progress.style.position = 'absolute';
            progress.style.top = '10px';
            progress.style.left = Std.string((width - 170) / 2) + 'px';
            progress.style.width = '170px';
            progress.value = 0;
            output.document.body.appendChild(progress);

            var ffmpeg = new FFmpeg.createFFmpeg({ log: true });

            ffmpeg.load().then(function() {
                ffmpeg.setProgress(function(ratio) {
                    progress.value = (ratio * 0.5) + 0.5;
                });

                var fps = videoFPS.getValue();
                var duration = videoDuration.getValue();
                var frames = duration * fps;

                var currentTime = 0;

                var i = 0;
                while(i < frames) {
                    player.render(currentTime);

                    var num = i.toString().padStart(5, '0');
                    ffmpeg.FS('writeFile', 'tmp.$num.png', canvas.toDataURL());
                    currentTime += 1 / fps;

                    progress.value = (i / frames) * 0.5;

                    i++;
                }

                ffmpeg.run('-framerate', Std.string(fps), '-pattern_type', 'glob', '-i', '*.png', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'slow', '-crf', '5', 'out.mp4').then(function() {
                    var data = ffmpeg.FS('readFile', 'out.mp4');

                    var j = 0;
                    while(j < frames) {
                        var num = j.toString().padStart(5, '0');
                        ffmpeg.FS('unlink', 'tmp.$num.png');

                        j++;
                    }

                    output.document.body.removeChild(canvas);
                    output.document.body.removeChild(progress);

                    var video = new Document.createElement('video');
                    video.width = width;
                    video.height = height;
                    video.controls = true;
                    video.loop = true;
                    video.src = URL.createObjectURL(new Blob([data.buffer], { type: 'video/mp4' }));
                    output.document.body.appendChild(video);

                    player.dispose();
                });
            });
        });
        container.add(renderButton);

        return container;
    }
}