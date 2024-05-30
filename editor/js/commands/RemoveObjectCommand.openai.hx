package three.editor.commands;

import three.editor.Command;
import three.ObjectLoader;

class RemoveObjectCommand extends Command {
    public var object:three.Object3D;
    public var parent:three.Object3D;
    public var index:Int;
    public var name:String;

    public function new(editor:Editor, object:three.Object3D = null) {
        super(editor);
        this.type = 'RemoveObjectCommand';
        this.object = object;
        this.parent = (object != null) ? object.parent : null;
        if (this.parent != null) {
            this.index = this.parent.children.indexOf(this.object);
        }
        if (object != null) {
            this.name = editor.strings.getKey('command/RemoveObject') + ': ' + object.name;
        }
    }

    public function execute():Void {
        editor.removeObject(this.object);
        editor.deselect();
    }

    public function undo():Void {
        editor.addObject(this.object, this.parent, this.index);
        editor.select(this.object);
    }

    public function toJSON():Dynamic {
        var output:Dynamic = super.toJSON(this);
        output.object = this.object.toJSON();
        output.index = this.index;
        output.parentUuid = this.parent.uuid;
        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        this.parent = editor.objectByUuid(json.parentUuid);
        if (this.parent == null) {
            this.parent = editor.scene;
        }
        this.index = json.index;
        this.object = editor.objectByUuid(json.object.uuid);
        if (this.object == null) {
            var loader:ObjectLoader = new ObjectLoader();
            this.object = loader.parse(json.object);
        }
    }
}