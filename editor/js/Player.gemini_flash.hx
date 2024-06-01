import js.Browser;
import ui.UIPanel;
import app.APP;

class Player extends UIPanel {

    public function new(editor:Editor) {
        super();
        
        this.setId("player");
        this.setPosition("absolute");
        this.setDisplay("none");

        var player = new APP.Player();
        this.dom.appendChild(player.dom);

        Browser.window.addEventListener("resize", function(_) {
            player.setSize(this.dom.clientWidth, this.dom.clientHeight);
        });

        editor.signals.windowResize.add(function(_) {
            player.setSize(this.dom.clientWidth, this.dom.clientHeight);
        });

        editor.signals.startPlayer.add(function(_) {
            this.setDisplay("");
            player.load(editor.toJSON());
            player.setSize(this.dom.clientWidth, this.dom.clientHeight);
            player.play();
        });

        editor.signals.stopPlayer.add(function(_) {
            this.setDisplay("none");
            player.stop();
            player.dispose();
        });
    }
}