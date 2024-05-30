package;

import js.Command;

/**
 * @param editor Editor
 * @param object THREE.Object3D
 * @param script javascript object
 * @param attributeName string
 * @param newValue string, object
 */
class SetScriptValueCommand extends Command {
    public var type: String = 'SetScriptValueCommand';
    public var name: String;
    public var updatable: Bool;
    public var object: Dynamic;
    public var script: Dynamic;
    public var attributeName: String;
    public var oldValue: Dynamic;
    public var newValue: Dynamic;

    public function new(editor: Dynamic, ?object: Dynamic, script: String = '', attributeName: String = '', newValue: Dynamic = null) {
        super(editor);
        $this.name = editor.strings.getKey('command/SetScriptValue') + ': ' + attributeName;
        $this.updatable = true;
        $this.object = object;
        $this.script = script;
        $this.attributeName = attributeName;
        $this.oldValue = (script != '') ? script[$this.attributeName] : null;
        $this.newValue = newValue;
    }

    public function execute() {
        $this.script[$this.attributeName] = $this.newValue;
        $this.editor.signals.scriptChanged.dispatch();
    }

    public function undo() {
        $this.script[$this.attributeName] = $this.oldValue;
        $this.editor.signals.scriptChanged.dispatch();
    }

    public function update(cmd: SetScriptValueCommand) {
        $this.newValue = cmd.newValue;
    }

    public function toJSON(): Dynamic {
        var output = super.toJSON();
        output.objectUuid = $this.object.uuid;
        output.index = $this.editor.scripts[$this.object.uuid].indexOf($this.script);
        output.attributeName = $this.attributeName;
        output.oldValue = $this.oldValue;
        output.newValue = $this.newValue;
        return output;
    }

    public function fromJSON(json: Dynamic) {
        super.fromJSON(json);
        $this.oldValue = json.oldValue;
        $this.newValue = json.newValue;
        $this.attributeName = json.attributeName;
        $this.object = $this.editor.objectByUuid(json.objectUuid);
        $this.script = $this.editor.scripts[json.objectUuid][json.index];
    }

    public static function __properties__():Array<String> {
        return ['type', 'name', 'updatable', 'object', 'script', 'attributeName', 'oldValue', 'newValue'];
    }
}