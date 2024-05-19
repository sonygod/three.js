import haxe.ds.StringMap;
import js.Js;
import js.html.Element;

class ThreeJsPrimitives {

	private static function darkColors(): StringMap<String> {
		return {
			lines: '#DDD',
		};
	}

	private static function lightColors(): StringMap<String> {
		return {
			lines: '#000',
		};
	}

	private static function getColors(): StringMap<String> {
		const isDarkMode = js.Browser.window.matchMedia('(prefers-color-scheme: dark)').matches;
		return isDarkMode ? darkColors() : lightColors();
	}

	private static function fontLoader(): dynamic {
		return new js.THREE.FontLoader(Js.instance);
	}

	private static function diagrams(): {[name: String]: {ui: {[param: String]: {type: String, min: Int, max: Int, precision: Int, mult: Float, bool: Bool};}; create: (...params: Array<Dynamic>) -> Dynamic;}} {
		return {
			// ... (other diagrams)
		};
	}

	private static function addLink(parent: Element, name: String, href: String): Element {
		// ... (the same as the JavaScript code)
	}

	private static function addDeepLink(parent: Element, name: String, href: String): Element {
		// ... (the same as the JavaScript code)
	}

	private static function addElem(parent: Element, type: String, className: String, text: String): Element {
		// ... (the same as the JavaScript code)
	}

	private static function addDiv(parent: Element, className: String): Element {
		// ... (the same as the JavaScript code)
	}

	private static function createPrimitiveDOM(base: Element): Void {
		// ... (the same as the JavaScript code)
	}

	private static function createDiagram(base: Element): Void {
		// ... (the same as the JavaScript code)
	}

	private static function makeExample(elem: Element, createFn: Dynamic, src: String): Void {
		// ... (the same as the JavaScript code)
	}

	private static function createLiveImage(elem: Element, info: {geometry: Dynamic, material: Dynamic, create: (...params: Array<Dynamic>) -> Dynamic}, name: String): Void {
		// ... (the same as the JavaScript code)
	}

	private static function getValueElem(commentElem: Element): Element {
		// ... (the same as the JavaScript code)
	}

	private static function threejsLessonUtils_onAfterPrettify(): Void {
		// ... (the same as the JavaScript code)
	}

	public static function main(): Void {
		threejsLessonUtils_onAfterPrettify();
	}
}