package three.js.editor.js;

import three.js.lib.*;

class Selector {
    var editor:Editor;
    var signals:Signals;

    var mouse:Vector2;
    var raycaster:Raycaster;

    public function new(editor:Editor) {
        mouse = new Vector2();
        raycaster = new Raycaster();

        this.editor = editor;
        signals = editor.signals;

        signals.intersectionsDetected.add(function(intersects:Array.INTERSECTION>) {
            if (intersects.length > 0) {
                var object:Object3D = intersects[0].object;
                if (object.userData.object != null) {
                    select(object.userData.object);
                } else {
                    select(object);
                }
            } else {
                select(null);
            }
        });
    }

    public function getIntersects(raycaster:Raycaster):Array.INTERSECTION> {
        var objects:Array<Object3D> = [];
        editor.scene.traverseVisible(function(child:Object3D) {
            objects.push(child);
        });
        editor.sceneHelpers.traverseVisible(function(child:Object3D) {
            if (child.name == 'picker') objects.push(child);
        });
        return raycaster.intersectObjects(objects, false);
    }

    public function getPointerIntersects(point:Vector2, camera:Camera):Array.INTERSECTION> {
        mouse.set((point.x * 2) - 1, - (point.y * 2) + 1);
        raycaster.setFromCamera(mouse, camera);
        return getIntersects(raycaster);
    }

    public function select(object:Object3D) {
        if (editor.selected == object) return;
        var uuid:String = null;
        if (object != null) {
            uuid = object.uuid;
        }
        editor.selected = object;
        editor.config.setKey('selected', uuid);
        signals.objectSelected.dispatch(object);
    }

    public function deselect() {
        select(null);
    }
}