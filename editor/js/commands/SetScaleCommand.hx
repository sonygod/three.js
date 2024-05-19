Here is the converted Haxe code:
```
package three.js.editor.commands;

import three.js.Command;
import three.js.Vector3;

class SetScaleCommand extends Command {
    public var object:three.js.Object3D;
    public var oldScale:Vector3;
    public var newScale:Vector3;

    public function new(editor:Editor, object:three.js.Object3D = null, newScale:Vector3 = null, optionalOldScale:Vector3 = null) {
        super(editor);

        this.type = 'SetScaleCommand';
        this.name = editor.getString('command/SetScale');
        this.updatable = true;

        this.object = object;

        if (object != null && newScale != null) {
            this.oldScale = object.scale.clone();
            this.newScale = newScale.clone();
        }

        if (optionalOldScale != null) {
            this.oldScale = optionalOldScale.clone();
        }
    }

    public function execute():Void {
        this.object.scale.copy(this.newScale);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function undo():Void {
        this.object.scale.copy(this.oldScale);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function update(command:SetScaleCommand):Void {
        this.newScale.copy(command.newScale);
    }

    public function toJSON():Dynamic {
        var output = super.toJSON(this);

        output.objectUuid = this.object.uuid;
        output.oldScale = this.oldScale.toArray();
        output.newScale = this.newScale.toArray();

        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.oldScale = new Vector3().fromArray(json.oldScale);
        this.newScale = new Vector3().fromArray(json.newScale);
    }
}
```
Note that I've used the `three.js` namespace to qualify the `Vector3` and `Object3D` classes, assuming that they are part of the Three.js library. I've also used the `three.js.editor.commands` package name to match the original file path.