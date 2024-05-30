import three.THREE;
import three.addons.interactive.HTMLMesh;
import three.addons.interactive.InteractiveGroup;
import three.addons.webxr.XRControllerModelFactory;

class XR {

    public function new(editor:Dynamic, controls:Dynamic) {

        var selector = editor.selector;
        var signals = editor.signals;

        var controllers:Null<Dynamic> = null;
        var group:Null<Dynamic> = null;
        var renderer:Null<Dynamic> = null;

        var camera = new THREE.PerspectiveCamera();

        var onSessionStarted = function(session) {

            camera.copy(editor.camera);

            var sidebar = js.Browser.document.getElementById('sidebar');
            sidebar.style.width = '350px';
            sidebar.style.height = '700px';

            if (controllers == null) {

                var geometry = new THREE.BufferGeometry();
                geometry.setAttribute('position', new THREE.Float32BufferAttribute([0, 0, 0, 0, 0, -5], 3));

                var line = new THREE.Line(geometry);

                var raycaster = new THREE.Raycaster();

                function onSelect(event) {

                    var controller = event.target;

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

                    var intersects = selector.getIntersects(raycaster);

                    if (intersects.length > 0) {

                        var intersect = intersects[0];
                        if (intersect.object == group.children[0]) return;

                    }

                    signals.intersectionsDetected.dispatch(intersects);

                }

                function onControllerEvent(event) {

                    var controller = event.target;

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

                controllers = new THREE.Group();

                var controller1 = renderer.xr.getController(0);
                controller1.addEventListener('select', onSelect);
                controller1.addEventListener('selectstart', onControllerEvent);
                controller1.addEventListener('selectend', onControllerEvent);
                controller1.addEventListener('move', onControllerEvent);
                controller1.userData.active = false;
                controllers.add(controller1);

                var controller2 = renderer.xr.getController(1);
                controller2.addEventListener('select', onSelect);
                controller2.addEventListener('selectstart', onControllerEvent);
                controller2.addEventListener('selectend', onControllerEvent);
                controller2.addEventListener('move', onControllerEvent);
                controller2.userData.active = true;
                controllers.add(controller2);

                var controllerModelFactory = new XRControllerModelFactory();

                var controllerGrip1 = renderer.xr.getControllerGrip(0);
                controllerGrip1.add(controllerModelFactory.createControllerModel(controllerGrip1));
                controllers.add(controllerGrip1);

                var controllerGrip2 = renderer.xr.getControllerGrip(1);
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

            }

            editor.sceneHelpers.add(group);
            editor.sceneHelpers.add(controllers);

            renderer.xr.enabled = true;
            renderer.xr.addEventListener('sessionend', onSessionEnded);

            js.Promise.resolve(renderer.xr.setSession(session));

        };

        var onSessionEnded = function() {

            editor.sceneHelpers.remove(group);
            editor.sceneHelpers.remove(controllers);

            var sidebar = js.Browser.document.getElementById('sidebar');
            sidebar.style.width = '';
            sidebar.style.height = '';

            renderer.xr.removeEventListener('sessionend', onSessionEnded);
            renderer.xr.enabled = false;

            editor.camera.copy(camera);

            signals.windowResize.dispatch();
            signals.leaveXR.dispatch();

        };

        signals.enterXR.add(function(mode) {

            if ('xr' in js.Browser.navigator) {

                js.Browser.navigator.xr.requestSession(mode, {optionalFeatures: ['local-floor']})
                    .then(onSessionStarted);

            }

        });

        signals.offerXR.add(function(mode) {

            if ('xr' in js.Browser.navigator) {

                js.Browser.navigator.xr.offerSession(mode, {optionalFeatures: ['local-floor']})
                    .then(onSessionStarted);

                signals.leaveXR.add(function() {

                    js.Browser.navigator.xr.offerSession(mode, {optionalFeatures: ['local-floor']})
                        .then(onSessionStarted);

                });

            }

        });

        signals.rendererCreated.add(function(value) {

            renderer = value;

        });

    }

}