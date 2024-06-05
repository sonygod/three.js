import three.core.Group;
import three.math.Vector2;
import three.raycaster.Raycaster;

class InteractiveGroup extends Group {

	private static _pointer:Vector2 = new Vector2();
	private static _event:Dynamic = { type: '', data: InteractiveGroup._pointer };
	private static _raycaster:Raycaster = new Raycaster();

	public function listenToPointerEvents(renderer:Dynamic, camera:Dynamic):Void {
		final scope = this;
		final raycaster:Raycaster = new Raycaster();

		final element = renderer.domElement;

		function onPointerEvent(event:Dynamic):Void {

			event.stopPropagation();

			final rect = renderer.domElement.getBoundingClientRect();

			InteractiveGroup._pointer.x = (event.clientX - rect.left) / rect.width * 2 - 1;
			InteractiveGroup._pointer.y = - (event.clientY - rect.top) / rect.height * 2 + 1;

			raycaster.setFromCamera(InteractiveGroup._pointer, camera);

			final intersects = raycaster.intersectObjects(scope.children, false);

			if (intersects.length > 0) {

				final intersection = intersects[0];

				final object = intersection.object;
				final uv = intersection.uv;

				InteractiveGroup._event.type = event.type;
				InteractiveGroup._event.data.set(uv.x, 1 - uv.y);

				object.dispatchEvent(InteractiveGroup._event);

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
		final scope = this;

		// TODO: Dispatch pointerevents too

		final events:Dynamic = {
			'move': 'mousemove',
			'select': 'click',
			'selectstart': 'mousedown',
			'selectend': 'mouseup'
		};

		function onXRControllerEvent(event:Dynamic):Void {

			final controller = event.target;

			InteractiveGroup._raycaster.setFromXRController(controller);

			final intersections = InteractiveGroup._raycaster.intersectObjects(scope.children, false);

			if (intersections.length > 0) {

				final intersection = intersections[0];

				final object = intersection.object;
				final uv = intersection.uv;

				InteractiveGroup._event.type = events[event.type];
				InteractiveGroup._event.data.set(uv.x, 1 - uv.y);

				object.dispatchEvent(InteractiveGroup._event);

			}

		}

		controller.addEventListener('move', onXRControllerEvent);
		controller.addEventListener('select', onXRControllerEvent);
		controller.addEventListener('selectstart', onXRControllerEvent);
		controller.addEventListener('selectend', onXRControllerEvent);
	}

}