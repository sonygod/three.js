import js.Browser.document;
import js.Browser.window;
import js.html.Element;

class Resizer extends UIElement { // Assuming UIElement is defined and handles Element wrapping

	public function new(editor:Dynamic) { // Using Dynamic for editor due to lack of type info
		super(document.createElement("div"));

		this.element.id = "resizer";

		this.element.addEventListener("pointerdown", onPointerDown);

		// Assuming editor.signals.windowResize is a Signal-like object
		editor.signals.windowResize.add(onWindowResize);
	}

	private function onPointerDown(event:PointerEvent):Void {
		if (!event.isPrimary) return;

		document.addEventListener("pointermove", onPointerMove);
		document.addEventListener("pointerup", onPointerUp);
	}

	private function onPointerUp(event:PointerEvent):Void {
		if (!event.isPrimary) return;

		document.removeEventListener("pointermove", onPointerMove);
		document.removeEventListener("pointerup", onPointerUp);
	}

	private function onPointerMove(event:PointerEvent):Void {
		if (!event.isPrimary) return;

		var offsetWidth = document.body.offsetWidth;
		var clientX = event.clientX;

		var cX = clientX < 0 ? 0 : clientX > offsetWidth ? offsetWidth : clientX;

		var x = Math.max(335, offsetWidth - cX);

		this.element.style.right = x + "px";

		cast(document.getElementById("sidebar"), Element).style.width = x + "px";
		cast(document.getElementById("player"), Element).style.right = x + "px";
		cast(document.getElementById("script"), Element).style.right = x + "px";
		cast(document.getElementById("viewport"), Element).style.right = x + "px";
	}

	private function onWindowResize():Void {
		// Implement logic from signals.windowResize.dispatch()
	}
}