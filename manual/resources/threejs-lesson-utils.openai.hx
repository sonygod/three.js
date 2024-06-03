package three.js.manual.resources;

import three.js.Three;
import three.js.examples.jsm.controls.OrbitControls;

class ThreejsLessonUtils {
    private var _afterPrettifyFuncs:Array<Void->Void> = [];
    private var renderer:Three.WebGLRenderer;
    private var elemToRenderFuncMap:Map<JsHtmlElement, Three.WebGLRenderer->Float->Bool>;
    private var elementsOnScreen:Set<JsHtmlElement>;
    private var intersectionObserver:IntersectionObserver;
    private var rafRequestId:Int;
    private var rafRunning:Bool;
    private var clearfix:Three.Color;

    public function new() {}

    public function init(?options:{ threejsOptions:{}}) {
        if (renderer != null) return;
        var canvas:JsHtmlElement = js.Browser.document.createElement("canvas");
        canvas.id = "c";
        js.Browser.document.body.appendChild(canvas);
        renderer = new Three.WebGLRenderer({
            canvas: canvas,
            alpha: true,
            antialias: true,
            powerPreference: low-power,
            // merge options.threejsOptions
            for (field in Reflect.fields(options.threejsOptions)) {
                Reflect.setField(this.renderer, field, Reflect.field(options.threejsOptions, field));
            }
        });
        this.pixelRatio = js.Browser.window.devicePixelRatio;
        this.elemToRenderFuncMap = new Map();
        this.elementsOnScreen = new Set();
        intersectionObserver = new IntersectionObserver(onIntersection);
        clearInterval();
    }

    private function resizeRendererToDisplaySize(renderer:Three.WebGLRenderer) {
        var canvas:JsHtmlElement = renderer.domElement;
        var width:Int = canvas.clientWidth * this.pixelRatio | 0;
        var height:Int = canvas.clientHeight * this.pixelRatio | 0;
        var needResize:Bool = canvas.width != width || canvas.height != height;
        if (needResize) {
            renderer.setSize(width, height, false);
        }
        return needResize;
    }

    private function render(time:Float) {
        rafRequestId = undefined;
        time *= 0.001;
        var resized:Bool = resizeRendererToDisplaySize(renderer);
        if (needsUpdate) {
            needsUpdate = false;
            renderer.setScissorTest(false);
            renderer.setClearColor(clearColor, 0);
            renderer.clear(true, true);
            renderer.setScissorTest(true);
        }
        var wasRendered:Bool = false;
        for (elem in elementsOnScreen) {
            var fn: Three.WebGLRenderer->Float->Bool = elemToRenderFuncMap.get(elem);
            wasRendered = fn(renderer, time, resized) || wasRendered;
        }
        if (wasRendered) {
            var transform:String = "translateY(" + js.Browser.window.scrollY + "px)";
            renderer.domElement.style.transform = transform;
        }
        if (rafRunning) {
            startRAFLoop();
        }
    }

    private function startRAFLoop() {
        rafRunning = true;
        if (!rafRequestId) {
            rafRequestId = js.Browser.window.requestAnimationFrame(render);
        }
    }

    public function addDiagrams(diagrams:Map<String, Dynamic>) {
        for (elem in js.Browser.document.querySelectorAll('[data-diagram]')) {
            var name:String = elem.dataset.diagram;
            var info:Dynamic = diagrams.get(name);
            if (info == null) {
                throw new js.Error('no diagram: $name');
            }
            addDiagram(elem, info);
        }
    }

    public function addDiagram(elem:JsHtmlElement, info:Dynamic) {
        init();
        var scene:Three.Scene = new Three.Scene();
        var camera:Three.PerspectiveCamera = new Three.PerspectiveCamera(60, 1, 0.1, 50);
        camera.position.z = 15;
        scene.add(camera);
        var root:Three.Object3D = new Three.Object3D();
        scene.add(root);
        var renderInfo:Dynamic = {
            pixelRatio: pixelRatio,
            camera: camera,
            scene: scene,
            root: root,
            renderer: renderer,
            elem: elem
        };
        var promise:Promise<Dynamic> = info.create({
            scene: scene,
            camera: camera,
            renderInfo: renderInfo,
        });
        promise.then(function(result:Dynamic) {
            // ...
        });
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

js.Browser.window.threejsLessonUtils = new ThreejsLessonUtils();