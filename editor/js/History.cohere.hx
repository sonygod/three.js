import js.Date;

class History {
    public var editor: Editor;
    public var undos: Array<Command>;
    public var redos: Array<Command>;
    public var lastCmdTime: Int;
    public var idCounter: Int;
    public var historyDisabled: Bool;
    public var config: Config;

    public function new(editor: Editor) {
        this.editor = editor;
        this.undos = [];
        this.redos = [];
        this.lastCmdTime = Date.now();
        this.idCounter = 0;
        this.historyDisabled = false;
        this.config = editor.config;

        // signals
        this.editor.signals.startPlayer.add($bind(this, this.onStartPlayer));
        this.editor.signals.stopPlayer.add($bind(this, this.onStopPlayer));
    }

    public function execute(cmd: Command, optionalName: String): Void {
        var lastCmd = this.undos.pop();
        var timeDifference = Date.now() - this.lastCmdTime;
        var isUpdatableCmd = false;

        if (lastCmd != null && lastCmd.updatable && cmd.updatable && lastCmd.object == cmd.object && lastCmd.type == cmd.type && lastCmd.script == cmd.script && lastCmd.attributeName == cmd.attributeName) {
            isUpdatableCmd = true;
        }

        if (isUpdatableCmd && cmd.type == 'SetScriptValueCommand') {
            lastCmd.update(cmd);
            cmd = lastCmd;
        } else if (isUpdatableCmd && timeDifference < 500) {
            lastCmd.update(cmd);
            cmd = lastCmd;
        } else {
            this.undos.push(cmd);
            cmd.id = this.idCounter + 1;
        }

        cmd.name = optionalName != null ? optionalName : cmd.name;
        cmd.execute();
        cmd.inMemory = true;

        if (this.config.getKey('settings/history')) {
            cmd.json = cmd.toJSON();
        }

        this.lastCmdTime = Date.now();
        this.redos = [];
        this.editor.signals.historyChanged.dispatch(cmd);
    }

    public function undo(): Command {
        if (this.historyDisabled) {
            alert(this.editor.strings.getKey('prompt/history/forbid'));
            return null;
        }

        var cmd = this.undos.pop();

        if (cmd != null && cmd.inMemory == false) {
            cmd.fromJSON(cmd.json);
        }

        if (cmd != null) {
            cmd.undo();
            this.redos.push(cmd);
            this.editor.signals.historyChanged.dispatch(cmd);
        }

        return cmd;
    }

    public function redo(): Command {
        if (this.historyDisabled) {
            alert(this.editor.strings.getKey('prompt/history/forbid'));
            return null;
        }

        var cmd = this.redos.pop();

        if (cmd != null && cmd.inMemory == false) {
            cmd.fromJSON(cmd.json);
        }

        if (cmd != null) {
            cmd.execute();
            this.undos.push(cmd);
            this.editor.signals.historyChanged.dispatch(cmd);
        }

        return cmd;
    }

    public function toJSON(): { undos: Array<Command>, redos: Array<Command> } {
        var history = { undos: [], redos: [] };

        if (!this.config.getKey('settings/history')) {
            return history;
        }

        for (cmd in this.undos) {
            if (cmd.hasOwnProperty('json')) {
                history.undos.push(cmd.json);
            }
        }

        for (cmd in this.redos) {
            if (cmd.hasOwnProperty('json')) {
                history.redos.push(cmd.json);
            }
        }

        return history;
    }

    public function fromJSON(json: { undos: Array<Command>, redos: Array<Command> }): Void {
        if (json == null) {
            return;
        }

        for (cmdJSON in json.undos) {
            var cmd = Command.create(cmdJSON.type, this.editor);
            cmd.json = cmdJSON;
            cmd.id = cmdJSON.id;
            cmd.name = cmdJSON.name;
            this.undos.push(cmd);
            this.idCounter = cmdJSON.id > this.idCounter ? cmdJSON.id : this.idCounter;
        }

        for (cmdJSON in json.redos) {
            var cmd = Command.create(cmdJSON.type, this.editor);
            cmd.json = cmdJSON;
            cmd.id = cmdJSON.id;
            cmd.name = cmdJSON.name;
            this.redos.push(cmd);
            this.idCounter = cmdJSON.id > this.idCounter ? cmdJSON.id : this.idCounter;
        }

        this.editor.signals.historyChanged.dispatch(this.undos[this.undos.length - 1]);
    }

    public function clear(): Void {
        this.undos = [];
        this.redos = [];
        this.idCounter = 0;
        this.editor.signals.historyChanged.dispatch();
    }

    public function goToState(id: Int): Void {
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
            while (cmd != null && id != cmd.id) {
                cmd = this.undos.pop();
                this.undo();
            }
        }

        this.editor.signals.sceneGraphChanged.active = true;
        this.editor.signals.historyChanged.active = true;
        this.editor.signals.sceneGraphChanged.dispatch();
        this.editor.signals.historyChanged.dispatch(cmd);
    }

    public function enableSerialization(id: Int): Void {
        this.goToState(-1);

        this.editor.signals.sceneGraphChanged.active = false;
        this.editor.signals.historyChanged.active = false;

        var cmd = this.redo();
        while (cmd != null) {
            if (!cmd.hasOwnProperty('json')) {
                cmd.json = cmd.toJSON();
            }
            cmd = this.redo();
        }

        this.editor.signals.sceneGraphChanged.active = true;
        this.editor.signals.historyChanged.active = true;
        this.goToState(id);
    }

    private function onStartPlayer(): Void {
        this.historyDisabled = true;
    }

    private function onStopPlayer(): Void {
        this.historyDisabled = false;
    }
}