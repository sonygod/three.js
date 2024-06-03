import ui.UIBreak;
import ui.UIButton;
import ui.UIInteger;
import ui.UIPanel;
import ui.UIRow;
import ui.UIText;

import app.APP;

class SidebarProjectVideo {
    public function new(editor:Editor) {
        var strings = editor.strings;

        var container = new UIPanel();
        container.setId('render');

        // Video
        container.add(new UIText(strings.getKey('sidebar/project/video')).setTextTransform('uppercase'));
        container.add(new UIBreak());
        container.add(new UIBreak());

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
        renderButton.onClick(async () => {
            var player = new APP.Player();
            player.load(editor.toJSON());
            player.setPixelRatio(1);
            player.setSize(videoWidth.getValue(), videoHeight.getValue());

            // Rest of the renderButton's onClick function...
            // Note: Haxe does not support ES modules, so FFmpeg related code is not included here
        });
        container.add(renderButton);

        return container;
    }
}