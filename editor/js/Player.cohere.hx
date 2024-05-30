import js.Browser.Window;

class Player {
    public function new(editor: Editor) {
        var container = new UIPanel();
        container.id = 'player';
        container.position = 'absolute';
        container.display = 'none';

        var player = new APP.Player();
        container.dom.appendChild(player.dom);

        Window.addEventListener('resize', function() {
            player.setSize(container.dom.clientWidth, container.dom.clientHeight);
        });

        editor.signals.windowResize.add(function() {
            player.setSize(container.dom.clientWidth, container.dom.clientHeight);
        });

        editor.signals.startPlayer.add(function() {
            container.display = '';
            player.load(editor.toJSON());
            player.setSize(container.dom.clientWidth, container.dom.clientHeight);
            player.play();
        });

        editor.signals.stopPlayer.add(function() {
            container.display = 'none';
            player.stop();
            player.dispose();
        });

        return container;
    }
}

class UIPanel {
    public var id: String;
    public var position: String;
    public var display: String;
    public var dom: HTMLElement;

    public function new() {
        dom = window.document.createElement('div');
    }

    public function setId(id: String) {
        this.id = id;
        dom.id = id;
    }

    public function setPosition(position: String) {
        this.position = position;
        dom.style.position = position;
    }

    public function setDisplay(display: String) {
        this.display = display;
        dom.style.display = display;
    }
}

class APP {
    public class Player {
        public var dom: HTMLElement;

        public function new() {
            dom = window.document.createElement('div');
        }

        public function setSize(width: Int, height: Int) {
            // Implement setSize logic here
        }

        public function load(data: Json) {
            // Implement load logic here
        }

        public function play() {
            // Implement play logic here
        }

        public function stop() {
            // Implement stop logic here
        }

        public function dispose() {
            // Implement dispose logic here
        }
    }
}

class Editor {
    public var signals: Signals;

    public function toJSON(): Json {
        // Implement toJSON logic here
    }
}

class Signals {
    public var windowResize: Signal;
    public var startPlayer: Signal;
    public var stopPlayer: Signal;

    public function new() {
        windowResize = new Signal();
        startPlayer = new Signal();
        stopPlayer = new Signal();
    }

    public function add(callback: Void->Void) {
        windowResize.add(callback);
        startPlayer.add(callback);
        stopPlayer.add(callback);
    }
}

class Signal {
    public function add(callback: Void->Void) {
        // Implement Signal logic here
    }
}