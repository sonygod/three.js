import js.Browser.Window;
import js.three.Vector3;
import js.three.Object3D;

class SetScaleCommand extends Command {
    public var object:Object3D;
    public var oldScale:Vector3;
    public var newScale:Vector3;

    public function new(editor:Editor, ?object:Object3D, ?newScale:Vector3, ?optionalOldScale:Vector3) {
        super(editor);

        $type = 'SetScaleCommand';
        $name = editor.strings.getKey('command/SetScale');
        $updatable = true;

        if (object != null && newScale != null) {
            this.oldScale = object.scale.clone();
            this.newScale = newScale.clone();
        }

        if (optionalOldScale != null) {
            this.oldScale = optionalOldScale.clone();
        }

        $object = object;
    }

    public function execute() {
        object.scale.copy(newScale);
        object.updateMatrixWorld(true);
        editor.signals.objectChanged.dispatch(object);
    }

    public function undo() {
        object.scale.copy(oldScale);
        object.updateMatrixWorld(true);
        editor.signals.objectChanged.dispatch(object);
    }

    public function update(command:SetScaleCommand) {
        newScale.copy(command.newScale);
    }

    public function toJSON():String {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.oldScale = oldScale.toArray();
        output.newScale = newScale.toArray();
        return output;
    }

    public function fromJSON(json:String) {
        super.fromJSON(json);
        object = editor.objectByUuid(json.objectUuid);
        oldScale = new Vector3().fromArray(json.oldScale);
        newScale = new Vector3().fromArray(json.newScale);
    }
}

class Command {
    public var type:String;
    public var name:String;
    public var updatable:Bool;

    public function new(?editor:Editor) {
        if (editor != null) {
            $editor = editor;
        }
    }

    public function toJSON():Dynamic {
        return { };
    }

    public function fromJSON(json:Dynamic) { }
}

class Editor {
    public function objectByUuid(uuid:String):Object3D {
        return null;
    }
}

class Vector3 {
    public function clone():Vector3 {
        return new Vector3();
    }

    public function copy(v:Vector3):Void { }

    public function fromArray(array:Array<Float>):Vector3 {
        return new Vector3();
    }

    public function toArray():Array<Float> {
        return [];
    }
}

class Object3D {
    public var scale:Vector3;
    public function updateMatrixWorld(force:Bool):Void { }
}

class Signal {
    public function dispatch(object:Object3D):Void { }
}

class Strings {
    public function getKey(key:String):String {
        return '';
    }
}

class Window {
    public static var JSON:Dynamic;
}