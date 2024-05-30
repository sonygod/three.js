package three.js.editor.js.libs;

import js.html.DivElement;
import js.html.CanvasElement;
import three.core.ObjectLoader;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.cameras.Camera;
import js.Browser;
import js.html.Document;
import js.html.Event;

class APP {
    public static var player:Player;

    public static function main() {
        player = new Player();
    }
}

class Player {
    private var renderer:WebGLRenderer;
    private var loader:ObjectLoader;
    private var camera:Camera;
    private var scene:Scene;
    private var events:Map<String, Array<Dynamic->Void>>;
    private var dom:DivElement;
    private var canvas:CanvasElement;

    public function new() {
        renderer = new WebGLRenderer({ antialias: true });
        renderer.setPixelRatio(Browser.window.devicePixelRatio); // TODO: Use player.setPixelRatio()

        loader = new ObjectLoader();

        events = {};

        dom = Browser.document.createDivElement();
        dom.appendChild(renderer.domElement);

        this.dom = dom;
        this.canvas = renderer.domElement;

        this.width = 500;
        this.height = 500;
    }

    public function load(json:Dynamic) {
        var project = json.project;

        if (project.shadows != null) renderer.shadowMap.enabled = project.shadows;
        if (project.shadowType != null) renderer.shadowMap.type = project.shadowType;
        if (project.toneMapping != null) renderer.toneMapping = project.toneMapping;
        if (project.toneMappingExposure != null) renderer.toneMappingExposure = project.toneMappingExposure;

        this.setScene(loader.parse(json.scene));
        this.setCamera(loader.parse(json.camera));

        events = {
            init: [],
            start: [],
            stop: [],
            keydown: [],
            keyup: [],
            pointerdown: [],
            pointerup: [],
            pointermove: [],
            update: []
        };

        var scriptWrapParams:String = 'player,renderer,scene,camera';
        var scriptWrapResultObj:Dynamic = {};

        for (var eventKey in events) {
            scriptWrapParams += ',' + eventKey;
            scriptWrapResultObj[eventKey] = eventKey;
        }

        var scriptWrapResult:String = Json.stringify(scriptWrapResultObj).replace(/\"/g, '');

        for (var uuid in json.scripts) {
            var object:Dynamic = scene.getObjectByProperty('uuid', uuid, true);

            if (object == null) {
                Browser.console.warn('APP.Player: Script without object.', uuid);
                continue;
            }

            var scripts:Array<Dynamic> = json.scripts[uuid];

            for (var i in 0...scripts.length) {
                var script:Dynamic = scripts[i];

                var functions:Dynamic = Reflect.callMethod(null, script.source + '\nreturn ' + scriptWrapResult + ';', [this, renderer, scene, camera]);

                for (var name:String in functions) {
                    if (functions[name] == null) continue;

                    if (events[name] == null) {
                        Browser.console.warn('APP.Player: Event type not supported (', name, ')');
                        continue;
                    }

                    events[name].push(Reflect.bind(functions[name], object));
                }
            }
        }

        dispatch(events.init, arguments);
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

    private function dispatch(array:Array<Dynamic->Void>, event:Dynamic) {
        for (i in 0...array.length) {
            array[i](event);
        }
    }

    private var time:Float;
    private var startTime:Float;
    private var prevTime:Float;

    private function animate() {
        time = Browser.performance.now();

        try {
            dispatch(events.update, { time: time - startTime, delta: time - prevTime });
        } catch (e:Dynamic) {
            Browser.console.error((e.message || e), (e.stack || ''));
        }

        renderer.render(scene, camera);

        prevTime = time;
    }

    public function play() {
        startTime = prevTime = Browser.performance.now();

        Browser.document.addEventListener('keydown', onKeyDown);
        Browser.document.addEventListener('keyup', onKeyUp);
        Browser.document.addEventListener('pointerdown', onPointerDown);
        Browser.document.addEventListener('pointerup', onPointerUp);
        Browser.document.addEventListener('pointermove', onPointerMove);

        dispatch(events.start, arguments);

        renderer.setAnimationLoop(animate);
    }

    public function stop() {
        Browser.document.removeEventListener('keydown', onKeyDown);
        Browser.document.removeEventListener('keyup', onKeyUp);
        Browser.document.removeEventListener('pointerdown', onPointerDown);
        Browser.document.removeEventListener('pointerup', onPointerUp);
        Browser.document.removeEventListener('pointermove', onPointerMove);

        dispatch(events.stop, arguments);

        renderer.setAnimationLoop(null);
    }

    public function render(time:Float) {
        dispatch(events.update, { time: time * 1000, delta: 0 /* TODO */ });

        renderer.render(scene, camera);
    }

    public function dispose() {
        renderer.dispose();

        camera = null;
        scene = null;
    }

    private function onKeyDown(event:Event) {
        dispatch(events.keydown, event);
    }

    private function onKeyUp(event:Event) {
        dispatch(events.keyup, event);
    }

    private function onPointerDown(event:Event) {
        dispatch(events.pointerdown, event);
    }

    private function onPointerUp(event:Event) {
        dispatch(events.pointerup, event);
    }

    private function onPointerMove(event:Event) {
        dispatch(events.pointermove, event);
    }
}