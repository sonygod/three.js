import js.Browser;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.Document;

class Jank {
    static var interval:Null<Int>;
    static var result:DivElement;
    static var button:ButtonElement;

    static function initJank() {
        button = cast Browser.document.getElementById('button');
        button.addEventListener('click', onClick);
        result = cast Browser.document.getElementById('result');
    }

    static function onClick(event) {
        if (interval == null) {
            interval = Browser.window.setInterval(jank, 1000 / 60);
            button.textContent = 'STOP JANK';
        } else {
            Browser.window.clearInterval(interval);
            interval = null;
            button.textContent = 'START JANK';
            result.textContent = '';
        }
    }

    static function jank() {
        var number:Float = 0.0;
        for (i in 0...10000000) {
            number += Math.random();
        }
        result.textContent = Std.string(number);
    }
}