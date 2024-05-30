import js.three.Addons.Interactive.HTMLMesh;
import js.three.Addons.Interactive.InteractiveGroup;
import js.three.Addons.WebXR.XRControllerModelFactory;
import js.three.Camera.PerspectiveCamera;
import js.three.Core.BufferAttribute;
import js.three.Core.BufferGeometry;
import js.three.Extras.Core.Raycaster;
import js.three.Extras.Objects.Line;

class XR {
    public function new(editor:Editor, controls:Controls) {
        var selector = editor.selector;
        var signals = editor.signals;

        var controllers:Dynamic = null;
        var group:InteractiveGroup = null;
        var renderer:Dynamic = null;

        var camera:PerspectiveCamera = cast PerspectiveCamera(editor.camera.clone());

        function onSessionStarted(session:Dynamic) {
            camera.copy(editor.camera);

            var sidebar = cast HtmlElement(document.getElementById('sidebar'));
            sidebar.style.width = '350px';
            sidebar.style.height = '700px';

            if (controllers == null) {
                var geometry:BufferGeometry = BufferGeometry.create();
                geometry.setAttribute('position', BufferAttribute.createFloat32(6, 3, [0, 0, 0, 0, 0, -5]));

                var line:Line = Line.create(geometry);

                var raycaster:Raycaster = Raycaster.create();

                function onSelect(event:Dynamic) -> Void {
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
                        if (intersect.object == group.children[0]) {
                            return;
                        }
                    }

                    signals.intersectionsDetected.dispatch(intersects);
                }

                function onControllerEvent(event:Dynamic) -> Void {
                    var controller = event.target;

                    if (controller.userData.active == false) {
                        return;
                    }

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

                controllers = js.three.Group_obj();

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

                var controllerModelFactory:XRControllerModelFactory = XRControllerModelFactory.create();

                var controllerGrip1 = renderer.xr.getControllerGrip(0);
                controllerGrip1.add(controllerModelFactory.createControllerModel(controllerGrip1));
                controllers.add(controllerGrip1);

                var controllerGrip2 = renderer.xr.getControllerGrip(1);
                controllerGrip2.add(controllerModelFactory.createControllerModel(controllerGrip2));
                controllers.add(controllerGrip2);

                group = InteractiveGroup.create();

                var mesh:HTMLMesh = HTMLMesh.create(sidebar);
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

            renderer.xr.setSession(session);
        }

        function onSessionEnded() {
            editor.sceneHelpers.remove(group);
            editor.sceneHelpers.remove(controllers);

            var sidebar = cast HtmlElement(document.getElementById('sidebar'));
            sidebar.style.width = '';
            sidebar.style.height = '';

            renderer.xr.removeEventListener('sessionend', onSessionEnded);
            renderer.xr.enabled = false;

            editor.camera.copy(camera);

            signals.windowResize.dispatch();
            signals.leaveXR.dispatch();
        }

        signals.enterXR.add(function(mode) {
            if (js.Browser.hasWindow('navigator')) {
                var navigator = cast Dynamic(js.Browser.window());
                if (Reflect.hasField(navigator, 'xr')) {
                    var xr = cast Dynamic(Reflect.field(navigator, 'xr'));
                    xr.requestSession(mode, sessionInit).then(onSessionStarted);
                }
            }
        });

        signals.offerXR.add(function(mode) {
            if (js.Browser.hasWindow('navigator')) {
                var navigator = cast Dynamic(js.Browser.window());
                if (Reflect.hasField(navigator, 'xr')) {
                    var xr = cast Dynamic(Reflect.field(navigator, 'xr'));
                    xr.offerSession(mode, sessionInit).then(onSessionStarted);

                    signals.leaveXR.add(function() {
                        xr.offerSession(mode, sessionInit).then(onSessionStarted);
                    });
                }
            }
        });

        signals.rendererCreated.add(function(value) {
            renderer = value;
        });
    }
}

class SessionInit {
    public var optionalFeatures:Array<String>;

    public function new(optionalFeatures:Array<String>) {
        this.optionalFeatures = optionalFeatures;
    }
}

var sessionInit:SessionInit = SessionInit.create(['local-floor']);