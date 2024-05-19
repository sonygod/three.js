package three.js.manual.resources;

import js.three.*;

class ThreejsLessonUtils {
    private var _afterPrettifyFuncs:Array<Void->Void> = [];
    private var renderer:WebGLRenderer;
    private var elemToRenderFuncMap:Map<js.html.Element, WebGLRenderer->Float->Bool->Void> = new Map();
    private var elementsOnScreen:Set<js.html.Element> = new Set();
    private var intersectionObserver:IntersectionObserver;
    private var pixelRatio:Float;

    public function new() {}

    public function init(?options:{threejsOptions:{}}) {
        if (renderer != null) return;

        var canvas = js.Browser.document.createElement("canvas");
        canvas.id = "c";
        js.Browser.document.body.appendChild(canvas);
        renderer = new WebGLRenderer({
            canvas: canvas,
            alpha: true,
            antialias: true,
            powerPreference: 'low-power',
            ...(options.threejsOptions != null ? options.threejsOptions : {})
        });
        pixelRatio = js.Browser.window.devicePixelRatio;

        elemToRenderFuncMap = new Map();
        elementsOnScreen = new Set();
        intersectionObserver = new IntersectionObserver((entries:Array<IntersectionObserverEntry>) -> {
            for (entry in entries) {
                if (entry.isIntersecting) {
                    elementsOnScreen.add(entry.target);
                } else {
                    elementsOnScreen.remove(entry.target);
                }
                if (elementsOnScreen.size > 0) {
                    startRAFLoop();
                } else {
                    rafRunning = false;
                }
            }
        });

        var resizeRendererToDisplaySize = (renderer:WebGLRenderer) -> {
            var canvas = renderer.domElement;
            var width = canvas.clientWidth * pixelRatio | 0;
            var height = canvas.clientHeight * pixelRatio | 0;
            var needResize = canvas.width != width || canvas.height != height;
            if (needResize) {
                renderer.setSize(width, height, false);
            }
            return needResize;
        };

        var clearColor = new Color(0x000000);
        var needsUpdate = true;
        var rafRequestId:Int;
        var rafRunning:Bool;

        var render = (time:Float) -> {
            rafRequestId = null;
            time *= 0.001;

            var resized = resizeRendererToDisplaySize(renderer);

            if (needsUpdate) {
                needsUpdate = false;
                renderer.setScissorTest(false);
                renderer.setClearColor(clearColor, 0);
                renderer.clear(true, true);
                renderer.setScissorTest(true);
            }

            for (elem in elementsOnScreen.keys()) {
                var fn = elemToRenderFuncMap.get(elem);
                var wasRendered = fn(renderer, time, resized);
                needsUpdate = needsUpdate || wasRendered;
            }

            if (needsUpdate) {
                var transform = 'translateY(${js.Browser.window.scrollY}px)';
                renderer.domElement.style.transform = transform;
            }

            if (rafRunning) {
                startRAFLoop();
            }
        };

        var startRAFLoop = () -> {
            rafRunning = true;
            if (rafRequestId == null) {
                rafRequestId = js.Browser.window.requestAnimationFrame(render);
            }
        };
    }

    public function addDiagrams(diagrams:Dynamic) {
        for (elem in js.Lib.document.querySelectorAll('[data-diagram]')) {
            var name = elem.dataset.diagram;
            var info = diagrams[name];
            if (info == null) {
                throw new js.Error('no diagram: $name');
            }
            addDiagram(elem, info);
        }
    }

