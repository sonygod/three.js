package three.js.editor.js.commands;

import three.js.editor.js.Command;

/**
 * @param editor Editor
 * @param object THREE.Object3D
 * @param attributeName String
 * @param newValue Dynamic (number, string, boolean or object)
 */
class SetValueCommand extends Command {
    
    public var object:THREE.Object3D;
    public var attributeName:String;
    public var oldValue:Dynamic;
    public var newValue:Dynamic;

    public function new(editor:Editor, object:THREE.Object3D = null, attributeName:String = '', newValue:Dynamic = null) {
        super(editor);

        this.type = 'SetValueCommand';
        this.name = editor.strings.getKey('command/SetValue') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? object[attributeName] : null;
        this.newValue = newValue;
    }

    public function execute():Void {
        this.object[attributeName] = this.newValue;
        this.editor.signals.objectChanged.dispatch(this.object);
        // this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo():Void {
        this.object[attributeName] = this.oldValue;
        this.editor.signals.objectChanged.dispatch(this.object);
        // this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function update(cmd:SetValueCommand):Void {
        this.newValue = cmd.newValue;
    }

    public function toJSON():Dynamic {
        var output = super.toJSON(this);

        output.objectUuid = this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldValue = this.oldValue;
        output.newValue = this.newValue;

        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
        this.object = this.editor.objectByUuid(json.objectUuid);
    }
}