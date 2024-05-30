import js.Browser.Window;

class SidebarMaterialProgram {
    public var container:UIRow;
    public var programInfo:UIButton;
    public var programVertex:UIButton;
    public var programFragment:UIButton;
    public var object:Dynamic;
    public var materialSlot:Int;
    public var material:Dynamic;
    public var editor:Dynamic;
    public var property:Dynamic;
    public var signals:Dynamic;
    public var strings:Dynamic;

    public function new(editor:Dynamic, property:Dynamic) {
        this.editor = editor;
        this.property = property;
        this.signals = editor.signals;
        this.strings = editor.strings;

        object = null;
        materialSlot = 0;
        material = null;

        container = new UIRow();
        container.add(new UIText(strings.getKey('sidebar/material/program')).setClass('Label'));

        programInfo = new UIButton(strings.getKey('sidebar/material/info'));
        programInfo.setMarginRight('4px');
        programInfo.onClick(function() {
            signals.editScript.dispatch(object, 'programInfo');
        });
        container.add(programInfo);

        programVertex = new UIButton(strings.getKey('sidebar/material/vertex'));
        programVertex.setMarginRight('4px');
        programVertex.onClick(function() {
            signals.editScript.dispatch(object, 'vertexShader');
        });
        container.add(programVertex);

        programFragment = new UIButton(strings.getKey('sidebar/material/fragment'));
        programFragment.setMarginRight('4px');
        programFragment.onClick(function() {
            signals.editScript.dispatch(object, 'fragmentShader');
        });
        container.add(programFragment);

        signals.objectSelected.add($bind(this, 'update'));
        signals.materialChanged.add($bind(this, 'update'));
    }

    public function update(currentObject:Dynamic, currentMaterialSlot:Int = 0):Void {
        object = currentObject;
        materialSlot = currentMaterialSlot;

        if (object == null) return;
        if (Reflect.hasField(object, 'material') == false) return;

        material = editor.getObjectMaterial(object, materialSlot);

        if (Reflect.hasField(material, property)) {
            container.setDisplay('');
        } else {
            container.setDisplay('none');
        }
    }
}

class Reflect {
    public static function hasField(obj:Dynamic, field:String):Bool {
        if (obj == null) {
            return false;
        }
        return obj.hasOwnProperty != null ? $bind(obj, 'hasOwnProperty')(field) : false;
    }
}

class UIButton {
    public function new(label:String) {
        // ...
    }

    public function setMarginRight(value:String):Void {
        // ...
    }

    public function onClick(callback:Void->Void):Void {
        // ...
    }
}

class UIText {
    public function new(text:String) {
        // ...
    }

    public function setClass(className:String):Void {
        // ...
    }
}

class UIRow {
    public function new() {
        // ...
    }

    public function add(element:Dynamic):Void {
        // ...
    }

    public function setDisplay(mode:String):Void {
        // ...
    }
}