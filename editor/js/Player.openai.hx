package three.js.editor.js;

import ui.UIPanel;

class Player {
    private var editor:Dynamic;
    private var container:UIPanel;
    private var player:APP.Player;

    public function new(editor:Dynamic) {
        this.editor = editor;

        var signals = editor.signals;

        container = new UIPanel();
        container.setId('player');
        container.setPosition('absolute');
        container.setDisplay('none');

        player = new APP.Player();
        container.dom.appendChild(player.dom);

        js.Browser.window.addEventListener('resize', resizeHandler);
        signals.windowResize.add(resizeHandler);
        signals.startPlayer.add(startPlayerHandler);
        signals.stopPlayer.add(stopPlayerHandler);
    }

    private function resizeHandler(event:Dynamic) {
        player.setSize(container.dom.clientWidth, container.dom.clientHeight);
    }

    private function startPlayerHandler(event:Dynamic) {
        container.setDisplay('');
        player.load(editor.toJSON());
        player.setSize(container.dom.clientWidth, container.dom.clientHeight);
        player.play();
    }

    private function stopPlayerHandler(event:Dynamic) {
        container.setDisplay('none');
        player.stop();
        player.dispose();
    }
}