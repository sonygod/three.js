import js.Browser.alert;
import Commands.*;

class History {
    var editor:Editor;
    var undos:Array<Command>;
    var redos:Array<Command>;
    var lastCmdTime:Float;
    var idCounter:Int;
    var historyDisabled:Bool;
    var config:Dynamic;

    public function new(editor:Editor) {
        this.editor = editor;
        this.undos = [];
        this.redos = [];
        this.lastCmdTime = js.Date.now();
        this.idCounter = 0;
        this.historyDisabled = false;
        this.config = editor.config;

        var scope = this;

        editor.signals.startPlayer.add(function() {
            scope.historyDisabled = true;
        });

        editor.signals.stopPlayer.add(function() {
            scope.historyDisabled = false;
        });
    }

    public function execute(cmd:Command, optionalName:String = null) {
        var lastCmd = this.undos[this.undos.length - 1];
        var timeDifference = js.Date.now() - this.lastCmdTime;

        var isUpdatableCmd = lastCmd != null &&
                             lastCmd.updatable &&
                             cmd.updatable &&
                             lastCmd.object == cmd.object &&
                             lastCmd.type == cmd.type &&
                             lastCmd.script == cmd.script &&
                             lastCmd.attributeName == cmd.attributeName;

        if (isUpdatableCmd && cmd.type == 'SetScriptValueCommand') {

            lastCmd.update(cmd);
            cmd = lastCmd;

        } else if (isUpdatableCmd && timeDifference < 500) {

            lastCmd.update(cmd);
            cmd = lastCmd;

        } else {

            this.undos.push(cmd);
            cmd.id = ++this.idCounter;

        }

        cmd.name = optionalName != null ? optionalName : cmd.name;
        cmd.execute();
        cmd.inMemory = true;

        if (this.config.getKey('settings/history')) {

            cmd.json = cmd.toJSON();

        }

        this.lastCmdTime = js.Date.now();

        this.redos = [];
        this.editor.signals.historyChanged.dispatch(cmd);
    }

    public function undo():Command {
        if (this.historyDisabled) {

            alert(this.editor.strings.getKey('prompt/history/forbid'));
            return null;

        }

        var cmd = this.undos.pop();

        if (cmd != null && !cmd.inMemory) {

            cmd.fromJSON(cmd.json);

        }

        if (cmd != null) {

            cmd.undo();
            this.redos.push(cmd);
            this.editor.signals.historyChanged.dispatch(cmd);

        }

        return cmd;
    }

    public function redo():Command {
        if (this.historyDisabled) {

            alert(this.editor.strings.getKey('prompt/history/forbid'));
            return null;

        }

        var cmd = this.redos.pop();

        if (cmd != null && !cmd.inMemory) {

            cmd.fromJSON(cmd.json);

        }

        if (cmd != null) {

            cmd.execute();
            this.undos.push(cmd);
            this.editor.signals.historyChanged.dispatch(cmd);

        }

        return cmd;
    }

    public function toJSON():Dynamic {
        var history = {
            undos: [],
            redos: []
        };

        if (!this.config.getKey('settings/history')) {

            return history;

        }

        for (var i in this.undos) {

            if (this.undos[i].json != null) {

                history.undos.push(this.undos[i].json);

            }

        }

        for (var i in this.redos) {

            if (this.redos[i].json != null) {

                history.redos.push(this.redos[i].json);

            }

        }

        return history;
    }

    public function fromJSON(json:Dynamic) {
        if (json == null) return;

        for (var i in json.undos) {

            var cmdJSON = json.undos[i];
            var cmd = Type.createInstance(Type.resolveClass(Commands), [this.editor]);
            cmd.json = cmdJSON;
            cmd.id = cmdJSON.id;
            cmd.name = cmdJSON.name;
            this.undos.push(cmd);
            this.idCounter = cmdJSON.id > this.idCounter ? cmdJSON.id : this.idCounter;

        }

        for (var i in json.redos) {

            var cmdJSON = json.redos[i];
            var cmd = Type.createInstance(Type.resolveClass(Commands), [this.editor]);
            cmd.json = cmdJSON;
            cmd.id = cmdJSON.id;
            cmd.name = cmdJSON.name;
            this.redos.push(cmd);
            this.idCounter = cmdJSON.id > this.idCounter ? cmdJSON.id : this.idCounter;

        }

        this.editor.signals.historyChanged.dispatch(this.undos[this.undos.length - 1]);
    }

    public function clear() {
        this.undos = [];
        this.redos = [];
        this.idCounter = 0;

        this.editor.signals.historyChanged.dispatch();
    }

    public function goToState(id:Int) {
        if (this.historyDisabled) {

            alert(this.editor.strings.getKey('prompt/history/forbid'));
            return;

        }

        this.editor.signals.sceneGraphChanged.active = false;
        this.editor.signals.historyChanged.active = false;

        var cmd = this.undos.length > 0 ? this.undos[this.undos.length - 1] : null;

        if (cmd == null || id > cmd.id) {

            cmd = this.redo();
            while (cmd != null && id > cmd.id) {

                cmd = this.redo();

            }

        } else {

            while (true) {

                cmd = this.undos[this.undos.length - 1];

                if (cmd == null || id == cmd.id) break;

                this.undo();

            }

        }

        this.editor.signals.sceneGraphChanged.active = true;
        this.editor.signals.historyChanged.active = true;

        this.editor.signals.sceneGraphChanged.dispatch();
        this.editor.signals.historyChanged.dispatch(cmd);
    }

    public function enableSerialization(id:Int) {
        this.goToState(-1);

        this.editor.signals.sceneGraphChanged.active = false;
        this.editor.signals.historyChanged.active = false;

        var cmd = this.redo();
        while (cmd != null) {

            if (cmd.json == null) {

                cmd.json = cmd.toJSON();

            }

            cmd = this.redo();

        }

        this.editor.signals.sceneGraphChanged.active = true;
        this.editor.signals.historyChanged.active = true;

        this.goToState(id);
    }
}