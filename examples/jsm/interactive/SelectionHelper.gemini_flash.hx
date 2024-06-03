import three.Vector2;
import js.html.Element;
import js.html.Window;
import js.html.MouseEvent;

class SelectionHelper {

	public var element:Element;
	public var renderer:Dynamic;
	public var startPoint:Vector2;
	public var pointTopLeft:Vector2;
	public var pointBottomRight:Vector2;
	public var isDown:Bool = false;
	public var enabled:Bool = true;

	public function new(renderer:Dynamic, cssClassName:String) {
		this.element = new Element("div");
		this.element.classList.add(cssClassName);
		this.element.style.pointerEvents = "none";
		this.renderer = renderer;
		this.startPoint = new Vector2();
		this.pointTopLeft = new Vector2();
		this.pointBottomRight = new Vector2();

		this.onPointerDown = this.onPointerDown.bind(this);
		this.onPointerMove = this.onPointerMove.bind(this);
		this.onPointerUp = this.onPointerUp.bind(this);

		this.renderer.domElement.addEventListener("pointerdown", this.onPointerDown);
		this.renderer.domElement.addEventListener("pointermove", this.onPointerMove);
		this.renderer.domElement.addEventListener("pointerup", this.onPointerUp);
	}

	public function dispose() {
		this.renderer.domElement.removeEventListener("pointerdown", this.onPointerDown);
		this.renderer.domElement.removeEventListener("pointermove", this.onPointerMove);
		this.renderer.domElement.removeEventListener("pointerup", this.onPointerUp);
	}

	private function onPointerDown(event:MouseEvent) {
		if (!this.enabled) return;

		this.isDown = true;
		this.onSelectStart(event);
	}

	private function onPointerMove(event:MouseEvent) {
		if (!this.enabled) return;

		if (this.isDown) {
			this.onSelectMove(event);
		}
	}

	private function onPointerUp() {
		if (!this.enabled) return;

		this.isDown = false;
		this.onSelectOver();
	}

	public function onSelectStart(event:MouseEvent) {
		this.element.style.display = "none";
		this.renderer.domElement.parentElement.appendChild(this.element);
		this.element.style.left = event.clientX + "px";
		this.element.style.top = event.clientY + "px";
		this.element.style.width = "0px";
		this.element.style.height = "0px";

		this.startPoint.x = event.clientX;
		this.startPoint.y = event.clientY;
	}

	public function onSelectMove(event:MouseEvent) {
		this.element.style.display = "block";

		this.pointBottomRight.x = Math.max(this.startPoint.x, event.clientX);
		this.pointBottomRight.y = Math.max(this.startPoint.y, event.clientY);
		this.pointTopLeft.x = Math.min(this.startPoint.x, event.clientX);
		this.pointTopLeft.y = Math.min(this.startPoint.y, event.clientY);

		this.element.style.left = this.pointTopLeft.x + "px";
		this.element.style.top = this.pointTopLeft.y + "px";
		this.element.style.width = (this.pointBottomRight.x - this.pointTopLeft.x) + "px";
		this.element.style.height = (this.pointBottomRight.y - this.pointTopLeft.y) + "px";
	}

	public function onSelectOver() {
		this.element.parentElement.removeChild(this.element);
	}

}