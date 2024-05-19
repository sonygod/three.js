package ;

import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.PointerEvent;
import js.Lib;
import threejs.Loader;
import threejs.ObjectLoader;
import threejs.Renderer;
import threejs.Scene;
import threejs.Camera;
import threejs.WebGLRenderer;

class APP {
    public static var player:Player;

    public static function main() {
        player = new Player();
    }
}

class Player {
    public var dom:Element;
    public var canvas:Element;
    public var width:Int;
    public var height:Int;
    public var renderer:WebGLRenderer;
    public var camera:Camera;
    public var scene:Scene;
    public var events:Map<String, Array<Dynamic->Void>>;

    public function new() {
        renderer = new WebGLRenderer({ antialias: true });
        renderer.setPixelRatio(Lib.window.devicePixelRatio);
        var loader:ObjectLoader = new ObjectLoader();
        dom = Document.createElement('div');
        dom.appendChild(renderer.domElement);
        this.dom = dom;
        this.canvas = renderer.domElement;
        this.width = 500;
        this.height = 500;
        events = new Map<String, Array<Dynamic->Void>>();
        events.set('init', new Array<Dynamic->Void>());
        events.set('start', new Array<Dynamic->Void>());
        events.set('stop', new Array<Dynamic->Void>());
        events.set('keydown', new Array<Dynamic->Void>());
        events.set('keyup', new Array<Dynamic->Void>());
        events.set('pointerdown', new Array<Dynamic->Void>());
        events.set('pointerup', new Array<Dynamic->Void>());
        events.set('pointermove', new Array<Dynamic->Void>());
        events.set('update', new Array<Dynamic->Void>());
    }

    public function load(json:Dynamic) {
        var project = json.project;
        if (project.shadows != null) renderer.shadowMap.enabled = project.shadows;
        if (project.shadowType != null) renderer.shadowMap.type = project.shadowType;
        if (project.toneMapping != null) renderer.toneMapping = project.toneMapping;
        if (project.toneMappingExposure != null) renderer.toneMappingExposure = project.toneMappingExposure;
        this.setScene(loader.parse(json.scene));
        this.setCamera(loader.parse(json.camera));
        for (key in events.keys()) {
            var scriptWrapParams = 'player,renderer,scene,camera';
            var scriptWrapResultObj = {};
            scriptWrapParams += ',' + key;
            scriptWrapResultObj[key] = key;
            var scriptWrapResult = Json.stringify(scriptWrapResultObj).replace(/"/g, '');
            for (uuid in json.scripts) {
                var object = scene.getObjectByProperty('uuid', uuid, true);
                if (object == null) {
                    console.warn('APP.Player: Script without object.', uuid);
                    continue;
                }
                var scripts:Array<Dynamic> = json.scripts[uuid];
                for (i in 0...scripts.length) {
                    var script = scripts[i];
                    var functions = (new Dynamic(scriptWrapParams, script.source + '\nreturn ' + scriptWrapResult + ';').bind(object))(this, renderer, scene, camera);
                    for (name in functions) {
                        if (functions[name] == null) continue;
                        if (events[name] == null) {
                            console.warn('APP.Player: Event type not supported (' + name + ')');
                            continue;
                        }
                        events[name].push(functions[name].bind(object));
                    }
                }
            }
            dispatch(events.init, arguments);
        }
    }

    public function setCamera(value:Camera) {
        camera = value;
        camera.aspect = this.width / this.height;
        camera.updateProjectionMatrix();
    }

    public function setScene(value:Scene) {
        scene = value;
    }

    public function setPixelRatio(pixelRatio:Float) {
        renderer.setPixelRatio(pixelRatio);
    }

    public function setSize(width:Int, height:Int) {
        this.width = width;
        this.height = height;
        if (camera != null) {
            camera.aspect = this.width / this.height;
            camera.updateProjectionMatrix();
        }
        renderer.setSize(width, height);
    }

    public function dispatch(array:Array<Dynamic->Void>, event:Dynamic) {
        for (i in 0...array.length) {
            array[i](event);
        }
    }

    var time:Float;
    var startTime:Float;
    var prevTime:Float;

    function animate() {
        time = Lib.performance.now();
        try {
            dispatch(events.update, { time: time - startTime, delta: time - prevTime } );
        } catch (e:Dynamic) {
            console.error((e.message || e), (e.stack || ''));
        }
        renderer.render(scene, camera);
        prevTime = time;
    }

    public function play() {
        startTime = prevTime = Lib.performance.now();
        Lib.document.addEventListener('keydown', onKeyDown);
        Lib.document.addEventListener('keyup', onKeyUp);
        Lib.document.addEventListener('pointerdown', onPointerDown);
        Lib.document.addEventListener('pointerup', onPointerUp);
        Lib.document.addEventListener('pointermove', onPointerMove);
        dispatch(events.start, arguments);
        renderer.setAnimationLoop(animate);
    }

    public function stop() {
        Lib.document.removeEventListener('keydown', onKeyDown);
        Lib.document.removeEventListener('keyup', onKeyUp);
        Lib.document.removeEventListener('pointerdown', onPointerDown);
        Lib.document.removeEventListener('pointerup', onPointerUp);
        Lib.document.removeEventListener('pointermove', onPointerMove);
        dispatch(events.stop, arguments);
        renderer.setAnimationLoop(null);
    }

    public function render(time:Float) {
        dispatch(events.update, { time: time * 1000, delta: 0 /* TODO */ } );
        renderer.render(scene, camera);
    }

    public function dispose() {
        renderer.dispose();
        camera = null;
        scene = null;
    }

    function onKeyDown(event:KeyboardEvent) {
        dispatch(events.keydown, event);
    }

    function onKeyUp(event:KeyboardEvent) {
        dispatch(events.keyup, event);
    }

    function onPointerDown(event:PointerEvent) {
        dispatch(events.pointerdown, event);
    }

    function onPointerUp(event:PointerEvent) {
        dispatch(events.pointerup, event);
    }

    function onPointerMove(event:PointerEvent) {
        dispatch(events.pointermove, event);
    }
}