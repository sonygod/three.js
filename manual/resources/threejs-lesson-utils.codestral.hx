import js.Browser.document;
import three.THREE;
import three.examples.jsm.controls.OrbitControls;

class ThreeJSLessonUtils {
    public var _afterPrettifyFuncs: Array<Void -> Void> = [];
    public var renderer: THREE.WebGLRenderer;
    public var pixelRatio: Float;
    public var elemToRenderFuncMap: Map<Element, (THREE.WebGLRenderer, Float, Bool) -> Bool>;
    public var elementsOnScreen: Set<Element>;
    public var intersectionObserver: IntersectionObserver;

    public function init(options: Dynamic = { threejsOptions: {} }) {
        if (this.renderer != null) return;

        var canvas: CanvasElement = document.createElement("canvas");
        canvas.id = "c";
        document.body.appendChild(canvas);
        this.renderer = new THREE.WebGLRenderer({
            canvas: canvas,
            alpha: true,
            antialias: true,
            powerPreference: "low-power",
            ...options.threejsOptions
        });
        this.pixelRatio = js.Browser.window.devicePixelRatio;

        this.elemToRenderFuncMap = new Map();

        var clearColor: THREE.Color = new THREE.Color("#000");
        var needsUpdate: Bool = true;
        var rafRequestId: Int = 0;
        var rafRunning: Bool = false;

        var resizeRendererToDisplaySize = (renderer: THREE.WebGLRenderer) => {
            var canvas: CanvasElement = renderer.domElement;
            var width: Int = (canvas.clientWidth * this.pixelRatio) | 0;
            var height: Int = (canvas.clientHeight * this.pixelRatio) | 0;
            var needResize: Bool = canvas.width != width || canvas.height != height;
            if (needResize) renderer.setSize(width, height, false);
            return needResize;
        };

        var render = (time: Float) => {
            rafRequestId = 0;
            time *= 0.001;

            var resized: Bool = resizeRendererToDisplaySize(this.renderer);

            if (needsUpdate) {
                needsUpdate = false;
                this.renderer.setScissorTest(false);
                this.renderer.setClearColor(clearColor, 0);
                this.renderer.clear(true, true);
                this.renderer.setScissorTest(true);
            }

            for (elem in this.elementsOnScreen) {
                var fn: (THREE.WebGLRenderer, Float, Bool) -> Bool = this.elemToRenderFuncMap.get(elem);
                var wasRendered: Bool = fn(this.renderer, time, resized);
                needsUpdate = needsUpdate || wasRendered;
            }

            if (needsUpdate) {
                var transform: String = "translateY(" + js.Browser.window.scrollY + "px)";
                this.renderer.domElement.style.transform = transform;
            }

            if (rafRunning) startRAFLoop();
        };

        var startRAFLoop = () => {
            rafRunning = true;
            if (rafRequestId == 0) rafRequestId = js.Browser.window.requestAnimationFrame(render);
        };

        this.elementsOnScreen = new Set();
        this.intersectionObserver = new IntersectionObserver((entries: Array<IntersectionObserverEntry>) => {
            for (entry in entries) {
                if (entry.isIntersecting) this.elementsOnScreen.add(entry.target);
                else this.elementsOnScreen.delete(entry.target);
            }

            if (this.elementsOnScreen.size > 0) startRAFLoop();
            else rafRunning = false;
        });
    }

    public function addDiagrams(diagrams: Dynamic) {
        var elems: Array<Element> = Array.from(document.querySelectorAll('[data-diagram]'));
        for (elem in elems) {
            var name: String = elem.dataset.diagram;
            var info: Dynamic = diagrams[name];
            if (info == null) throw new js.Error("no diagram: " + name);
            this.addDiagram(elem, info);
        }
    }

