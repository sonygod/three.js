import js.html.Document;
import js.html.Element;
import js.html.Window;
import js.html.Event;
import js.html.Node;
import js.Timer;

class Jank {
    var interval:Timer;
    var result:Element;

    public function new() {
        initJank();
    }

    public function initJank() {
        var button:Element = Document.getElementById('button');
        button.addEventListener(Event.CLICK, function(event:Event) {
            if (interval == null) {
                interval = Timer.delay(jank, 1000 / 60);
                button.textContent = 'STOP JANK';
            } else {
                interval.stop();
                interval = null;
                button.textContent = 'START JANK';
                result.textContent = '';
            }
        });
        result = Document.getElementById('result');
    }

    public function jank() {
        var number:Float = 0.0;
        for (i in 0...10000000) {
            number += Math.random();
        }
        result.textContent = number.toString();
    }

    static function main() {
        new Jank();
    }
}