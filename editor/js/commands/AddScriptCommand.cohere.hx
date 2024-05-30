package;

import js.js_es6.Map;
import js.js_es6.Set;

class AddScriptCommand extends Command {
    public var object:Dynamic;
    public var script:String;

    public function new(editor:Dynamic, ?object:Dynamic, ?script:String) {
        super(editor);
        $if (object != null) {
            $if (script != null) {
                $this.object = object;
                $this.script = script;
            } else {
                $this.object = object;
                $this.script = '';
            }
        } else {
            $if (script != null) {
                $this.object = null;
                $this.script = script;
            } else {
                $this.object = null;
                $this.script = '';
            }
        }
        $this.type = 'AddScriptCommand';
        $this.name = editor.strings.getKey('command/AddScript');
    }

    public function execute() {
        if (Map.prototype.has($this.editor.scripts, $this.object.uuid) == false) {
            $this.editor.scripts.set($this.object.uuid, []);
        }
        $this.editor.scripts.get($this.object.uuid).push($this.script);
        $this.editor.signals.scriptAdded.dispatch($this.script);
    }

    public function undo() {
        if (Map.prototype.has($this.editor.scripts, $this.object.uuid) == false) {
            return;
        }
        var index = $this.editor.scripts.get($this.object.uuid).indexOf($this.script);
        if (index != -1) {
            $this.editor.scripts.get($this.object.uuid).splice(index, 1);
        }
        $this.editor.signals.scriptRemoved.dispatch($this.script);
    }

    public function toJSON() {
        var output = super.toJSON();
        output.objectUuid = $this.object.uuid;
        output.script = $this.script;
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        $this.script = json.script;
        $this.object = $this.editor.objectByUuid(json.objectUuid);
    }
}

@:expose("AddScriptCommand")
class AddScriptCommandExtern {
}