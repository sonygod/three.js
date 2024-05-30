package;

import js.Browser.window;
import js.html.Document;
import js.html.Element;
import js.html.HTMLElement;
import js.html.HTMLCanvasElement;
import js.html.HTMLDivElement;
import js.html.Performance;
import js.three.ObjectLoader;
import js.three.Renderer;
import js.three.Scene;
import js.three.WebGLRenderer;

class APP {
    class Player {
        var renderer:Renderer;
        var loader:ObjectLoader;
        var camera:Dynamic;
        var scene:Scene;
        var events:Map<Array<Dynamic -> Void>>;
        var dom:HTMLElement;
        var canvas:HTMLCanvasElement;
        var width:Int;
        var height:Int;

        public function new() {
            renderer = new WebGLRenderer({ antialias: true });
            renderer.setPixelRatio(window.devicePixelRatio);

            loader = new ObjectLoader();
            scene = null;
            camera = null;
            events = Map();
            events.set("init", []);
            events.set("start", []);
            events.set("stop", []);
            events.set("keydown", []);
            events.set("keyup", []);
            events.set("pointerdown", []);
            events.set("pointerup", []);
            events.set("pointermove", []);
            events.set("update", []);

            dom = document.createElement("div") as HTMLDivElement;
            canvas = renderer.domElement as HTMLCanvasElement;
            dom.appendChild(canvas);

            width = 500;
            height = 500;
        }

        public function load(json:Map<Dynamic>):Void {
            var project = json.get("project");

            if (project != null) {
                if (project.hasOwnProperty("shadows")) renderer.shadowMap.enabled = project.shadows;
                if (project.hasOwnProperty("shadowType")) renderer.shadowMap.type = project.shadowType;
                if (project.hasOwnProperty("toneMapping")) renderer.toneMapping = project.toneMapping;
                if (project.hasOwnProperty("toneMappingExposure")) renderer.toneMappingExposure = project.toneMappingExposure;
            }

            scene = loader.parse(json.get("scene")) as Scene;
            camera = loader.parse(json.get("camera"));

            setScene(scene);
            setCamera(camera);

            var scriptWrapParams = ["player", "renderer", "scene", "camera"];
            var scriptWrapResultObj = {
                init: "init",
                start: "start",
                stop: "stop",
                keydown: "keydown",
                keyup: "keyup",
                pointerdown: "pointerdown",
                pointerup: "pointerup",
                pointermove: "pointermove",
                update: "update"
            };

            var scriptWrapResult = Std.string(scriptWrapResultObj).replace("\"", "");

            var jsonScripts = json.get("scripts") as Map<Array<Map<String>>>;
            if (jsonScripts != null) {
                for (uuid in jsonScripts) {
                    var object = scene.getObjectByProperty("uuid", uuid, true);
                    if (object == null) {
                        trace("APP.Player: Script without object. " + uuid);
                        continue;
                    }

                    var scripts = jsonScripts.get(uuid);
                    for (script in scripts) {
                        var functions = untyped (function($scriptWrapParams, $script) {
                            #if js
                            return eval($script);
                            #end
                        })(scriptWrapParams, script.source + "\nreturn " + scriptWrapResult + ";");

                        for (name in functions) {
                            if (functions[$name] == null) continue;

                            if (!events.exists(name)) {
                                trace("APP.Player: Event type not supported (" + name + ")");
                                continue;
                            }

                            events.get(name).push(functions[$name]);
                        }
                    }
                }
            }

            dispatch("init", arguments);
        }

        public function setCamera(value:Dynamic):Void {
            camera = value;
            camera.aspect = width / height;
            camera.updateProjectionMatrix();
        }

        public function setScene(value:Scene):Void {
            scene = value;
        }

        public function setPixelRatio(pixelRatio:Float):Void {
            renderer.setPixelRatio(pixelRatio);
        }

        public function setSize(width:Int, height:Int):Void {
            this.width = width;
            this.height = height;

            if (camera != null) {
                camera.aspect = width / height;
                camera.updateProjectionMatrix();
            }

            renderer.setSize(width, height);
        }

        function dispatch(eventName:String, event:Dynamic):Void {
            var eventArray = events.get(eventName);
            if (eventArray != null) {
                for (callback in eventArray) {
                    callback(event);
                }
            }
        }

        var time:Float;
        var startTime:Float;
        var prevTime:Float;

        function animate():Void {
            time = Performance.now();

            try {
                dispatch("update", { time: time - startTime, delta: time - prevTime });
            } catch (e:Dynamic) {
                trace(e.message, e.stack);
            }

            renderer.render(scene, camera);

            prevTime = time;
        }

        public function play():Void {
            startTime = prevTime = Performance.now();

            document.addEventListener("keydown", onKeyDown);
            document.addEventListener("keyup", onKeyUp);
            document.addEventListener("pointerdown", onPointerDown);
            document.addEventListener("pointerup", onPointerUp);
            document.addEventListener("pointermove", onPointerMove);

            dispatch("start", arguments);

            renderer.setAnimationLoop(animate);
        }

        public function stop():Void {
            document.removeEventListener("keydown", onKeyDown);
            document.removeEventListener("keyup", onKeyUp);
            document.removeEventListener("pointerdown", onPointerDown);
            document.removeEventListener("pointerup", onPointerUp);
            document.removeEventListener("pointermove", onPointerMove);

            dispatch("stop", arguments);

            renderer.setAnimationLoop(null);
        }

        public function render(time:Float):Void {
            dispatch("update", { time: time * 1000, delta: 0 });
            renderer.render(scene, camera);
        }

        public function dispose():Void {
            renderer.dispose();
            camera = null;
            scene = null;
        }

        function onKeyDown(event:Dynamic):Void {
            dispatch("keydown", event);
        }

        function onKeyUp(event:Dynamic):Void {
            dispatch("keyup", event);
        }

        function onPointerDown(event:Dynamic):Void {
            dispatch("pointerdown", event);
        }

        function onPointerUp(event:Dynamic):Void {
            dispatch("pointerup", event);
        }

        function onPointerMove(event:Dynamic):Void {
            dispatch("pointermove", event);
        }
    }
}