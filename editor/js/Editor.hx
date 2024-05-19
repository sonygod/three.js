package three.js.editor;

import three.js.THREE;

class Editor {
    public var signals:Signals;
    public var config:Config;
    public var history:History;
    public var selector:Selector;
    public var storage:Storage;
    public var strings:Strings;
    public var loader:Loader;
    public var camera:THREE.PerspectiveCamera;
    public var scene:THREE.Scene;
    public var sceneHelpers:THREE.Scene;
    public var object:Dynamic;
    public var geometries:Map<String, THREE.Geometry>;
    public var materials:Map<String, THREE.Material>;
    public var textures:Map<String, THREE.Texture>;
    public var scripts:Map<String, Array<Dynamic>>;
    public var materialsRefCounter:Map<THREE.Material, Int>;
    public var mixer:THREE.AnimationMixer;
    public var selected:Null<THREE.Object3D>;
    public var helpers:Map<String, THREE.Object3D>;
    public var cameras:Map<String, THREE.Camera>;
    public var viewportCamera:THREE.Camera;
    public var viewportShading:String;

    public function new() {
        signals = new Signals();
        config = new Config();
        history = new History(this);
        selector = new Selector(this);
        storage = new Storage();
        strings = new Strings(config);
        loader = new Loader(this);
        camera = THREE.PerspectiveCamera(50, 1, 0.01, 1000);
        camera.name = 'Camera';
        camera.position.set(0, 5, 10);
        camera.lookAt(new THREE.Vector3());
        scene = new THREE.Scene();
        scene.name = 'Scene';
        sceneHelpers = new THREE.Scene();
        sceneHelpers.add(new THREE.HemisphereLight(0xffffff, 0x888888, 2));
        object = {};
        geometries = new Map<String, THREE.Geometry>();
        materials = new Map<String, THREE.Material>();
        textures = new Map<String, THREE.Texture>();
        scripts = new Map<String, Array<Dynamic>>();
        materialsRefCounter = new Map<THREE.Material, Int>();
        mixer = new THREE.AnimationMixer(scene);
        selected = null;
        helpers = new Map<String, THREE.Object3D>();
        cameras = new Map<String, THREE.Camera>();
        viewportCamera = camera;
        viewportShading = 'default';
        addCamera(camera);
    }

    public function setScene(scene:THREE.Scene) {
        this.scene.uuid = scene.uuid;
        this.scene.name = scene.name;
        this.scene.background = scene.background;
        this.scene.environment = scene.environment;
        this.scene.fog = scene.fog;
        this.scene.backgroundBlurriness = scene.backgroundBlurriness;
        this.scene.backgroundIntensity = scene.backgroundIntensity;
        this.scene.userData = JSON.parse(JSON.stringify(scene.userData));
        signals.sceneGraphChanged.active = false;
        while (scene.children.length > 0) {
            addObject(scene.children[0]);
        }
        signals.sceneGraphChanged.active = true;
        signals.sceneGraphChanged.dispatch();
    }

    // ... (other methods)

    public function addObject(object:THREE.Object3D, parent:THREE.Object3D = null, index:Int = 0) {
        object.traverse(function(child:THREE.Object3D) {
            if (child.geometry != null) addGeometry(child.geometry);
            if (child.material != null) addMaterial(child.material);
            addCamera(child);
            addHelper(child);
        });
        if (parent == null) {
            scene.add(object);
        } else {
            parent.children.splice(index, 0, object);
            object.parent = parent;
        }
        signals.objectAdded.dispatch(object);
        signals.sceneGraphChanged.dispatch();
    }

    // ... (other methods)

    public function fromJSON(json:Dynamic) {
        var loader:THREE.ObjectLoader = new THREE.ObjectLoader();
        var camera:THREE.Camera = loader.parseAsync(json.camera);
        var existingUuid:String = this.camera.uuid;
        var incomingUuid:String = camera.uuid;
        this.camera.copy(camera);
        this.camera.uuid = incomingUuid;
        delete cameras[existingUuid];
        cameras[incomingUuid] = this.camera;
        signals.cameraResetted.dispatch();
        history.fromJSON(json.history);
        scripts = json.scripts;
        setScene(loader.parseAsync(json.scene));
        if (json.environment == 'ModelViewer') {
            signals.sceneEnvironmentChanged.dispatch(json.environment);
            signals.refreshSidebarEnvironment.dispatch();
        }
    }

    public function toJSON():Dynamic {
        var scripts:Map<String, Array<Dynamic>> = this.scripts;
        for (key in scripts.keys()) {
            var script:Array<Dynamic> = scripts[key];
            if (script.length == 0 || scene.getObjectByProperty('uuid', key) == null) {
                delete scripts[key];
            }
        }
        var environment:String = null;
        if (scene.environment != null && scene.environment.isRenderTargetTexture) {
            environment = 'ModelViewer';
        }
        return {
            metadata: {},
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

    // ... (other methods)
}