    public function addDiagram(elem:js.html.Element, info:Dynamic) {
        init();

        var scene = new Scene();
        var targetFOVDeg = 60;
        var aspect = 1;
        var near = 0.1;
        var far = 50;
        var camera = new PerspectiveCamera(targetFOVDeg, aspect, near, far);
        camera.position.z = 15;
        scene.add(camera);

        var root = new Object3D();
        scene.add(root);

        var renderInfo = {
            pixelRatio: pixelRatio,
            camera: camera,
            scene: scene,
            root: root,
            renderer: renderer,
            elem: elem
        };

        var obj3DPromise:Promise<Object3D> = info.create({ scene: scene, camera: camera, renderInfo: renderInfo });
        var updateFunctions:Array<Void->Void> = [];
        var resizeFunctions:Array<Void->Void> = [];

        var settings = {
            lights: true,
            trackball: true,
            render: (renderInfo) -> {
                renderInfo.renderer.render(renderInfo.scene, renderInfo.camera);
            }
        };

        obj3DPromise.then((result:Object3D) -> {
            var info = if (result instanceof Object3D) {
                { obj3D: result }
            } else {
                result;
            };

            if (info.obj3D != null) {
                root.add(info.obj3D);
            }

            if (info.update != null) {
                updateFunctions.push(info.update);
            }

            if (info.resize != null) {
                resizeFunctions.push(info.resize);
            }

            if (info.camera != null) {
                camera = info.camera;
                renderInfo.camera = camera;
            }

            js.Lib.object.assign(settings, info);
            targetFOVDeg = camera.fov;

            if (settings.trackball != false) {
                var controls = new OrbitControls(camera, elem);
                controls.rotateSpeed = 1 / 6;
                controls.enableZoom = false;
                controls.enablePan = false;
                elem.removeAttribute('tabIndex');
                // resizeFunctions.push(controls.handleResize.bind(controls));
                updateFunctions.push(controls.update.bind(controls));
            }

            if (settings.lights != false) {
                camera.add(new HemisphereLight(0xaaaaaa, 0x444444, .5));
                var light = new DirectionalLight(0xffffff, 1);
                light.position.set(-1, 2, 4 - 15);
                camera.add(light);
            }
        });

        var oldWidth = -1;
        var oldHeight = -1;

        var render = (renderer:WebGLRenderer, time:Float) -> {
            root.rotation.x = time * 0.1;
            root.rotation.y = time * 0.11;

            var rect = elem.getBoundingClientRect();
            if (rect.bottom < 0 || rect.top > renderer.domElement.clientHeight ||
                rect.right < 0 || rect.left > renderer.domElement.clientWidth) {
                return false;
            }

            renderInfo.width = rect.width * pixelRatio;
            renderInfo.height = rect.height * pixelRatio;
            renderInfo.left = rect.left * pixelRatio;
            renderInfo.bottom = (renderer.domElement.clientHeight - rect.bottom) * pixelRatio;

            if (renderInfo.width != oldWidth || renderInfo.height != oldHeight) {
                oldWidth = renderInfo.width;
                oldHeight = renderInfo.height;
                for (fn in resizeFunctions) {
                    fn(renderInfo);
                }
            }

            for (fn in updateFunctions) {
                fn(time, renderInfo);
            }

            var aspect = renderInfo.width / renderInfo.height;
            var fovDeg = if (aspect >= 1) {
                targetFOVDeg
            } else {
                MathUtils.radToDeg(2 * Math.atan(Math.tan(MathUtils.degToRad(targetFOVDeg) * 0.5) / aspect));
            };

            camera.fov = fovDeg;
            camera.aspect = aspect;
            camera.updateProjectionMatrix();

            renderer.setViewport(renderInfo.left, renderInfo.bottom, renderInfo.width, renderInfo.height);
            renderer.setScissor(renderInfo.left, renderInfo.bottom, renderInfo.width, renderInfo.height);

            settings.render(renderInfo);

            return true;
        };

        intersectionObserver.observe(elem);
        elemToRenderFuncMap.set(elem, render);
    }

    public function onAfterPrettify(fn:Void->Void) {
        _afterPrettifyFuncs.push(fn);
    }

    public function afterPrettify() {
        for (fn in _afterPrettifyFuncs) {
            fn();
        }
    }
}