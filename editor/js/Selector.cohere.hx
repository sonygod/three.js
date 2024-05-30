import js.three.Vector2;
import js.three.Raycaster;

class Selector {
    var editor:Editor;
    var signals:Signals;

    public function new(editor:Editor) {
        this.editor = editor;
        this.signals = editor.signals;

        signals.intersectionsDetected.add(function(intersects:Array<js.three.Intersection>) {
            if (intersects.length > 0) {
                var object = intersects[0].object;
                if (Std.is(object.userData.object, Object)) {
                    this.select(untyped object.userData.object);
                } else {
                    this.select(object);
                }
            } else {
                this.select(null);
            }
        });
    }

    function getIntersects(raycaster:Raycaster):Array<js.three.Intersection> {
        var objects = [];
        editor.scene.traverseVisible(function(child:Dynamic) {
            objects.push(child);
        });
        editor.sceneHelpers.traverseVisible(function(child:Dynamic) {
            if (child.name == 'picker') objects.push(child);
        });
        return raycaster.intersectObjects(objects, false);
    }

    function getPointerIntersects(point:Vector2, camera:js.three.Camera):Array<js.three.Intersection> {
        var mouse = new Vector2((point.x * 2) - 1, -(point.y * 2) + 1);
        var raycaster = new Raycaster();
        raycaster.setFromCamera(mouse, camera);
        return this.getIntersects(raycaster);
    }

    function select(object:Dynamic) {
        if (editor.selected == object) return;
        var uuid:Null<String> = null;
        if (object != null) {
            uuid = object.uuid;
        }
        editor.selected = object;
        editor.config.setKey('selected', uuid);
        signals.objectSelected.dispatch(object);
    }

    function deselect() {
        this.select(null);
    }
}

extern class Editor {
    var scene:js.three.Scene;
    var config:Dynamic;
    var selected:Dynamic;
    var signals:Signals;
}

extern class Signals {
    function add(callback:Dynamic -> Void):Void;
    function dispatch(object:Dynamic):Void;
}

extern function traverseVisible(callback:Dynamic -> Void):Void;