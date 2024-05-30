package three.js.editor.js;

import three.js.*;

import interactive.HTMLMesh;
import interactive.InteractiveGroup;

import webxr.XRControllerModelFactory;

class XR {
    private var editor:Dynamic;
    private var controls:Dynamic;
    private var controllers:Group;
    private var group:InteractiveGroup;
    private var renderer:WebGLRenderer;
    private var camera:PerspectiveCamera;

    public function new(editor:Dynamic, controls:Dynamic) {
        this.editor = editor;
        this.controls = controls;

        camera = new PerspectiveCamera();

        editor.signals.enterXR.add(onEnterXR);
        editor.signals.offerXR.add(onOfferXR);
        editor.signals.rendererCreated.add(onRendererCreated);
    }

    private function onEnterXR(mode:String) {
        if (xrSupported()) {
            navigator.xr.requestSession(mode, {optionalFeatures: ['local-floor']}).then(onSessionStarted);
        }
    }

    private function onOfferXR(mode:String) {
        if (xrSupported()) {
            navigator.xr.offerSession(mode, {optionalFeatures: ['local-floor']}).then(onSessionStarted);
            editor.signals.leaveXR.add(function() {
                navigator.xr.offerSession(mode, {optionalFeatures: ['local-floor']}).then(onSessionStarted);
            });
        }
    }

    private function onRendererCreated(renderer:WebGLRenderer) {
        this.renderer = renderer;
    }

    private function onSessionStarted(session:Dynamic) {
        camera.copy(editor.camera);

        var sidebar = js.Browser.document.getElementById('sidebar');
        sidebar.style.width = '350px';
        sidebar.style.height = '700px';

        if (controllers == null) {
            var geometry = new BufferGeometry();
            geometry.setAttribute('position', new Float32BufferAttribute([0, 0, 0, 0, 0, -5], 3));

            var line = new Line(geometry);

            var raycaster = new Raycaster();

            function onSelect(event:Event) {
                var controller:XRController = event.target;

                controller1.userData.active = false;
                controller2.userData.active = false;

                if (controller == controller1) {
                    controller1.userData.active = true;
                    controller1.add(line);
                }

                if (controller == controller2) {
                    controller2.userData.active = true;
                    controller2.add(line);
                }

                raycaster.setFromXRController(controller);

                var intersects = editor.selector.getIntersects(raycaster);

                if (intersects.length > 0) {
                    var intersect = intersects[0];
                    if (intersect.object == group.children[0]) return;

                    editor.signals.intersectionsDetected.dispatch(intersects);
                }
            }

            function onControllerEvent(event:Event) {
                var controller:XRController = event.target;

                if (!controller.userData.active) return;

                controls.getRaycaster().setFromXRController(controller);

                switch (event.type) {
                    case 'selectstart':
                        controls.pointerDown(null);
                        break;
                    case 'selectend':
                        controls.pointerUp(null);
                        break;
                    case 'move':
                        controls.pointerHover(null);
                        controls.pointerMove(null);
                        break;
                }
            }

            controllers = new Group();

            var controller1:XRController = renderer.xr.getController(0);
            controller1.addEventListener('select', onSelect);
            controller1.addEventListener('selectstart', onControllerEvent);
            controller1.addEventListener('selectend', onControllerEvent);
            controller1.addEventListener('move', onControllerEvent);
            controller1.userData.active = false;
            controllers.add(controller1);

            var controller2:XRController = renderer.xr.getController(1);
            controller2.addEventListener('select', onSelect);
            controller2.addEventListener('selectstart', onControllerEvent);
            controller2.addEventListener('selectend', onControllerEvent);
            controller2.addEventListener('move', onControllerEvent);
            controller2.userData.active = true;
            controllers.add(controller2);

            var controllerModelFactory = new XRControllerModelFactory();

            var controllerGrip1:XRControllerGrip = renderer.xr.getControllerGrip(0);
            controllerGrip1.add(controllerModelFactory.createControllerModel(controllerGrip1));
            controllers.add(controllerGrip1);

            var controllerGrip2:XRControllerGrip = renderer.xr.getControllerGrip(1);
            controllerGrip2.add(controllerModelFactory.createControllerModel(controllerGrip2));
            controllers.add(controllerGrip2);

            group = new InteractiveGroup();

            var mesh = new HTMLMesh(sidebar);
            mesh.name = 'picker';
            mesh.position.set(0.5, 1.0, -0.5);
            mesh.rotation.y = -0.5;
            group.add(mesh);

            group.listenToXRControllerEvents(controller1);
            group.listenToXRControllerEvents(controller2);

            editor.sceneHelpers.add(group);
            editor.sceneHelpers.add(controllers);

            renderer.xr.enabled = true;
            renderer.xr.addEventListener('sessionend', onSessionEnded);

            renderer.xr.setSession(session);
        }
    }

    private function onSessionEnded() {
        editor.sceneHelpers.remove(group);
        editor.sceneHelpers.remove(controllers);

        var sidebar = js.Browser.document.getElementById('sidebar');
        sidebar.style.width = '';
        sidebar.style.height = '';

        renderer.xr.removeEventListener('sessionend', onSessionEnded);
        renderer.xr.enabled = false;

        editor.camera.copy(camera);

        editor.signals.windowResize.dispatch();
        editor.signals.leaveXR.dispatch();
    }

    private function xrSupported():Bool {
        return Reflect.hasField(navigator, 'xr');
    }
}