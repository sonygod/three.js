import three.THREE;

class Selector {

    var mouse:THREE.Vector2;
    var raycaster:THREE.Raycaster;
    var editor:Dynamic;
    var signals:Dynamic;

    public function new(editor:Dynamic) {
        mouse = new THREE.Vector2();
        raycaster = new THREE.Raycaster();
        this.editor = editor;
        this.signals = editor.signals;

        // signals
        signals.intersectionsDetected.add(function(intersects:Array<Dynamic>) {
            if (intersects.length > 0) {
                var object = intersects[0].object;
                if (object.userData.object !== undefined) {
                    // helper
                    this.select(object.userData.object);
                } else {
                    this.select(object);
                }
            } else {
                this.select(null);
            }
        });
    }

    public function getIntersects(raycaster:THREE.Raycaster):Array<Dynamic> {
        var objects:Array<Dynamic> = [];
        this.editor.scene.traverseVisible(function(child:Dynamic) {
            objects.push(child);
        });
        this.editor.sceneHelpers.traverseVisible(function(child:Dynamic) {
            if (child.name == 'picker') objects.push(child);
        });
        return raycaster.intersectObjects(objects, false);
    }

    public function getPointerIntersects(point:Dynamic, camera:Dynamic):Array<Dynamic> {
        mouse.set((point.x * 2) - 1, -(point.y * 2) + 1);
        raycaster.setFromCamera(mouse, camera);
        return this.getIntersects(raycaster);
    }

    public function select(object:Dynamic):Void {
        if (this.editor.selected == object) return;
        var uuid:Dynamic = null;
        if (object !== null) {
            uuid = object.uuid;
        }
        this.editor.selected = object;
        this.editor.config.setKey('selected', uuid);
        this.signals.objectSelected.dispatch(object);
    }

    public function deselect():Void {
        this.select(null);
    }
}