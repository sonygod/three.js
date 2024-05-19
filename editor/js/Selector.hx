package three.js.editor.js;

import threejs.THREE;

class Selector {
    private var editor: Editor;
    private var signals: Signals;
    private var mouse: THREE.Vector2;
    private var raycaster: THREE.Raycaster;

    public function new(editor: Editor) {
        this.editor = editor;
        this.signals = editor.signals;

        this.mouse = new THREE.Vector2();
        this.raycaster = new THREE.Raycaster();

        this.signals.intersectionsDetected.add(function(intersects: Array<Dynamic>) {
            if (intersects.length > 0) {
                var object: Dynamic = intersects[0].object;
                if (object.userData.object != null) {
                    this.select(object.userData.object);
                } else {
                    this.select(object);
                }
            } else {
                this.select(null);
            }
        });
    }

    public function getIntersects(raycaster: THREE.Raycaster): Array<Dynamic> {
        var objects: Array<Dynamic> = [];
        this.editor.scene.traverseVisible(function(child: Dynamic) {
            objects.push(child);
        });
        this.editor.sceneHelpers.traverseVisible(function(child: Dynamic) {
            if (child.name == 'picker') objects.push(child);
        });
        return raycaster.intersectObjects(objects, false);
    }

    public function getPointerIntersects(point: {x: Float, y: Float}, camera: THREE.Camera): Array<Dynamic> {
        this.mouse.set((point.x * 2) - 1, -(point.y * 2) + 1);
        this.raycaster.setFromCamera(this.mouse, camera);
        return this.getIntersects(this.raycaster);
    }

    public function select(object: Dynamic) {
        if (this.editor.selected == object) return;
        var uuid: String = null;
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