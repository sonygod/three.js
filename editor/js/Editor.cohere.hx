import js.three.Three;
import js.three.extras.core.Object3D;
import js.three.extras.core.Geometry;
import js.three.extras.core.BufferGeometry;
import js.three.extras.core.Material;
import js.three.extras.core.Texture;
import js.three.extras.core.AnimationMixer;
import js.three.extras.helpers.CameraHelper;
import js.three.extras.helpers.PointLightHelper;
import js.three.extras.helpers.DirectionalLightHelper;
import js.three.extras.helpers.SpotLightHelper;
import js.three.extras.helpers.HemisphereLightHelper;
import js.three.extras.helpers.SkeletonHelper;
import js.three.extras.loaders.ObjectLoader;

import js.signals.Signal;

class Editor {
    public var signals: {
        editScript: Signal;
        startPlayer: Signal;
        stopPlayer: Signal;
        enterXR: Signal;
        offerXR: Signal;
        leaveXR: Signal;
        editorCleared: Signal;
        savingStarted: Signal;
        savingFinished: Signal;
        transformModeChanged: Signal;
        snapChanged: Signal;
        spaceChanged: Signal;
        rendererCreated: Signal;
        rendererUpdated: Signal;
        rendererDetectKTX2Support: Signal;
        sceneBackgroundChanged: Signal;
        sceneEnvironmentChanged: Signal;
        sceneFogChanged: Signal;
        sceneFogSettingsChanged: Signal;
        sceneGraphChanged: Signal;
        sceneRendered: Signal;
        cameraChanged: Signal;
        cameraResetted: Signal;
        geometryChanged: Signal;
        objectSelected: Signal;
        objectFocused: Signal;
        objectAdded: Signal;
        objectChanged: Signal;
        objectRemoved: Signal;
        cameraAdded: Signal;
        cameraRemoved: Signal;
        helperAdded: Signal;
        helperRemoved: Signal;
        materialAdded: Signal;
        materialChanged: Signal;
        materialRemoved: Signal;
        scriptAdded: Signal;
        scriptChanged: Signal;
        scriptRemoved: Signal;
        windowResize: Signal;
        showGridChanged: Signal;
        showHelpersChanged: Signal;
        refreshSidebarObject3D: Signal;
        refreshSidebarEnvironment: Signal;
        historyChanged: Signal;
        viewportCameraChanged: Signal;
        viewportShadingChanged: Signal;
        intersectionsDetected: Signal;
    };

    public var config: Config;
    public var history: _History;
    public var selector: Selector;
    public var storage: _Storage;
    public var strings: Strings;
    public var loader: Loader;
    public var camera: PerspectiveCamera;
    public var scene: Object3D;
    public var sceneHelpers: Object3D;
    public var object: { };
    public var geometries: { [key: string]: Geometry | BufferGeometry };
    public var materials: { [key: string]: Material };
    public var textures: { [key: string]: Texture };
    public var scripts: { [key: string]: Array<Dynamic> };
    public var materialsRefCounter: Map<Material, Int>;
    public var mixer: AnimationMixer;
    public var selected: Object3D;
    public var helpers: { [key: string]: Object3D };
    public var cameras: { [key: string]: Object3D };
    public var viewportCamera: Object3D;
    public var viewportShading: String;

    public function new() {
        camera = _DEFAULT_CAMERA.clone();
        scene = new Object3D();
        sceneHelpers = new Object3D();
        object = { };
        geometries = { };
        materials = { };
        textures = { };
        scripts = { };
        materialsRefCounter = new Map();
        mixer = new AnimationMixer(scene);
        helpers = { };
        cameras = { };
        viewportCamera = camera;
        viewportShading = 'default';
    }

    public function setScene(scene: Object3D) {
        this.scene.uuid = scene.uuid;
        this.scene.name = scene.name;
        this.scene.background = scene.background;
        this.scene.environment = scene.environment;
        this.scene.fog = scene.fog;
        this.scene.backgroundBlurriness = scene.backgroundBlurriness;
        this.scene.backgroundIntensity = scene.backgroundIntensity;
        this.scene.userData = scene.userData;

        signals.sceneGraphChanged.active = false;

        while (scene.children.length > 0) {
            addObject(scene.children[0]);
        }

        signals.sceneGraphChanged.active = true;
        signals.sceneGraphChanged.dispatch();
    }

