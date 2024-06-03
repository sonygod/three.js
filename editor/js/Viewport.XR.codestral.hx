import three.THREE;
import three.addons.interactive.HTMLMesh;
import three.addons.interactive.InteractiveGroup;
import three.addons.webxr.XRControllerModelFactory;

class XR {

    private var selector: any;
    private var signals: any;
    private var controllers: THREE.Group;
    private var group: InteractiveGroup;
    private var renderer: THREE.WebGLRenderer;
    private var camera: THREE.PerspectiveCamera;

    public function new(editor: any, controls: any) {
        this.selector = editor.selector;
        this.signals = editor.signals;

        this.controllers = null;
        this.group = null;
        this.renderer = null;

        this.camera = new THREE.PerspectiveCamera();

        this.signals.rendererCreated.add((value: THREE.WebGLRenderer) => {
            this.renderer = value;
        });

        this.signals.enterXR.add((mode: String) => {
            if(js.Browser.window.navigator.xr != null) {
                var sessionInit = { optionalFeatures: ["local-floor"] };
                js.Browser.window.navigator.xr.requestSession(mode, sessionInit).then(this.onSessionStarted.bind(this));
            }
        });

        this.signals.offerXR.add((mode: String) => {
            if(js.Browser.window.navigator.xr != null) {
                var sessionInit = { optionalFeatures: ["local-floor"] };
                js.Browser.window.navigator.xr.offerSession(mode, sessionInit).then(this.onSessionStarted.bind(this));

                this.signals.leaveXR.add(() => {
                    js.Browser.window.navigator.xr.offerSession(mode, sessionInit).then(this.onSessionStarted.bind(this));
                });
            }
        });
    }

    private function onSessionStarted(session: any): Void {
        this.camera.copy(this.editor.camera);

        var sidebar = js.Browser.document.getElementById('sidebar');
        sidebar.style.width = '350px';
        sidebar.style.height = '700px';

        if(this.controllers == null) {
            this.controllers = new THREE.Group();

            var geometry = new THREE.BufferGeometry();
            geometry.setAttribute('position', new THREE.Float32BufferAttribute([0, 0, 0, 0, 0, -5], 3));

            var line = new THREE.Line(geometry);
            var raycaster = new THREE.Raycaster();

            var controller1 = this.renderer.xr.getController(0);
            controller1.addEventListener('select', this.onSelect.bind(this));
            controller1.addEventListener('selectstart', this.onControllerEvent.bind(this));
            controller1.addEventListener('selectend', this.onControllerEvent.bind(this));
            controller1.addEventListener('move', this.onControllerEvent.bind(this));
            controller1.userData.active = false;
            this.controllers.add(controller1);

            var controller2 = this.renderer.xr.getController(1);
            controller2.addEventListener('select', this.onSelect.bind(this));
            controller2.addEventListener('selectstart', this.onControllerEvent.bind(this));
            controller2.addEventListener('selectend', this.onControllerEvent.bind(this));
            controller2.addEventListener('move', this.onControllerEvent.bind(this));
            controller2.userData.active = true;
            this.controllers.add(controller2);

            var controllerModelFactory = new XRControllerModelFactory();

            var controllerGrip1 = this.renderer.xr.getControllerGrip(0);
            controllerGrip1.add(controllerModelFactory.createControllerModel(controllerGrip1));
            this.controllers.add(controllerGrip1);

            var controllerGrip2 = this.renderer.xr.getControllerGrip(1);
            controllerGrip2.add(controllerModelFactory.createControllerModel(controllerGrip2));
            this.controllers.add(controllerGrip2);

            this.group = new InteractiveGroup();

            var mesh = new HTMLMesh(sidebar);
            mesh.name = 'picker';
            mesh.position.set(0.5, 1.0, -0.5);
            mesh.rotation.y = -0.5;
            this.group.add(mesh);

            this.group.listenToXRControllerEvents(controller1);
            this.group.listenToXRControllerEvents(controller2);
        }

        this.editor.sceneHelpers.add(this.group);
        this.editor.sceneHelpers.add(this.controllers);

        this.renderer.xr.enabled = true;
        this.renderer.xr.addEventListener('sessionend', this.onSessionEnded.bind(this));

        this.renderer.xr.setSession(session);
    }

    private function onSessionEnded(event: any): Void {
        this.editor.sceneHelpers.remove(this.group);
        this.editor.sceneHelpers.remove(this.controllers);

        var sidebar = js.Browser.document.getElementById('sidebar');
        sidebar.style.width = '';
        sidebar.style.height = '';

        this.renderer.xr.removeEventListener('sessionend', this.onSessionEnded.bind(this));
        this.renderer.xr.enabled = false;

        this.editor.camera.copy(this.camera);

        this.signals.windowResize.dispatch();
        this.signals.leaveXR.dispatch();
    }

    private function onSelect(event: any): Void {
        var controller = event.target;

        controller1.userData.active = false;
        controller2.userData.active = false;

        if(controller == controller1) {
            controller1.userData.active = true;
            controller1.add(line);
        }

        if(controller == controller2) {
            controller2.userData.active = true;
            controller2.add(line);
        }

        raycaster.setFromXRController(controller);

        var intersects = this.selector.getIntersects(raycaster);

        if(intersects.length > 0) {
            if(intersects[0].object == this.group.children[0]) return;
        }

        this.signals.intersectionsDetected.dispatch(intersects);
    }

    private function onControllerEvent(event: any): Void {
        var controller = event.target;

        if(controller.userData.active == false) return;

        this.controls.getRaycaster().setFromXRController(controller);

        switch(event.type) {
            case 'selectstart':
                this.controls.pointerDown(null);
                break;

            case 'selectend':
                this.controls.pointerUp(null);
                break;

            case 'move':
                this.controls.pointerHover(null);
                this.controls.pointerMove(null);
                break;
        }
    }
}