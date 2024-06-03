import js.html.Window;
import ui.UIPanel;
import app.APP;

class Player {

    public function new(editor: Dynamic) {

        var signals: Dynamic = editor.signals;

        var container: UIPanel = new UIPanel();
        container.setId('player');
        container.setPosition('absolute');
        container.setDisplay('none');

        //

        var player: APP.Player = new APP.Player();
        container.dom.appendChild(player.dom);

        var resizeFunc: Void -> Void = function() {
            player.setSize(container.dom.clientWidth, container.dom.clientHeight);
        };

        Window.current.onresize = resizeFunc;

        signals.windowResize.add(resizeFunc);

        signals.startPlayer.add(function() {
            container.setDisplay('');
            player.load(editor.toJSON());
            player.setSize(container.dom.clientWidth, container.dom.clientHeight);
            player.play();
        });

        signals.stopPlayer.add(function() {
            container.setDisplay('none');
            player.stop();
            player.dispose();
        });

        return container;
    }
}