    public function addDiagram(elem: Element, info: Dynamic) {
        this.init();

        var scene: THREE.Scene = new THREE.Scene();
        var targetFOVDeg: Float = 60;
        var aspect: Float = 1;
        var near: Float = 0.1;
        var far: Float = 50;
        var camera: THREE.PerspectiveCamera = new THREE.PerspectiveCamera(targetFOVDeg, aspect, near, far);
        camera.position.z = 15;
        scene.add(camera);

        var root: THREE.Object3D = new THREE.Object3D();
        scene.add(root);

        var renderInfo = {
            pixelRatio: this.pixelRatio,
            camera: camera,
            scene: scene,
            root: root,
            renderer: this.renderer,
            elem: elem
        };

        var obj3D: THREE.Object3D = info.create({ scene: scene, camera: camera, renderInfo: renderInfo });
        var promise: Promise<Dynamic> = obj3D is Promise ? obj3D : Promise.resolve(obj3D);

        var updateFunctions: Array<(Float, Dynamic) -> Void> = [];
        var resizeFunctions: Array<(Dynamic) -> Void> = [];

        var settings: Dynamic = {
            lights: true,
            trackball: true,
            render: (renderInfo: Dynamic) => {
                renderInfo.renderer.render(renderInfo.scene, renderInfo.camera);
            }
        };

        promise.then((result: Dynamic) => {
            var info: Dynamic = result is THREE.Object3D ? { obj3D: result } : result;
            if (info.obj3D != null) root.add(info.obj3D);

            if (info.update != null) updateFunctions.push(info.update);

            if (info.resize != null) resizeFunctions.push(info.resize);

            if (info.camera != null) {
                camera = info.camera;
                renderInfo.camera = camera;
            }

            js.Boot.copy(info, settings);
            targetFOVDeg = camera.fov;

            if (settings.trackball != false) {
                var controls: OrbitControls = new OrbitControls(camera, elem);
                controls.rotateSpeed = 1 / 6;
                controls.enableZoom = false;
                controls.enablePan = false;
                elem.removeAttribute("tabIndex");
                updateFunctions.push(controls.update);
            }

            if (settings.lights != false) {
                camera.add(new THREE.HemisphereLight(0xaaaaaa, 0x444444, .5));
                var light: THREE.DirectionalLight = new THREE.DirectionalLight(0xffffff, 1);
                light.position.set(-1, 2, 4 - 15);
                camera.add(light);
            }
        });

        var oldWidth: Int = -1;
        var oldHeight: Int = -1;

        var render = (renderer: THREE.WebGLRenderer, time: Float): Bool => {
            root.rotation.x = time * .1;
            root.rotation.y = time * .11;

            var rect: ClientRect = elem.getBoundingClientRect();
            if (rect.bottom < 0 || rect.top > renderer.domElement.clientHeight ||
                rect.right < 0 || rect.left > renderer.domElement.clientWidth) {
                return false;
            }

            renderInfo.width = rect.width * this.pixelRatio;
            renderInfo.height = rect.height * this.pixelRatio;
            renderInfo.left = rect.left * this.pixelRatio;
            renderInfo.bottom = (renderer.domElement.clientHeight - rect.bottom) * this.pixelRatio;

            if (renderInfo.width != oldWidth || renderInfo.height != oldHeight) {
                oldWidth = renderInfo.width;
                oldHeight = renderInfo.height;
                for (fn in resizeFunctions) fn(renderInfo);
            }

            for (fn in updateFunctions) fn(time, renderInfo);

            var aspect: Float = renderInfo.width / renderInfo.height;
            var fovDeg: Float = aspect >= 1 ? targetFOVDeg : THREE.MathUtils.radToDeg(2 * Math.atan(Math.tan(THREE.MathUtils.degToRad(targetFOVDeg) * .5) / aspect));

            camera.fov = fovDeg;
            camera.aspect = aspect;
            camera.updateProjectionMatrix();

            renderer.setViewport(renderInfo.left, renderInfo.bottom, renderInfo.width, renderInfo.height);
            renderer.setScissor(renderInfo.left, renderInfo.bottom, renderInfo.width, renderInfo.height);

            settings.render(renderInfo);

            return true;
        };

        this.intersectionObserver.observe(elem);
        this.elemToRenderFuncMap.set(elem, render);
    }

    public function onAfterPrettify(fn: Void -> Void) {
        this._afterPrettifyFuncs.push(fn);
    }

    public function afterPrettify() {
        for (fn in this._afterPrettifyFuncs) fn();
    }
}

var threejsLessonUtils = new ThreeJSLessonUtils();
js.Browser.window.threejsLessonUtils = threejsLessonUtils;