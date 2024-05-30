import js.Browser.document;
import three.Vector2;

class SelectionHelper {

	var element:js.html.Element;
	var renderer:Dynamic;
	var startPoint:Vector2;
	var pointTopLeft:Vector2;
	var pointBottomRight:Vector2;
	var isDown:Bool;
	var enabled:Bool;
	var onPointerDown:js.html.Event->Void;
	var onPointerMove:js.html.Event->Void;
	var onPointerUp:js.html.Event->Void;

	public function new(renderer:Dynamic, cssClassName:String) {
		element = document.createElement('div');
		element.classList.add(cssClassName);
		element.style.pointerEvents = 'none';

		this.renderer = renderer;

		startPoint = new Vector2();
		pointTopLeft = new Vector2();
		pointBottomRight = new Vector2();

		isDown = false;
		enabled = true;

		onPointerDown = function(event:js.html.Event) {
			if (enabled == false) return;
			isDown = true;
			onSelectStart(event);
		};

		onPointerMove = function(event:js.html.Event) {
			if (enabled == false) return;
			if (isDown) {
				onSelectMove(event);
			}
		};

		onPointerUp = function() {
			if (enabled == false) return;
			isDown = false;
			onSelectOver();
		};

		renderer.domElement.addEventListener('pointerdown', onPointerDown);
		renderer.domElement.addEventListener('pointermove', onPointerMove);
		renderer.domElement.addEventListener('pointerup', onPointerUp);
	}

	public function dispose() {
		renderer.domElement.removeEventListener('pointerdown', onPointerDown);
		renderer.domElement.removeEventListener('pointermove', onPointerMove);
		renderer.domElement.removeEventListener('pointerup', onPointerUp);
	}

	public function onSelectStart(event:js.html.Event) {
		element.style.display = 'none';
		renderer.domElement.parentElement.appendChild(element);
		element.style.left = event.clientX + 'px';
		element.style.top = event.clientY + 'px';
		element.style.width = '0px';
		element.style.height = '0px';
		startPoint.x = event.clientX;
		startPoint.y = event.clientY;
	}

	public function onSelectMove(event:js.html.Event) {
		element.style.display = 'block';
		pointBottomRight.x = Math.max(startPoint.x, event.clientX);
		pointBottomRight.y = Math.max(startPoint.y, event.clientY);
		pointTopLeft.x = Math.min(startPoint.x, event.clientX);
		pointTopLeft.y = Math.min(startPoint.y, event.clientY);
		element.style.left = pointTopLeft.x + 'px';
		element.style.top = pointTopLeft.y + 'px';
		element.style.width = (pointBottomRight.x - pointTopLeft.x) + 'px';
		element.style.height = (pointBottomRight.y - pointTopLeft.y) + 'px';
	}

	public function onSelectOver() {
		element.parentElement.removeChild(element);
	}
}