import js.Browser.window;
import js.html.Element;
import three.js.editor.js.libs.ui.UIPanel;
import three.js.editor.js.libs.app.APP.Player;

class Player {

    public function new(editor:Dynamic) {

        var signals = editor.signals;

        var container = new UIPanel();
        container.setId('player');
        container.setPosition('absolute');
        container.setDisplay('none');

        var player = new APP.Player();
        container.dom.appendChild(player.dom);

        window.addEventListener('resize', function () {
            player.setSize(container.dom.clientWidth, container.dom.clientHeight);
        });

        signals.windowResize.add(function () {
            player.setSize(container.dom.clientWidth, container.dom.clientHeight);
        });

        signals.startPlayer.add(function () {
            container.setDisplay('');
            player.load(editor.toJSON());
            player.setSize(container.dom.clientWidth, container.dom.clientHeight);
            player.play();
        });

        signals.stopPlayer.add(function () {
            container.setDisplay('none');
            player.stop();
            player.dispose();
        });

        return container;

    }

}