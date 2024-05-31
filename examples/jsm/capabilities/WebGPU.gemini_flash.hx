import js.Browser;
import js.html.DivElement;

class WebGPU {

	static isAvailable:Bool = false;
	static adapter:Null<gpu.GPUAdapter> = null;

	static function main():Void {
		if (Browser.navigator.gpu != null) {
			Browser.navigator.gpu.requestAdapter().then(function(a) {
				adapter = a;
				isAvailable = true;
			});
		}
	}

	public static function isAvailable():Bool {
		return isAvailable;
	}

	public static function getStaticAdapter():Null<gpu.GPUAdapter> {
		return adapter;
	}

	public static function getErrorMessage():DivElement {
		var message = 'Your browser does not support <a href="https://gpuweb.github.io/gpuweb/" style="color:blue">WebGPU</a> yet';
		var element = Browser.document.createDivElement();
		element.id = 'webgpumessage';
		element.style.fontFamily = 'monospace';
		element.style.fontSize = '13px';
		element.style.fontWeight = 'normal';
		element.style.textAlign = 'center';
		element.style.background = '#fff';
		element.style.color = '#000';
		element.style.padding = '1.5em';
		element.style.maxWidth = '400px';
		element.style.margin = '5em auto 0';
		element.innerHTML = message;
		return element;
	}

}

enum abstract GPUShaderStage(Int) {
	var VERTEX = 1;
	var FRAGMENT = 2;
	var COMPUTE = 4;
}