package;

import js.Command;

class RemoveScriptCommand extends Command {
    public var object:Dynamic;
    public var script:String;
    public var index:Int;

    public function new(editor:Dynamic, ?object:Dynamic, ?script:String) {
        super(editor);

        $type = 'RemoveScriptCommand';
        $name = editor.strings.getKey('command/RemoveScript');

        $object = object;
        $script = script;

        if (object != null && script != '') {
            $index = editor.scripts[$object.uuid].indexOf(script);
        }
    }

    public function execute() {
        if (editor.scripts[$object.uuid] == null) return;

        if ($index != -1) {
            editor.scripts[$object.uuid].splice($index, 1);
        }

        editor.signals.scriptRemoved.dispatch(script);
    }

    public function undo() {
        if (editor.scripts[$object.uuid] == null) {
            editor.scripts[$object.uuid] = [];
        }

        editor.scripts[$object.uuid].splice($index, 0, script);
        editor.signals.scriptAdded.dispatch(script);
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();

        output.objectUuid = $object.uuid;
        output.script = $script;
        output.index = $index;

        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);

        $script = json.script;
        $index = json.index;
        $object = editor.objectByUuid(json.objectUuid);
    }
}