import three.js.extras.core.Group;
import three.js.extras.core.Raycaster;
import three.js.extras.math.Vector2;

class InteractiveGroup extends Group {

	private static var _pointer:Vector2 = new Vector2();
	private static var _event:Dynamic = { type: '', data: _pointer };

	private static var _raycaster:Raycaster = new Raycaster();

	public function new() {
		super();
	}

	public function listenToPointerEvents(renderer:Dynamic, camera:Dynamic) {

		var scope = this;
		var raycaster = new Raycaster();

		var element = renderer.domElement;

		function onPointerEvent(event) {

			event.stopPropagation();

			var rect = renderer.domElement.getBoundingClientRect();

			_pointer.x = (event.clientX - rect.left) / rect.width * 2 - 1;
			_pointer.y = - (event.clientY - rect.top) / rect.height * 2 + 1;

			raycaster.setFromCamera(_pointer, camera);

			var intersects = raycaster.intersectObjects(scope.children, false);

			if (intersects.length > 0) {

				var intersection = intersects[0];

				var object = intersection.object;
				var uv = intersection.uv;

				_event.type = event.type;
				_event.data.set(uv.x, 1 - uv.y);

				object.dispatchEvent(_event);

			}

		}

		element.addEventListener('pointerdown', onPointerEvent);
		element.addEventListener('pointerup', onPointerEvent);
		element.addEventListener('pointermove', onPointerEvent);
		element.addEventListener('mousedown', onPointerEvent);
		element.addEventListener('mouseup', onPointerEvent);
		element.addEventListener('mousemove', onPointerEvent);
		element.addEventListener('click', onPointerEvent);

	}

	public function listenToXRControllerEvents(controller:Dynamic) {

		var scope = this;

		// TODO: Dispatch pointerevents too

		var events = {
			'move': 'mousemove',
			'select': 'click',
			'selectstart': 'mousedown',
			'selectend': 'mouseup'
		};

		function onXRControllerEvent(event) {

			var controller = event.target;

			_raycaster.setFromXRController(controller);

			var intersections = _raycaster.intersectObjects(scope.children, false);

			if (intersections.length > 0) {

				var intersection = intersections[0];

				var object = intersection.object;
				var uv = intersection.uv;

				_event.type = events[event.type];
				_event.data.set(uv.x, 1 - uv.y);

				object.dispatchEvent(_event);

			}

		}

		controller.addEventListener('move', onXRControllerEvent);
		controller.addEventListener('select', onXRControllerEvent);
		controller.addEventListener('selectstart', onXRControllerEvent);
		controller.addEventListener('selectend', onXRControllerEvent);

	}

}