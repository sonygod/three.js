import js.js_types.js_Object;
import js.Browser.window;
import js.html.HTMLElement;
import js.html.CanvasElement;

class SetMaterialColorCommand {
    public var type: String;
    public var name: String;
    public var updatable: Bool;
    public var object: js_Object;
    public var materialSlot: Int;
    public var oldValue: Int;
    public var newValue: Int;
    public var attributeName: String;
    public var editor: js_Object;

    public function new(editor: js_Object, ?object: js_Object, ?attributeName: String, ?newValue: Int, ?materialSlot: Int) {
        $editor = editor;
        $object = object;
        $attributeName = attributeName;
        $materialSlot = materialSlot;

        $type = 'SetMaterialColorCommand';
        $name = editor.callMethod('strings', 'getKey', ['command/SetMaterialColor'] ++ attributeName);
        $updatable = true;

        var material = if (object != null) editor.callMethod('getObjectMaterial', [object, materialSlot]) else null;

        $oldValue = if (material != null) material.callMethod('getHex', []) else null;
        $newValue = newValue;
    }

    public function execute() {
        var material = editor.callMethod('getObjectMaterial', [object, materialSlot]);
        material.callMethod('setHex', [newValue]);
        editor.callMethod('dispatch', ['materialChanged', object, materialSlot]);
    }

    public function undo() {
        var material = editor.callMethod('getObjectMaterial', [object, materialSlot]);
        material.callMethod('setHex', [oldValue]);
        editor.callMethod('dispatch', ['materialChanged', object, materialSlot]);
    }

    public function update(cmd: SetMaterialColorCommand) {
        newValue = cmd.newValue;
    }

    public function toJSON(): js_Object {
        var output = js.JSON.stringify(this);
        output.set('objectUuid', object.callMethod('uuid', []));
        output.set('attributeName', attributeName);
        output.set('oldValue', oldValue);
        output.set('newValue', newValue);
        output.set('materialSlot', materialSlot);
        return output;
    }

    public function fromJSON(json: js_Object) {
        editor = window.callMethod('editor');
        object = editor.callMethod('objectByUuid', [json.get('objectUuid').toString()]);
        attributeName = json.get('attributeName').toString();
        oldValue = json.get('oldValue');
        newValue = json.get('newValue');
        materialSlot = json.get('materialSlot');
    }
}

class Command {
    public var editor: js_Object;

    public function new(editor: js_Object) {
        $editor = editor;
    }

    public function toJSON(): js_Object {
        return js.JSON.stringify(this);
    }

    public function fromJSON(json: js_Object) {
        js.Lib.alert('fromJSON not implemented');
    }
}