    public function addObject(object: Object3D, ?parent: Object3D, ?index: Int) {
        var scope = this;
        object.traverse(function (child) {
            if (child.geometry != null) scope.addGeometry(child.geometry);
            if (child.material != null) scope.addMaterial(child.material);
            scope.addCamera(child);
            scope.addHelper(child);
        });

        if (parent == null) {
            this.scene.add(object);
        } else {
            parent.children.splice(index, 0, object);
            object.parent = parent;
        }

        signals.objectAdded.dispatch(object);
        signals.sceneGraphChanged.dispatch();
    }

    public function moveObject(object: Object3D, parent: Object3D, ?before: Object3D) {
        if (parent == null) {
            parent = scene;
        }
        parent.add(object);

        if (before != null) {
            var index = parent.children.indexOf(before);
            parent.children.splice(index, 0, object);
            parent.children.pop();
        }

        signals.sceneGraphChanged.dispatch();
    }

    public function nameObject(object: Object3D, name: String) {
        object.name = name;
        signals.sceneGraphChanged.dispatch();
    }

    public function removeObject(object: Object3D) {
        if (object.parent == null) return;

        var scope = this;
        object.traverse(function (child) {
            scope.removeCamera(child);
            scope.removeHelper(child);
            if (child.material != null) scope.removeMaterial(child.material);
        });

        object.parent.remove(object);

        signals.objectRemoved.dispatch(object);
        signals.sceneGraphChanged.dispatch();
    }

    public function addGeometry(geometry: Geometry | BufferGeometry) {
        geometries[geometry.uuid] = geometry;
    }

    public function setGeometryName(geometry: Geometry | BufferGeometry, name: String) {
        geometry.name = name;
        signals.sceneGraphChanged.dispatch();
    }

    public function addMaterial(material: Material) {
        if (material is Array<Material>) {
            for (material in material) {
                addMaterialToRefCounter(material);
            }
        } else {
            addMaterialToRefCounter(material);
        }
        signals.materialAdded.dispatch();
    }

    public function addMaterialToRefCounter(material: Material) {
        var count = materialsRefCounter.get(material);
        if (count == null) {
            materialsRefCounter.set(material, 1);
            materials[material.uuid] = material;
        } else {
            count++;
            materialsRefCounter.set(material, count);
        }
    }

    public function removeMaterial(material: Material) {
        if (material is Array<Material>) {
            for (material in material) {
                removeMaterialFromRefCounter(material);
            }
        } else {
            removeMaterialFromRefCounter(material);
        }
        signals.materialRemoved.dispatch();
    }

    public function removeMaterialFromRefCounter(material: Material) {
        var count = materialsRefCounter.get(material);
        count--;
        if (count == 0) {
            materialsRefCounter.delete(material);
            delete materials[material.uuid];
        } else {
            materialsRefCounter.set(material, count);
        }
    }

    public function getMaterialById(id: Int) {
        var material: Material;
        var materialsArray = materials.values();
        for (material in materialsArray) {
            if (material.id == id) {
                return material;
            }
        }
        return null;
    }

    public function setMaterialName(material: Material, name: String) {
        material.name = name;
        signals.sceneGraphChanged.dispatch();
    }

    public function addTexture(texture: Texture) {
        textures[texture.uuid] = texture;
    }

    public function addCamera(camera: Object3D) {
        if (camera.isCamera) {
            cameras[camera.uuid] = camera;
            signals.cameraAdded.dispatch(camera);
        }
    }

    public function removeCamera(camera: Object3D) {
        if (cameras.exists(camera.uuid)) {
            delete cameras[camera.uuid];
            signals.cameraRemoved.dispatch(camera);
        }
    }

    public function addHelper() {
        var geometry = new SphereGeometry(2, 4, 2);
        var material = new MeshBasicMaterial({ color: 0xff0000, visible: false });
        return function (object: Object3D, ?helper: Object3D) {
            if (helper == null) {
                if (object.isCamera) {
                    helper = new CameraHelper(object);
                } else if (object.isPointLight) {
                    helper = new PointLightHelper(object, 1);
                } else if (object.isDirectionalLight) {
                    helper = new DirectionalLightHelper(object, 1);
                } else if (object.isSpotLight) {
                    helper = new SpotLightHelper(object);
                } else if (object.isHemisphereLight) {
                    helper = new HemisphereLightHelper(object, 1);
                } else if (object.isSkinnedMesh) {
                    helper = new SkeletonHelper(object.skeleton.bones[0]);
                } else if (object.isBone && object.parent != null && !object.parent.isBone) {
                    helper = new SkeletonHelper(object);
                } else {
                    // no helper for this object type
                    return;
                }
                var picker = new Mesh(geometry, material);
                picker.name = 'picker';
                picker.userData.object = object;
                helper.add(picker);
            }
            sceneHelpers.add(helper);
            helpers[object.id] = helper;
            signals.helperAdded.dispatch(helper);
        };
    }

