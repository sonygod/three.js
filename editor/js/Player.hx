package three.js.editor.js;

import js.html.Element;
import js.Browser;
import js.html.Window;

class Player {
    private var editor:Dynamic;
    private var signals:Dynamic;
    private var container:UIPanel;
    private var player:APP.Player;

    public function new(editor:Dynamic) {
        this.editor = editor;
        signals = editor.signals;
        container = new UIPanel();
        container.setId('player');
        container.setPosition('absolute');
        container.setDisplay('none');

        player = new APP.Player();
        container.dom.appendChild(player.dom);

        Browser.window.addEventListener('resize', resizeHandler);

        signals.windowResize.add(resizeHandler);
        signals.startPlayer.add(startPlayerHandler);
        signals.stopPlayer.add(stopPlayerHandler);
    }

    private function resizeHandler(event:Dynamic):Void {
        player.setSize(container.dom.clientWidth, container.dom.clientHeight);
    }

    private function startPlayerHandler(event:Dynamic):Void {
        container.setDisplay('');
        player.load(editor.toJSON());
        player.setSize(container.dom.clientWidth, container.dom.clientHeight);
        player.play();
    }

    private function stopPlayerHandler(event:Dynamic):Void {
        container.setDisplay('none');
        player.stop();
        player.dispose();
    }
}