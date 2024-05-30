import Command from '../Command.hx';

import ObjectLoader from 'three/src/loaders/ObjectLoader.js';

class RemoveObjectCommand extends Command {
    public object:Dynamic;
    public parent:Dynamic;
    public index:Int;
    public name:String;

    public function new(editor:Editor, object:Dynamic = null) {
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

    public function execute() {
        this.editor.removeObject(this.object);
        this.editor.deselect();
    }

    public function undo() {
        this.editor.addObject(this.object, this.parent, this.index);
        this.editor.select(this.object);
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.object = this.object.toJSON();
        output.index = this.index;
        output.parentUuid = this.parent.uuid;
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);

        this.parent = this.editor.objectByUuid(json.parentUuid);
        if (this.parent == null) {
            this.parent = this.editor.scene;
        }

        this.index = json.index;

        this.object = this.editor.objectByUuid(json.object.object.uuid);

        if (this.object == null) {
            var loader = new ObjectLoader();
            this.object = loader.parse(json.object);
        }
    }
}