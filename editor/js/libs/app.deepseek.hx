package three.js.editor.js.libs;

import js.Browser.document;
import js.Browser.window;
import js.html.Element;
import three.js.THREE.*;

class APP {

    public static function Player() {

        var renderer = new WebGLRenderer({ antialias: true });
        renderer.setPixelRatio(window.devicePixelRatio);

        var loader = new ObjectLoader();
        var camera:PerspectiveCamera;
        var scene:Scene;

        var events = {
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

        var dom = document.createElement('div');
        dom.appendChild(renderer.domElement);

        this.dom = dom;
        this.canvas = renderer.domElement;

        this.width = 500;
        this.height = 500;

        this.load = function(json) {

            var project = json.project;

            if (project.shadows !== undefined) renderer.shadowMap.enabled = project.shadows;
            if (project.shadowType !== undefined) renderer.shadowMap.type = project.shadowType;
            if (project.toneMapping !== undefined) renderer.toneMapping = project.toneMapping;
            if (project.toneMappingExposure !== undefined) renderer.toneMappingExposure = project.toneMappingExposure;

            this.setScene(loader.parse(json.scene));
            this.setCamera(loader.parse(json.camera));

            var scriptWrapParams = 'player,renderer,scene,camera';
            var scriptWrapResultObj = {};

            for (key in events) {

                scriptWrapParams += ',' + key;
                scriptWrapResultObj[key] = key;

            }

            var scriptWrapResult = haxe.Json.encode(scriptWrapResultObj).replace(/\"/g, '');

            for (uuid in json.scripts) {

                var object = scene.getObjectByProperty('uuid', uuid, true);

                if (object === undefined) {

                    trace('APP.Player: Script without object.', uuid);
                    continue;

                }

                var scripts = json.scripts[uuid];

                for (i in scripts) {

                    var script = scripts[i];

                    var functions = (new Function(scriptWrapParams, script.source + '\nreturn ' + scriptWrapResult + ';').bind(object))(this, renderer, scene, camera);

                    for (name in functions) {

                        if (functions[name] === undefined) continue;

                        if (events[name] === undefined) {

                            trace('APP.Player: Event type not supported (', name, ')');
                            continue;

                        }

                        events[name].push(functions[name].bind(object));

                    }

                }

            }

            dispatch(events.init, arguments);

        };

        this.setCamera = function(value) {

            camera = value;
            camera.aspect = this.width / this.height;
            camera.updateProjectionMatrix();

        };

        this.setScene = function(value) {

            scene = value;

        };

        this.setPixelRatio = function(pixelRatio) {

            renderer.setPixelRatio(pixelRatio);

        };

        this.setSize = function(width, height) {

            this.width = width;
            this.height = height;

            if (camera) {

                camera.aspect = this.width / this.height;
                camera.updateProjectionMatrix();

            }

            renderer.setSize(width, height);

        };

        function dispatch(array, event) {

            for (i in array) {

                array[i](event);

            }

        }

        var time:Float;
        var startTime:Float;
        var prevTime:Float;

        function animate() {

            time = window.performance.now();

            try {

                dispatch(events.update, { time: time - startTime, delta: time - prevTime });

            } catch (e:Dynamic) {

                trace((e.message || e), (e.stack || ''));

            }

            renderer.render(scene, camera);

            prevTime = time;

        }

        this.play = function() {

            startTime = prevTime = window.performance.now();

            document.addEventListener('keydown', onKeyDown);
            document.addEventListener('keyup', onKeyUp);
            document.addEventListener('pointerdown', onPointerDown);
            document.addEventListener('pointerup', onPointerUp);
            document.addEventListener('pointermove', onPointerMove);

            dispatch(events.start, arguments);

            renderer.setAnimationLoop(animate);

        };

        this.stop = function() {

            document.removeEventListener('keydown', onKeyDown);
            document.removeEventListener('keyup', onKeyUp);
            document.removeEventListener('pointerdown', onPointerDown);
            document.removeEventListener('pointerup', onPointerUp);
            document.removeEventListener('pointermove', onPointerMove);

            dispatch(events.stop, arguments);

            renderer.setAnimationLoop(null);

        };

        this.render = function(time) {

            dispatch(events.update, { time: time * 1000, delta: 0 /* TODO */ });

            renderer.render(scene, camera);

        };

        this.dispose = function() {

            renderer.dispose();

            camera = null;
            scene = null;

        };

        //

        function onKeyDown(event) {

            dispatch(events.keydown, event);

        }

        function onKeyUp(event) {

            dispatch(events.keyup, event);

        }

        function onPointerDown(event) {

            dispatch(events.pointerdown, event);

        }

        function onPointerUp(event) {

            dispatch(events.pointerup, event);

        }

        function onPointerMove(event) {

            dispatch(events.pointermove, event);

        }

    }

}