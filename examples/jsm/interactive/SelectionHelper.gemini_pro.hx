import three.Vector2;

class SelectionHelper {

	public var element: HtmlElement;
	public var renderer: dynamic;
	public var startPoint: Vector2;
	public var pointTopLeft: Vector2;
	public var pointBottomRight: Vector2;

	public var isDown: Bool = false;
	public var enabled: Bool = true;

	public function new(renderer: dynamic, cssClassName: String) {
		this.element = HtmlElement.create("div");
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

	private function onPointerDown(event: PointerEvent) {
		if (!this.enabled) return;

		this.isDown = true;
		this.onSelectStart(event);
	}

	private function onPointerMove(event: PointerEvent) {
		if (!this.enabled) return;

		if (this.isDown) {
			this.onSelectMove(event);
		}
	}

	private function onPointerUp(event: PointerEvent) {
		if (!this.enabled) return;

		this.isDown = false;
		this.onSelectOver();
	}

	public function onSelectStart(event: PointerEvent) {
		this.element.style.display = "none";
		this.renderer.domElement.parentElement.appendChild(this.element);

		this.element.style.left = event.clientX + "px";
		this.element.style.top = event.clientY + "px";
		this.element.style.width = "0px";
		this.element.style.height = "0px";

		this.startPoint.x = event.clientX;
		this.startPoint.y = event.clientY;
	}

	public function onSelectMove(event: PointerEvent) {
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


**Explanation:**

1. **Imports:** The `three.Vector2` is imported for working with 2D vectors.
2. **Constructor:**
    - Creates an `HtmlElement` of type `div`.
    - Adds the `cssClassName` to the element's class list.
    - Sets `pointerEvents` to `none`.
    - Initializes the `startPoint`, `pointTopLeft`, and `pointBottomRight` vectors.
    - Binds the `onPointerDown`, `onPointerMove`, and `onPointerUp` functions to the `this` context.
    - Attaches the event listeners to the `renderer.domElement`.
3. **Dispose:** Removes the event listeners from the `renderer.domElement`.
4. **Event Handlers:**
    - `onPointerDown`, `onPointerMove`, and `onPointerUp` are private functions that handle the corresponding events. They check if the `enabled` flag is true and perform the appropriate actions.
5. **Select Methods:**
    - `onSelectStart`, `onSelectMove`, and `onSelectOver` are public functions that define the behavior of the selection helper.
    - `onSelectStart` initializes the selection box.
    - `onSelectMove` updates the selection box based on mouse movement.
    - `onSelectOver` removes the selection box from the DOM.

**Key Differences:**

- **Event Handling:** Haxe uses `addEventListener` and `removeEventListener` for event handling, similar to JavaScript.
- **DOM Manipulation:** Haxe uses `HtmlElement.create` to create DOM elements and `parentElement.appendChild` and `parentElement.removeChild` to add and remove elements.
- **Event Objects:** Haxe's `PointerEvent` object has similar properties to JavaScript's `PointerEvent`.
- **Binding:** The `bind` method is used to bind event handlers to the `this` context.

**Usage:**


import three.WebGLRenderer;
import three.Scene;
import three.PerspectiveCamera;

class Main {

	static function main() {
		// Create renderer, scene, camera, etc.
		var renderer = new WebGLRenderer();
		var scene = new Scene();
		var camera = new PerspectiveCamera(75, 16 / 9, 0.1, 1000);

		// Create selection helper
		var selectionHelper = new SelectionHelper(renderer, "selection-helper");

		// ... render loop, etc.
	}

}