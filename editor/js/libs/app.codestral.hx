import js.Browser.document;
import js.html.CanvasElement;
import js.html.Element;
import js.performance.Performance;
import three.WebGLRenderer;
import three.ObjectLoader;
import three.Camera;
import three.Scene;
import three.Object3D;

class APP {

    public class Player {

        private var renderer:WebGLRenderer;
        private var loader:ObjectLoader;
        private var camera:Camera;
        private var scene:Scene;
        private var events:haxe.ds.StringMap<Array<Dynamic>>;
        private var dom:Element;
        public var canvas:CanvasElement;
        public var width:Int = 500;
        public var height:Int = 500;

        public function new() {
            renderer = new WebGLRenderer({antialias: true});
            renderer.setPixelRatio(js.Browser.window.devicePixelRatio);

            loader = new ObjectLoader();

            events = new haxe.ds.StringMap();

            dom = document.createElement("div");
            canvas = renderer.domElement;
            dom.appendChild(canvas);
        }

        public function load(json:Dynamic) {
            var project = json.project;

            if (project.shadows != null) renderer.shadowMap.enabled = project.shadows;
            if (project.shadowType != null) renderer.shadowMap.type = project.shadowType;
            if (project.toneMapping != null) renderer.toneMapping = project.toneMapping;
            if (project.toneMappingExposure != null) renderer.toneMappingExposure = project.toneMappingExposure;

            setScene(loader.parse(json.scene));
            setCamera(loader.parse(json.camera));

            events = new haxe.ds.StringMap<Array<Dynamic>>();
            events.set("init", []);
            events.set("start", []);
            events.set("stop", []);
            events.set("keydown", []);
            events.set("keyup", []);
            events.set("pointerdown", []);
            events.set("pointerup", []);
            events.set("pointermove", []);
            events.set("update", []);

            for (uuid in json.scripts) {
                var object = scene.getObjectByProperty("uuid", uuid, true);

                if (object == null) {
                    js.Boot.trace("APP.Player: Script without object.", uuid);
                    continue;
                }

                var scripts = json.scripts[uuid];

                for (i in 0...scripts.length) {
                    var script = scripts[i];
                    var source = script.source;
                    var func = js.Function.eval("return function(" + "player,renderer,scene,camera,init,start,stop,keydown,keyup,pointerdown,pointerup,pointermove,update" + "){" + source + "}")();
                    var functions = func(this, renderer, scene, camera);

                    for (name in Reflect.fields(functions)) {
                        if (functions[name] == null) continue;

                        if (!events.exists(name)) {
                            js.Boot.trace("APP.Player: Event type not supported (", name, ")");
                            continue;
                        }

                        var arr = events.get(name);
                        arr.push(functions[name].bind(object));
                    }
                }
            }

            dispatch(events.get("init"), arguments);
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

        private function dispatch(array:Array<Dynamic>, event:Dynamic) {
            for (i in 0...array.length) {
                array[i](event);
            }
        }

        private function animate() {
            var time = Performance.now();

            try {
                dispatch(events.get("update"), { time: time - startTime, delta: time - prevTime });
            } catch (e:Dynamic) {
                js.Boot.trace(e.message != null ? e.message : e, e.stack != null ? e.stack : "");
            }

            renderer.render(scene, camera);
            prevTime = time;
        }

        private var startTime:Float;
        private var prevTime:Float;

        public function play() {
            startTime = prevTime = Performance.now();

            document.addEventListener("keydown", onKeyDown);
            document.addEventListener("keyup", onKeyUp);
            document.addEventListener("pointerdown", onPointerDown);
            document.addEventListener("pointerup", onPointerUp);
            document.addEventListener("pointermove", onPointerMove);

            dispatch(events.get("start"), arguments);

            renderer.setAnimationLoop(animate);
        }

        public function stop() {
            document.removeEventListener("keydown", onKeyDown);
            document.removeEventListener("keyup", onKeyUp);
            document.removeEventListener("pointerdown", onPointerDown);
            document.removeEventListener("pointerup", onPointerUp);
            document.removeEventListener("pointermove", onPointerMove);

            dispatch(events.get("stop"), arguments);

            renderer.setAnimationLoop(null);
        }

        public function render(time:Float) {
            dispatch(events.get("update"), { time: time * 1000, delta: 0 });

            renderer.render(scene, camera);
        }

        public function dispose() {
            renderer.dispose();

            camera = null;
            scene = null;
        }

        private function onKeyDown(event:Dynamic) {
            dispatch(events.get("keydown"), event);
        }

        private function onKeyUp(event:Dynamic) {
            dispatch(events.get("keyup"), event);
        }

        private function onPointerDown(event:Dynamic) {
            dispatch(events.get("pointerdown"), event);
        }

        private function onPointerUp(event:Dynamic) {
            dispatch(events.get("pointerup"), event);
        }

        private function onPointerMove(event:Dynamic) {
            dispatch(events.get("pointermove"), event);
        }
    }
}