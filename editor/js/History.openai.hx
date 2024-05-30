package three.js.editor.js;

import Commands;

class History {
    public var editor:Editor;
    public var undos:Array<Command>;
    public var redos:Array<Command>;
    public var lastCmdTime:Int;
    public var idCounter:Int;
    public var historyDisabled:Bool;
    public var config:Config;

    public function new(editor:Editor) {
        this.editor = editor;
        this.undos = new Array<Command>();
        this.redos = new Array<Command>();
        this.lastCmdTime = Date.now().getTime();
        this.idCounter = 0;
        this.historyDisabled = false;
        this.config = editor.config;

        // signals
        var scope = this;
        editor.signals.startPlayer.add(function() {
            scope.historyDisabled = true;
        });
        editor.signals.stopPlayer.add(function() {
            scope.historyDisabled = false;
        });
    }

    public function execute(cmd:Command, optionalName:String = "") {
        var lastCmd = undos[undos.length - 1];
        var timeDifference = Date.now().getTime() - lastCmdTime;

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
            undos.push(cmd);
            cmd.id = ++idCounter;
        }

        cmd.name = optionalName != "" ? optionalName : cmd.name;
        cmd.execute();
        cmd.inMemory = true;

        if (config.getKey('settings/history')) {
            cmd.json = cmd.toJSON(); // serialize the cmd immediately after execution and append the json to the cmd
        }

        lastCmdTime = Date.now().getTime();

        // clearing all the redo-commands
        redos = new Array<Command>();
        editor.signals.historyChanged.dispatch(cmd);
    }

    public function undo():Command {
        if (historyDisabled) {
            alert(editor.strings.getKey('prompt/history/forbid'));
            return null;
        }

        var cmd:Command = undos.pop();
        if (cmd != null) {
            cmd.undo();
            redos.push(cmd);
            editor.signals.historyChanged.dispatch(cmd);
        }
        return cmd;
    }

    public function redo():Command {
        if (historyDisabled) {
            alert(editor.strings.getKey('prompt/history/forbid'));
            return null;
        }

        var cmd:Command = redos.pop();
        if (cmd != null) {
            cmd.execute();
            undos.push(cmd);
            editor.signals.historyChanged.dispatch(cmd);
        }
        return cmd;
    }

    public function toJSON():Dynamic {
        var history = {};
        history.undos = [];
        history.redos = [];

        if (!config.getKey('settings/history')) {
            return history;
        }

        // Append Undos to History
        for (i in 0...undos.length) {
            if (undos[i].json != null) {
                history.undos.push(undos[i].json);
            }
        }

        // Append Redos to History
        for (i in 0...redos.length) {
            if (redos[i].json != null) {
                history.redos.push(redos[i].json);
            }
        }

        return history;
    }

    public function fromJSON(json:Dynamic) {
        if (json == null) return;

        for (i in 0...json.undos.length) {
            var cmdJSON = json.undos[i];
            var cmd:Command = Type.createInstance(Type.resolveClass('Commands.' + cmdJSON.type), [editor]);
            cmd.json = cmdJSON;
            cmd.id = cmdJSON.id;
            cmd.name = cmdJSON.name;
            undos.push(cmd);
            idCounter = Math.max(idCounter, cmdJSON.id);
        }

        for (i in 0...json.redos.length) {
            var cmdJSON = json.redos[i];
            var cmd:Command = Type.createInstance(Type.resolveClass('Commands.' + cmdJSON.type), [editor]);
            cmd.json = cmdJSON;
            cmd.id = cmdJSON.id;
            cmd.name = cmdJSON.name;
            redos.push(cmd);
            idCounter = Math.max(idCounter, cmdJSON.id);
        }

        // Select the last executed undo-command
        editor.signals.historyChanged.dispatch(undos[undos.length - 1]);
    }

    public function clear() {
        undos = new Array<Command>();
        redos = new Array<Command>();
        idCounter = 0;

        editor.signals.historyChanged.dispatch();
    }

    public function goToState(id:Int) {
        if (historyDisabled) {
            alert(editor.strings.getKey('prompt/history/forbid'));
            return;
        }

        editor.signals.sceneGraphChanged.active = false;
        editor.signals.historyChanged.active = false;

        var cmd:Command = undos.length > 0 ? undos[undos.length - 1] : null;

        if (cmd == null || id > cmd.id) {
            cmd = redo();
            while (cmd != null && id > cmd.id) {
                cmd = redo();
            }
        } else {
            while (true) {
                cmd = undos[undos.length - 1];

                if (cmd == null || id == cmd.id) break;

                undo();
            }
        }

        editor.signals.sceneGraphChanged.active = true;
        editor.signals.historyChanged.active = true;

        editor.signals.sceneGraphChanged.dispatch();
        editor.signals.historyChanged.dispatch(cmd);
    }

    public function enableSerialization(id:Int) {
        /**
         * because there might be commands in this.undos and this.redos
         * which have not been serialized with .toJSON() we go back
         * to the oldest command and redo one command after the other
         * while also calling .toJSON() on them.
         */

        goToState(-1);

        editor.signals.sceneGraphChanged.active = false;
        editor.signals.historyChanged.active = false;

        var cmd:Command = redo();
        while (cmd != null) {
            if (!cmd.hasOwnProperty('json')) {
                cmd.json = cmd.toJSON();
            }
            cmd = redo();
        }

        editor.signals.sceneGraphChanged.active = true;
        editor.signals.historyChanged.active = true;

        goToState(id);
    }
}