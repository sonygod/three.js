import js.Browser.document;
import js.Browser.window;
import js.html.HtmlElement;

var interval:Int = null;
var result:HtmlElement = null;

function initJank() {
	var button:HtmlElement = document.getElementById('button');
	button.addEventListener('click', function(_) {
		if (interval == null) {
			interval = window.setInterval(jank, 1000 / 60);
			button.textContent = 'STOP JANK';
		} else {
			window.clearInterval(interval);
			interval = null;
			button.textContent = 'START JANK';
			result.textContent = '';
		}
	});
	result = document.getElementById('result');
}

function jank() {
	var number:Float = 0;
	for (var i:Int = 0; i < 10000000; i++) {
		number += Math.random();
	}
	result.textContent = number.toString();
}

class Main {
	public static function main() {
		initJank();
	}
}