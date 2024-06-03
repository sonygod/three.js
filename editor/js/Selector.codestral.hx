import three.Vector2;
import three.Raycaster;
import three.Object3D;
import three.Intersection;

class Selector {
    private var mouse:Vector2;
    private var raycaster:Raycaster;
    private var editor:Editor;
    private var signals:Signals;

    public function new(editor:Editor) {
        this.mouse = new Vector2();
        this.raycaster = new Raycaster();
        this.editor = editor;
        this.signals = editor.signals;

        signals.intersectionsDetected.add((intersects:Array<Intersection>) => {
            if (intersects.length > 0) {
                var object = intersects[0].object;
                if (object.userData.exists("object")) {
                    this.select(object.userData.get("object"));
                } else {
                    this.select(object);
                }
            } else {
                this.select(null);
            }
        });
    }

    private function getIntersects(raycaster:Raycaster):Array<Intersection> {
        var objects:Array<Object3D> = [];

        this.editor.scene.traverseVisible(function(child:Object3D) {
            objects.push(child);
        });

        this.editor.sceneHelpers.traverseVisible(function(child:Object3D) {
            if (child.name == 'picker') objects.push(child);
        });

        return raycaster.intersectObjects(objects, false);
    }

    public function getPointerIntersects(point:Dynamic, camera:Camera):Array<Intersection> {
        this.mouse.set((point.x * 2) - 1, - (point.y * 2) + 1);
        this.raycaster.setFromCamera(this.mouse, camera);
        return this.getIntersects(this.raycaster);
    }

    public function select(object:Object3D) {
        if (this.editor.selected == object) return;

        var uuid:String = null;

        if (object != null) {
            uuid = object.uuid;
        }

        this.editor.selected = object;
        this.editor.config.setKey('selected', uuid);

        this.signals.objectSelected.dispatch(object);
    }

    public function deselect() {
        this.select(null);
    }
}