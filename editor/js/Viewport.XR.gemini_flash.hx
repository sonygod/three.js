import three.Three;
import three.cameras.PerspectiveCamera;
import three.core.BufferGeometry;
import three.geometries.BufferAttribute.Float32BufferAttribute;
import three.objects.Line;
import three.materials.LineBasicMaterial;
import three.math.Raycaster;
import three.webxr.ControllerModelFactory;
import three.interactive.HTMLMesh;
import three.interactive.InteractiveGroup;

class XR {

	public function new(editor, controls) {

		var controllers:three.Group = null;
		var group:InteractiveGroup = null;
		var renderer:three.WebGLRenderer = null;

		var camera = new PerspectiveCamera();

		var onSessionStarted = function(session) {

			camera.copy(editor.camera);

			var sidebar = cast(js.Browser.document.getElementById("sidebar"), js.html.Element);
			sidebar.style.width = "350px";
			sidebar.style.height = "700px";

			//

			if (controllers == null) {

				var geometry = new BufferGeometry();
				geometry.setAttribute("position", new Float32BufferAttribute([0, 0, 0, 0, 0, -5], 3));

				var material = new LineBasicMaterial({ color: 0xff0000 });

				var line = new Line(geometry, material);

				var raycaster = new Raycaster();

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

						// Ignore menu clicks
						var intersect = intersects[0];
						if (intersect.object == group.children[0])
							return;

					}

					signals.intersectionsDetected.dispatch(intersects);

				}

				function onControllerEvent(event) {

					var controller = event.target;

					if (!controller.userData.active)
						return;

					controls.getRaycaster().setFromXRController(controller);

					switch (event.type) {

						case "selectstart":
							controls.pointerDown(null);
						case "selectend":
							controls.pointerUp(null);
						case "move":
							controls.pointerHover(null);
							controls.pointerMove(null);
						case _:
					}

				}

				controllers = new three.Group();

				var controller1 = renderer.xr.getController(0);
				controller1.addEventListener("select", onSelect);
				controller1.addEventListener("selectstart", onControllerEvent);
				controller1.addEventListener("selectend", onControllerEvent);
				controller1.addEventListener("move", onControllerEvent);
				controller1.userData.active = false;
				controllers.add(controller1);

				var controller2 = renderer.xr.getController(1);
				controller2.addEventListener("select", onSelect);
				controller2.addEventListener("selectstart", onControllerEvent);
				controller2.addEventListener("selectend", onControllerEvent);
				controller2.addEventListener("move", onControllerEvent);
				controller2.userData.active = true;
				controllers.add(controller2);

				//

				var controllerModelFactory = new ControllerModelFactory();

				var controllerGrip1 = renderer.xr.getControllerGrip(0);
				controllerGrip1.add(controllerModelFactory.createControllerModel(controllerGrip1));
				controllers.add(controllerGrip1);

				var controllerGrip2 = renderer.xr.getControllerGrip(1);
				controllerGrip2.add(controllerModelFactory.createControllerModel(controllerGrip2));
				controllers.add(controllerGrip2);

				// menu

				group = new InteractiveGroup(renderer, camera);

				var mesh = new HTMLMesh(cast(sidebar, js.html.Element));
				mesh.name = "picker"; // Make Selector be aware of the menu
				mesh.position.set(0.5, 1.0, -0.5);
				mesh.rotation.y = -0.5;
				group.add(mesh);

				//group.listenToXRControllerEvents(controller1);
				//group.listenToXRControllerEvents(controller2);

			}

			editor.sceneHelpers.add(group);
			editor.sceneHelpers.add(controllers);

			renderer.xr.enabled = true;
			renderer.xr.addEventListener("sessionend", onSessionEnded);

			renderer.xr.setSession(session);

		};

		var onSessionEnded = function() {

			editor.sceneHelpers.remove(group);
			editor.sceneHelpers.remove(controllers);

			var sidebar = cast(js.Browser.document.getElementById("sidebar"), js.html.Element);
			sidebar.style.width = "";
			sidebar.style.height = "";

			renderer.xr.removeEventListener("sessionend", onSessionEnded);
			renderer.xr.enabled = false;

			editor.camera.copy(camera);

			signals.windowResize.dispatch();
			signals.leaveXR.dispatch();

		};

		// signals

		var sessionInit = { optionalFeatures: ["local-floor"] };

		signals.enterXR.add(function(mode) {

			if (Reflect.hasField(js.Browser.navigator, "xr")) {

				js.Browser.navigator.xr.requestSession(mode, sessionInit).then(function(value) onSessionStarted(value));

			}

		});

		signals.offerXR.add(function(mode) {

			if (Reflect.hasField(js.Browser.navigator, "xr")) {

				js.Browser.navigator.xr.offerSession(mode, sessionInit).then(function(value) onSessionStarted(value));

				signals.leaveXR.add(function() {

					js.Browser.navigator.xr.offerSession(mode, sessionInit).then(function(value) onSessionStarted(value));

				});

			}

		});

		signals.rendererCreated.add(function(value) {

			renderer = value;

		});

	}

}