    public function removeHelper(object: Object3D) {
        if (helpers.exists(object.id)) {
            var helper = helpers[object.id];
            helper.parent.remove(helper);
            delete helpers[object.id];
            signals.helperRemoved.dispatch(helper);
        }
    }

    public function addScript(object: Object3D, script: Dynamic) {
        if (!scripts.exists(object.uuid)) {
            scripts[object.uuid] = [];
        }
        scripts[object.uuid].push(script);
        signals.scriptAdded.dispatch(script);
    }

    public function removeScript(object: Object3D, script: Dynamic) {
        if (scripts.exists(object.uuid)) {
            var index = scripts[object.uuid].indexOf(script);
            if (index != -1) {
                scripts[object.uuid].splice(index, 1);
            }
        }
        signals.scriptRemoved.dispatch(script);
    }

    public function getObjectMaterial(object: Object3D, ?slot: Int) {
        var material = object.material;
        if (material is Array<Material> && slot != null) {
            material = material[slot];
        }
        return material;
    }

    public function setObjectMaterial(object: Object3D, ?slot: Int, newMaterial: Material) {
        if (object.material is Array<Material> && slot != null) {
            object.material[slot] = newMaterial;
        } else {
            object.material = newMaterial;
        }
    }

    public function setViewportCamera(uuid: String) {
        viewportCamera = cameras[uuid];
        signals.viewportCameraChanged.dispatch();
    }

    public function setViewportShading(value: String) {
        viewportShading = value;
        signals.viewportShadingChanged.dispatch();
    }

    public function select(object: Object3D) {
        selector.select(object);
    }

    public function selectById(id: Int) {
        if (id == camera.id) {
            select(camera);
            return;
        }
        select(scene.getObjectById(id));
    }

    public function selectByUuid(uuid: String) {
        var scope = this;
        scene.traverse(function (child) {
            if (child.uuid == uuid) {
                scope.select(child);
            }
        });
    }

    public function deselect() {
        selector.deselect();
    }

    public function focus(object: Object3D) {
        if (object != null) {
            signals.objectFocused.dispatch(object);
        }
    }

    public function focusById(id: Int) {
        focus(scene.getObjectById(id));
    }

    public function clear() {
        history.clear();
        storage.clear();
        camera.copy(_DEFAULT_CAMERA);
        signals.cameraResetted.dispatch();
        scene.name = 'Scene';
        scene.userData = { };
        scene.background = null;
        scene.environment = null;
        scene.fog = null;
        var objects = scene.children;
        signals.sceneGraphChanged.active = false;
        while (objects.length > 0) {
            removeObject(objects[0]);
        }
        signals.sceneGraphChanged.active = true;
        geometries = { };
        materials = { };
        textures = { };
        scripts = { };
        materialsRefCounter.clear();
        animations = { };
        mixer.stopAllAction();
        deselect();
        signals.editorCleared.dispatch();
    }

    public async function fromJSON(json: { camera: { }, history: { }, scripts: { }, scene: { } }) {
        var loader = new ObjectLoader();
        var camera = await loader.parseAsync(json.camera);
        const existingUuid = this.camera.uuid;
        const incomingUuid = camera.uuid;
        this.camera.copy(camera);
        this.camera.uuid = incomingUuid;
        delete cameras[existingUuid];
        cameras[incomingUuid] = this.camera;
        signals.cameraResetted.dispatch();
        history.fromJSON(json.history);
        scripts = json.scripts;
        setScene(await loader.parseAsync(json.scene));
        if (json.environment == 'ModelViewer') {
            signals.sceneEnvironmentChanged.dispatch(json.environment);
            signals.refreshSidebarEnvironment.dispatch();
        }
    }

