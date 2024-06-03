import three.core.Group;
import three.math.Vector2;
import three.raytracing.Raycaster;

class InteractiveGroup extends Group {

	static var _pointer:Vector2 = new Vector2();
	static var _event:Dynamic = { type: '', data: _pointer };
	static var _raycaster:Raycaster = new Raycaster();

	public function new() {
		super();
	}

	public function listenToPointerEvents(renderer:Dynamic, camera:Dynamic):Void {

		var scope = this;
		var raycaster = new Raycaster();
		var element = renderer.domElement;

		function onPointerEvent(event:Dynamic):Void {

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

	public function listenToXRControllerEvents(controller:Dynamic):Void {

		var scope = this;

		// TODO: Dispatch pointerevents too

		var events = {
			'move': 'mousemove',
			'select': 'click',
			'selectstart': 'mousedown',
			'selectend': 'mouseup'
		};

		function onXRControllerEvent(event:Dynamic):Void {

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