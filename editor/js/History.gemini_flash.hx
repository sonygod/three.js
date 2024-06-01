import Commands from './commands/Commands';

class History {
	public editor:Dynamic;
	public undos:Array<Dynamic>;
	public redos:Array<Dynamic>;
	public lastCmdTime:Float;
	public idCounter:Int;
	public historyDisabled:Bool;
	public config:Dynamic;

	public function new(editor:Dynamic) {
		this.editor = editor;
		this.undos = [];
		this.redos = [];
		this.lastCmdTime = Date.now().getTime();
		this.idCounter = 0;

		this.historyDisabled = false;
		this.config = editor.config;

		// signals

		var scope = this;

		this.editor.signals.startPlayer.add(function() {
			scope.historyDisabled = true;
		});

		this.editor.signals.stopPlayer.add(function() {
			scope.historyDisabled = false;
		});
	}

	public function execute(cmd:Dynamic, optionalName:String = null):Void {
		var lastCmd:Dynamic = (this.undos.length > 0) ? this.undos[this.undos.length - 1] : null;
		var timeDifference:Float = Date.now().getTime() - this.lastCmdTime;

		var isUpdatableCmd:Bool = lastCmd != null &&
			lastCmd.updatable &&
			cmd.updatable &&
			lastCmd.object == cmd.object &&
			lastCmd.type == cmd.type &&
			lastCmd.script == cmd.script &&
			lastCmd.attributeName == cmd.attributeName;

		if (isUpdatableCmd && cmd.type == 'SetScriptValueCommand') {
			// When the cmd.type is "SetScriptValueCommand" the timeDifference is ignored

			lastCmd.update(cmd);
			cmd = lastCmd;
		} else if (isUpdatableCmd && timeDifference < 500) {
			lastCmd.update(cmd);
			cmd = lastCmd;
		} else {
			// the command is not updatable and is added as a new part of the history

			this.undos.push(cmd);
			cmd.id = ++this.idCounter;
		}

		cmd.name = (optionalName != null) ? optionalName : cmd.name;
		cmd.execute();
		cmd.inMemory = true;

		if (this.config.getKey('settings/history')) {
			cmd.json = cmd.toJSON(); // serialize the cmd immediately after execution and append the json to the cmd
		}

		this.lastCmdTime = Date.now().getTime();

		// clearing all the redo-commands

		this.redos = [];
		this.editor.signals.historyChanged.dispatch(cmd);
	}

	public function undo():Dynamic {
		if (this.historyDisabled) {
			js.Lib.alert(this.editor.strings.getKey('prompt/history/forbid'));
			return null;
		}

		var cmd:Dynamic = null;

		if (this.undos.length > 0) {
			cmd = this.undos.pop();

			if (!cmd.inMemory) {
				cmd.fromJSON(cmd.json);
			}
		}

		if (cmd != null) {
			cmd.undo();
			this.redos.push(cmd);
			this.editor.signals.historyChanged.dispatch(cmd);
		}

		return cmd;
	}

	public function redo():Dynamic {
		if (this.historyDisabled) {
			js.Lib.alert(this.editor.strings.getKey('prompt/history/forbid'));
			return null;
		}

		var cmd:Dynamic = null;

		if (this.redos.length > 0) {
			cmd = this.redos.pop();

			if (!cmd.inMemory) {
				cmd.fromJSON(cmd.json);
			}
		}

		if (cmd != null) {
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

		// Append Undos to History

		for (i in 0...this.undos.length) {
			if (Reflect.hasField(this.undos[i], 'json')) {
				history.undos.push(this.undos[i].json);
			}
		}

		// Append Redos to History

		for (i in 0...this.redos.length) {
			if (Reflect.hasField(this.redos[i], 'json')) {
				history.redos.push(this.redos[i].json);
			}
		}

		return history;
	}

	public function fromJSON(json:Dynamic):Void {
		if (json == null)
			return;

		for (i in 0...json.undos.length) {
			var cmdJSON:Dynamic = json.undos[i];
			var cmd:Dynamic = Type.createInstance(Type.resolveClass(cmdJSON.type), [this.editor]); // creates a new object of type "json.type"
			cmd.json = cmdJSON;
			cmd.id = cmdJSON.id;
			cmd.name = cmdJSON.name;
			this.undos.push(cmd);
			this.idCounter = (cmdJSON.id > this.idCounter) ? cmdJSON.id : this.idCounter; // set last used idCounter
		}

		for (i in 0...json.redos.length) {
			var cmdJSON = json.redos[i];
			var cmd:Dynamic = Type.createInstance(Type.resolveClass(cmdJSON.type), [this.editor]); // creates a new object of type "json.type"
			cmd.json = cmdJSON;
			cmd.id = cmdJSON.id;
			cmd.name = cmdJSON.name;
			this.redos.push(cmd);
			this.idCounter = (cmdJSON.id > this.idCounter) ? cmdJSON.id : this.idCounter; // set last used idCounter
		}

		// Select the last executed undo-command
		this.editor.signals.historyChanged.dispatch((this.undos.length > 0) ? this.undos[this.undos.length - 1] : null);
	}

	public function clear():Void {
		this.undos = [];
		this.redos = [];
		this.idCounter = 0;

		this.editor.signals.historyChanged.dispatch();
	}

	public function goToState(id:Int):Void {
		if (this.historyDisabled) {
			js.Lib.alert(this.editor.strings.getKey('prompt/history/forbid'));
			return;
		}

		this.editor.signals.sceneGraphChanged.active = false;
		this.editor.signals.historyChanged.active = false;

		var cmd:Dynamic = (this.undos.length > 0) ? this.undos[this.undos.length - 1] : null; // next cmd to pop

		if (cmd == null || id > cmd.id) {
			cmd = this.redo();
			while (cmd != null && id > cmd.id) {
				cmd = this.redo();
			}
		} else {
			while (true) {
				cmd = (this.undos.length > 0) ? this.undos[this.undos.length - 1] : null; // next cmd to pop

				if (cmd == null || id == cmd.id)
					break;

				this.undo();
			}
		}

		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.historyChanged.active = true;

		this.editor.signals.sceneGraphChanged.dispatch();
		this.editor.signals.historyChanged.dispatch(cmd);
	}

	public function enableSerialization(id:Int):Void {
		/**
		 * because there might be commands in this.undos and this.redos
		 * which have not been serialized with .toJSON() we go back
		 * to the oldest command and redo one command after the other
		 * while also calling .toJSON() on them.
		 */

		this.goToState(-1);

		this.editor.signals.sceneGraphChanged.active = false;
		this.editor.signals.historyChanged.active = false;

		var cmd:Dynamic = this.redo();
		while (cmd != null) {
			if (!Reflect.hasField(cmd, 'json')) {
				cmd.json = cmd.toJSON();
			}

			cmd = this.redo();
		}

		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.historyChanged.active = true;

		this.goToState(id);
	}
}

#if editor
export default History;
#end