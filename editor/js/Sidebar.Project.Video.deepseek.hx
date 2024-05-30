import js.Browser.window;
import js.Browser.document;
import js.Browser.URL;
import js.Browser.Blob;
import js.Browser.screen;
import js.Browser.window.devicePixelRatio;
import js.Browser.window.open;
import js.Browser.document.createElement;
import js.Browser.document.head;
import js.Browser.document.body;
import js.Browser.document.body.style;
import js.Browser.document.body.appendChild;
import js.Browser.document.body.removeChild;

import three.js.editor.js.libs.ui.UIBreak;
import three.js.editor.js.libs.ui.UIButton;
import three.js.editor.js.libs.ui.UIInteger;
import three.js.editor.js.libs.ui.UIPanel;
import three.js.editor.js.libs.ui.UIRow;
import three.js.editor.js.libs.ui.UIText;

import three.js.editor.js.libs.app.APP;

class SidebarProjectVideo {

    public function new(editor:Dynamic) {

        var strings = editor.strings;

        var container = new UIPanel();
        container.setId('render');

        // Video

        container.add(new UIText(strings.getKey('sidebar/project/video')).setTextTransform('uppercase'));
        container.add(new UIBreak(), new UIBreak());

        // Resolution

        var resolutionRow = new UIRow();
        container.add(resolutionRow);

        resolutionRow.add(new UIText(strings.getKey('sidebar/project/resolution')).setClass('Label'));

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
        videoDurationRow.add(new UIText(strings.getKey('sidebar/project/duration')).setClass('Label'));

        var videoDuration = new UIInteger(10);
        videoDurationRow.add(videoDuration);

        container.add(videoDurationRow);

        // Render

        var renderButton = new UIButton(strings.getKey('sidebar/project/render'));
        renderButton.setWidth('170px');
        renderButton.setMarginLeft('120px');
        renderButton.onClick(function() {

            var player = new APP.Player();
            player.load(editor.toJSON());
            player.setPixelRatio(1);
            player.setSize(videoWidth.getValue(), videoHeight.getValue());

            //

            var width = videoWidth.getValue() / window.devicePixelRatio;
            var height = videoHeight.getValue() / window.devicePixelRatio;

            var canvas = player.canvas;
            canvas.style.width = width + 'px';
            canvas.style.height = height + 'px';

            var left = (screen.width - width) / 2;
            var top = (screen.height - height) / 2;

            var output = window.open('', '_blank', 'location=no,left=' + left + ',top=' + top + ',width=' + width + ',height=' + height);

            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0';
            output.document.head.appendChild(meta);

            output.document.body.style.background = '#000';
            output.document.body.style.margin = '0px';
            output.document.body.style.overflow = 'hidden';
            output.document.body.appendChild(canvas);

            var progress = document.createElement('progress');
            progress.style.position = 'absolute';
            progress.style.top = '10px';
            progress.style.left = ((width - 170) / 2) + 'px';
            progress.style.width = '170px';
            progress.value = 0;
            output.document.body.appendChild(progress);

            //

            var createFFmpeg = FFmpeg.createFFmpeg; // eslint-disable-line no-undef
            var fetchFile = FFmpeg.fetchFile; // eslint-disable-line no-undef
            var ffmpeg = createFFmpeg({log: true});

            ffmpeg.load();

            ffmpeg.setProgress(function({ratio}) {

                progress.value = (ratio * 0.5) + 0.5;

            });

            var fps = videoFPS.getValue();
            var duration = videoDuration.getValue();
            var frames = duration * fps;

            var currentTime = 0;

            for (i in 0...frames) {

                player.render(currentTime);

                var num = i.toString().padStart(5, '0');
                ffmpeg.FS('writeFile', 'tmp.' + num + '.png', fetchFile(canvas.toDataURL()));
                currentTime += 1 / fps;

                progress.value = (i / frames) * 0.5;

            }

            ffmpeg.run('-framerate', String(fps), '-pattern_type', 'glob', '-i', '*.png', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'slow', '-crf', String(5), 'out.mp4');

            var data = ffmpeg.FS('readFile', 'out.mp4');

            for (i in 0...frames) {

                var num = i.toString().padStart(5, '0');
                ffmpeg.FS('unlink', 'tmp.' + num + '.png');

            }

            output.document.body.removeChild(canvas);
            output.document.body.removeChild(progress);

            var video = document.createElement('video');
            video.width = width;
            video.height = height;
            video.controls = true;
            video.loop = true;
            video.src = URL.createObjectURL(new Blob([data.buffer], {type: 'video/mp4'}));
            output.document.body.appendChild(video);

            player.dispose();

        });
        container.add(renderButton);

        //

        return container;

    }

}