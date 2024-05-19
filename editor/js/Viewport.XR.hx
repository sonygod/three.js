package three.js.editor.js;

import three.js.lib.*;

import interactive.HTMLMesh;
import interactive.InteractiveGroup;

import webxr.XRControllerModelFactory;

class XR {
    private var editor:Dynamic;
    private var controls:Dynamic;
    private var controllers:three.js.Group;
    private var group:three.js.Group;
    private var renderer:three.js.WebGLRenderer;

    public function new(editor:Dynamic, controls:Dynamic) {
        this.editor = editor;
        this.controls = controls;

        var camera:three.js.PerspectiveCamera = new three.js.PerspectiveCamera();

        var onSessionStarted = function(session:Dynamic) {
            camera.copy(editor.camera);

            var sidebar:js.html.Element = js.Browser.document.getElementById('sidebar');
            sidebar.style.width = '350px';
            sidebar.style.height = '700px';

            if (controllers == null) {
                var geometry:three.js.BufferGeometry = new three.js.BufferGeometry();
                geometry.setAttribute('position', new three.js.Float32BufferAttribute([0, 0, 0, 0, 0, -5], 3));

                var line:three.js.Line = new three.js.Line(geometry);

                var raycaster:three.js.Raycaster = new three.js.Raycaster();

                function onSelect(event:Dynamic) {
                    var controller:Dynamic = event.target;

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

                    var intersects:Array<three.js.Intersection> = editor.selector.getIntersects(raycaster);

                    if (intersects.length > 0) {
                        // Ignore menu clicks
                        var intersect:three.js.Intersection = intersects[0];
                        if (intersect.object == group.children[0]) return;

                    }

                    editor.signals.intersectionsDetected.dispatch(intersects);
                }

                function onControllerEvent(event:Dynamic) {
                    var controller:Dynamic = event.target;

                    if (controller.userData.active == false) return;

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

                controllers = new three.js.Group();

                var controller1:three.js.XRController = renderer.xr.getController(0);
                controller1.addEventListener('select', onSelect);
                controller1.addEventListener('selectstart', onControllerEvent);
                controller1.addEventListener('selectend', onControllerEvent);
                controller1.addEventListener('move', onControllerEvent);
                controller1.userData.active = false;
                controllers.add(controller1);

                var controller2:three.js.XRController = renderer.xr.getController(1);
                controller2.addEventListener('select', onSelect);
                controller2.addEventListener('selectstart', onControllerEvent);
                controller2.addEventListener('selectend', onControllerEvent);
                controller2.addEventListener('move', onControllerEvent);
                controller2.userData.active = true;
                controllers.add(controller2);

                var controllerModelFactory:webxr.XRControllerModelFactory = new webxr.XRControllerModelFactory();

                var controllerGrip1:three.js.XRControllerGrip = renderer.xr.getControllerGrip(0);
                controllerGrip1.add(controllerModelFactory.createControllerModel(controllerGrip1));
                controllers.add(controllerGrip1);

                var controllerGrip2:three.js.XRControllerGrip = renderer.xr.getControllerGrip(1);
                controllerGrip2.add(controllerModelFactory.createControllerModel(controllerGrip2));
                controllers.add(controllerGrip2);

                group = new interactive.InteractiveGroup();

                var mesh:interactive.HTMLMesh = new interactive.HTMLMesh(sidebar);
                mesh.name = 'picker'; // Make Selector be aware of the menu
                mesh.position.set(0.5, 1.0, -0.5);
                mesh.rotation.y = -0.5;
                group.add(mesh);

                group.listenToXRControllerEvents(controller1);
                group.listenToXRControllerEvents(controller2);

            }

            editor.sceneHelpers.add(group);
            editor.sceneHelpers.add(controllers);

            renderer.xr.enabled = true;
            renderer.xr.addEventListener('sessionend', onSessionEnded);

            renderer.xr.setSession(session);
        };

        var onSessionEnded = function() {
            editor.sceneHelpers.remove(group);
            editor.sceneHelpers.remove(controllers);

            var sidebar:js.html.Element = js.Browser.document.getElementById('sidebar');
            sidebar.style.width = '';
            sidebar.style.height = '';

            renderer.xr.removeEventListener('sessionend', onSessionEnded);
            renderer.xr.enabled = false;

            editor.camera.copy(camera);

            editor.signals.windowResize.dispatch();
            editor.signals.leaveXR.dispatch();
        };

        editor.signals.enterXR.add(function(mode:Dynamic) {
            if (js.Browser.navigator.xr != null) {
                js.Browser.navigator.xr.requestSession(mode, { optionalFeatures: ['local-floor'] })
                    .then(onSessionStarted);
            }
        });

        editor.signals.offerXR.add(function(mode:Dynamic) {
            if (js.Browser.navigator.xr != null) {
                js.Browser.navigator.xr.offerSession(mode, { optionalFeatures: ['local-floor'] })
                    .then(onSessionStarted);

                editor.signals.leaveXR.add(function() {
                    js.Browser.navigator.xr.offerSession(mode, { optionalFeatures: ['local-floor'] })
                        .then(onSessionStarted);
                });
            }
        });

        editor.signals.rendererCreated.add(function(value:Dynamic) {
            renderer = value;
        });
    }
}