    public function toJSON(): { metadata: { }, project: { }, camera: { }, scene: { }, scripts: { }, history: { }, environment: String } {
        var scene = this.scene;
        var scripts = this.scripts;
        for (var key in scripts) {
            var script = scripts[key];
            if (script.length == 0 || scene.getObjectByProperty('uuid', key) == null) {
                delete scripts[key];
            }
        }
        let environment = null;
        if (scene.environment != null && scene.environment.isRenderTargetTexture) {
            environment = 'ModelViewer';
        }
        return {
            metadata: { },
            project: {
                shadows: config.getKey('project/renderer/shadows'),
                shadowType: config.getKey('project/renderer/shadowType'),
                toneMapping: config.getKey('project/renderer/toneMapping'),
                toneMappingExposure: config.getKey('project/renderer/toneMappingExposure')
            },
            camera: viewportCamera.toJSON(),
            scene: scene.toJSON(),
            scripts: scripts,
            history: history.toJSON(),
            environment: environment
        };
    }

    public function objectByUuid(uuid: String) {
        return scene.getObjectByProperty('uuid', uuid, true);
    }

    public function execute(cmd: Dynamic, ?optionalName: String) {
        history.execute(cmd, optionalName);
    }

    public function undo() {
        history.undo();
    }

    public function redo() {
        history.redo();
    }

    public var utils: {
        save: Function;
        saveArrayBuffer: Function;
        saveString: Function;
        formatNumber: Function;
    };
}

var _DEFAULT_CAMERA = new PerspectiveCamera(50, 1, 0.01, 1000);
_DEFAULT_CAMERA.name = 'Camera';
_DEFAULT_CAMERA.position.set(0, 5, 10);
_DEFAULT_CAMERA.lookAt(new Vector3());

class Config {
    public function getKey(key: String) {
        // To be implemented
    }
}

class Loader {
    public function new(editor: Editor) {
        // To be implemented
    }
}

class _History {
    public function new(editor: Editor) {
        // To be implemented
    }
    public function fromJSON(json: { }) {
        // To be implemented
    }
    public function toJSON() {
        // To be implemented
    }
    public function clear() {
        // To be implemented
    }
    public function execute(cmd: Dynamic, ?optionalName: String) {
        // To be implemented
    }
    public function undo() {
        // To be implemented
    }
    public function redo() {
        // To be implemented
    }
}

class Strings {
    public function new(config: Config) {
        // To be implemented
    }
}

class _Storage {
    public function clear() {
        // To be implemented
    }
}

class Selector {
    public function select(object: Object3D) {
        // To be implemented
    }
    public function deselect() {
        // To be implemented
    }
}

class Vector3 {
    public var x: Float;
    public var y: Float;
    public var z: Float;
    public function lookAt(vector: Vector3) {
        // To be implemented
    }
}

class PerspectiveCamera {
    public var uuid: String;
public var name: String;
public var position: Vector3;
public function clone(): PerspectiveCamera {
    // To be implemented
}
public function toJSON() {
    // To be implemented
}
}

class Object3D {
    public var uuid: String;
    public var name: String;
    public var background: Dynamic;
    public var environment: Dynamic;
    public var fog: Dynamic;
    public var backgroundBlurriness: Dynamic;
    public var backgroundIntensity: Dynamic;
    public var userData: Dynamic;
    public var children: Array<Object3D>;
    public var parent: Object3D;
    public function add(object: Object3D) {
        // To be implemented
    }
    public function remove(object: Object3D) {
        // To be implemented
    }
    public function traverse(callback: Function) {
        // To be implemented
    }
    public function getObjectById(id: Int, ?recursive: Bool) {
        // To be implemented
    }
    public function getObjectByProperty(name: String, value: Dynamic, ?recursive: Bool) {
        // To be implemented
    }
    public function toJSON() {
        // To be implemented
    }
}

class SphereGeometry {
    public var uuid: String;
}

class MeshBasicMaterial {
    public var color: Int;
    public var visible: Bool;
}

class Mesh {
    public var name: String;
    public var userData: Dynamic;
}

class Signal {
    public function dispatch(?event: Dynamic) {
        // To be implemented
    }
    public var active: Bool;
}

class Intl {
    public static function getNumberFormat(locales: String, ?options: { }) {
        // To be implemented
    }
}

class MouseEvent {
    public static var CLICK: String;
}

class URL {
    public static function createObjectURL(blob: Dynamic) {
        // To be implemented
    }
    public static function revokeObjectURL(url: String) {
        // To be implemented
    }
}

class Blob {
    public function new(?parts: Array<Dynamic>, ?options: { }) {
        // To be implemented
    }
}

class Int {
    public static var dynamic: Dynamic;
}

class Bool {
    public static var dynamic: Dynamic;
}

class Float {
    public static var dynamic: Dynamic;
}