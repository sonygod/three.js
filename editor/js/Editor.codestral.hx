import js.Browser;
import js.html.HTMLAnchorElement;
import js.html.MouseEvent;
import js.html.URL;
import js.lib.ArrayBufferView;
import js.lib.Blob;
import js.lib.Map;
import js.lib.Set;
import signals.Signal;
import three.core.Object3D;
import three.core.PerspectiveCamera;
import three.core.Scene;
import three.extras.AnimationMixer;
import three.extras.HemisphereLightHelper;
import three.extras.SkeletonHelper;
import three.lights.DirectionalLight;
import three.lights.DirectionalLightHelper;
import three.lights.HemisphereLight;
import three.lights.PointLight;
import three.lights.PointLightHelper;
import three.lights.SpotLight;
import three.lights.SpotLightHelper;
import three.objects.Bone;
import three.objects.Camera;
import three.objects.Mesh;
import three.objects.SkinnedMesh;

import Config from './Config';
import Loader from './Loader';
import History from './History';
import Strings from './Strings';
import Storage from './Storage';
import Selector from './Selector';

class Editor {
    public var signals:Map<String, Signal<Dynamic>>;
    public var config:Config;
    public var history:History;
    public var selector:Selector;
    public var storage:Storage;
    public var strings:Strings;
    public var loader:Loader;
    public var camera:PerspectiveCamera;
    public var scene:Scene;
    public var sceneHelpers:Scene;
    public var object:Map<String, Object3D>;
    public var geometries:Map<String, Object>;
    public var materials:Map<String, Object>;
    public var textures:Map<String, Object>;
    public var scripts:Map<String, Array<Dynamic>>;
    public var materialsRefCounter:Map<Object, Int>;
    public var mixer:AnimationMixer;
    public var selected:Object3D;
    public var helpers:Map<Int, Object>;
    public var cameras:Map<String, Camera>;
    public var viewportCamera:Camera;
    public var viewportShading:String;

    private var _DEFAULT_CAMERA:PerspectiveCamera = new PerspectiveCamera( 50, 1, 0.01, 1000 );
    private var link:HTMLAnchorElement = Browser.document.createElement( 'a' );

    public function new() {
        _DEFAULT_CAMERA.name = 'Camera';
        _DEFAULT_CAMERA.position.set( 0, 5, 10 );
        _DEFAULT_CAMERA.lookAt( new THREE.Vector3() );

        signals = new Map<String, Signal<Dynamic>>();
        // Initialize other signals...

        config = new Config();
        history = new History(this);
        selector = new Selector(this);
        storage = new Storage();
        strings = new Strings(config);

        loader = new Loader(this);

        camera = _DEFAULT_CAMERA.clone();

        scene = new Scene();
        scene.name = 'Scene';

        sceneHelpers = new Scene();
        sceneHelpers.add(new HemisphereLight(0xffffff, 0x888888, 2));

        object = new Map<String, Object3D>();
        geometries = new Map<String, Object>();
        materials = new Map<String, Object>();
        textures = new Map<String, Object>();
        scripts = new Map<String, Array<Dynamic>>();

        materialsRefCounter = new Map<Object, Int>();

        mixer = new AnimationMixer(scene);

        selected = null;
        helpers = new Map<Int, Object>();

        cameras = new Map<String, Camera>();

        viewportCamera = camera;
        viewportShading = 'default';

        addCamera(camera);
    }

    // Implement other methods...

    public function save(blob:Blob, filename:String):Void {
        if (link.href != null) {
            URL.revokeObjectURL(link.href);
        }

        link.href = URL.createObjectURL(blob);
        link.download = filename || 'data.json';
        link.dispatchEvent(new MouseEvent('click'));
    }

    public function saveArrayBuffer(buffer:ArrayBufferView, filename:String):Void {
        save(new Blob([buffer], { type: 'application/octet-stream' }), filename);
    }

    public function saveString(text:String, filename:String):Void {
        save(new Blob([text], { type: 'text/plain' }), filename);
    }

    public function formatNumber(number:Float):String {
        return new Intl.NumberFormat('en-us', { useGrouping: true }).format(number);
    }
}