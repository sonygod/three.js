import commands.Commands;

class History {

	var editor:Dynamic;
	var undos:Array<Dynamic>;
	var redos:Array<Dynamic>;
	var lastCmdTime:Int;
	var idCounter:Int;
	var historyDisabled:Bool;
	var config:Dynamic;

	public function new(editor:Dynamic) {
		this.editor = editor;
		this.undos = [];
		this.redos = [];
		this.lastCmdTime = Date.now();
		this.idCounter = 0;
		this.historyDisabled = false;
		this.config = editor.config;

		var scope = this;

		this.editor.signals.startPlayer.add(function () {
			scope.historyDisabled = true;
		});

		this.editor.signals.stopPlayer.add(function () {
			scope.historyDisabled = false;
		});
	}

	public function execute(cmd:Dynamic, optionalName:Dynamic):Void {
		var lastCmd = this.undos[this.undos.length - 1];
		var timeDifference = Date.now() - this.lastCmdTime;

		var isUpdatableCmd = lastCmd &&
			lastCmd.updatable &&
			cmd.updatable &&
			lastCmd.object === cmd.object &&
			lastCmd.type === cmd.type &&
			lastCmd.script === cmd.script &&
			lastCmd.attributeName === cmd.attributeName;

		if (isUpdatableCmd && cmd.type === 'SetScriptValueCommand') {
			lastCmd.update(cmd);
			cmd = lastCmd;
		} else if (isUpdatableCmd && timeDifference < 500) {
			lastCmd.update(cmd);
			cmd = lastCmd;
		} else {
			this.undos.push(cmd);
			cmd.id = ++this.idCounter;
		}

		cmd.name = (optionalName !== undefined) ? optionalName : cmd.name;
		cmd.execute();
		cmd.inMemory = true;

		if (this.config.getKey('settings/history')) {
			cmd.json = cmd.toJSON();
		}

		this.lastCmdTime = Date.now();
		this.redos = [];
		this.editor.signals.historyChanged.dispatch(cmd);
	}

	public function undo():Dynamic {
		if (this.historyDisabled) {
			trace(this.editor.strings.getKey('prompt/history/forbid'));
			return null;
		}

		var cmd:Dynamic = null;

		if (this.undos.length > 0) {
			cmd = this.undos.pop();
			if (cmd.inMemory === false) {
				cmd.fromJSON(cmd.json);
			}
		}

		if (cmd !== null) {
			cmd.undo();
			this.redos.push(cmd);
			this.editor.signals.historyChanged.dispatch(cmd);
		}

		return cmd;
	}

	public function redo():Dynamic {
		if (this.historyDisabled) {
			trace(this.editor.strings.getKey('prompt/history/forbid'));
			return null;
		}

		var cmd:Dynamic = null;

		if (this.redos.length > 0) {
			cmd = this.redos.pop();
			if (cmd.inMemory === false) {
				cmd.fromJSON(cmd.json);
			}
		}

		if (cmd !== null) {
			cmd.execute();
			this.undos.push(cmd);
			this.editor.signals.historyChanged.dispatch(cmd);
		}

		return cmd;
	}

	public function toJSON():Dynamic {
		var history:Dynamic = {};
		history.undos = [];
		history.redos = [];

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

	public function fromJSON(json:Dynamic):Void {
		if (json === null) return;

		for (cmdJSON in json.undos) {
			var cmd = new Commands[cmdJSON.type](this.editor);
			cmd.json = cmdJSON;
			cmd.id = cmdJSON.id;
			cmd.name = cmdJSON.name;
			this.undos.push(cmd);
			this.idCounter = (cmdJSON.id > this.idCounter) ? cmdJSON.id : this.idCounter;
		}

		for (cmdJSON in json.redos) {
			var cmd = new Commands[cmdJSON.type](this.editor);
			cmd.json = cmdJSON;
			cmd.id = cmdJSON.id;
			cmd.name = cmdJSON.name;
			this.redos.push(cmd);
			this.idCounter = (cmdJSON.id > this.idCounter) ? cmdJSON.id : this.idCounter;
		}

		this.editor.signals.historyChanged.dispatch(this.undos[this.undos.length - 1]);
	}

	public function clear():Void {
		this.undos = [];
		this.redos = [];
		this.idCounter = 0;
		this.editor.signals.historyChanged.dispatch();
	}

	public function goToState(id:Int):Void {
		if (this.historyDisabled) {
			trace(this.editor.strings.getKey('prompt/history/forbid'));
			return;
		}

		this.editor.signals.sceneGraphChanged.active = false;
		this.editor.signals.historyChanged.active = false;

		var cmd:Dynamic = (this.undos.length > 0) ? this.undos[this.undos.length - 1] : null;

		if (cmd === null || id > cmd.id) {
			cmd = this.redo();
			while (cmd !== null && id > cmd.id) {
				cmd = this.redo();
			}
		} else {
			while (true) {
				cmd = this.undos[this.undos.length - 1];
				if (cmd === null || id === cmd.id) break;
				this.undo();
			}
		}

		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.historyChanged.active = true;

		this.editor.signals.sceneGraphChanged.dispatch();
		this.editor.signals.historyChanged.dispatch(cmd);
	}

	public function enableSerialization(id:Int):Void {
		this.goToState(-1);

		this.editor.signals.sceneGraphChanged.active = false;
		this.editor.signals.historyChanged.active = false;

		var cmd:Dynamic = this.redo();
		while (cmd !== null) {
			if (!cmd.hasOwnProperty('json')) {
				cmd.json = cmd.toJSON();
			}
			cmd = this.redo();
		}

		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.historyChanged.active = true;

		this.goToState(id);
	}
}