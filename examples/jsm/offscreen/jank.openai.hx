import js.html.DOMElement;
import js.html.Document;
import js.Browser;

class Jank {
  static var interval:Null<js.timers.Interval>;
  static var result:DOMElement;

  public static function initJank() {
    var button:DOMElement = Browser.document.getElementById('button');
    button.addEventListener('click', function(_) {
      if (interval == null) {
        interval = js.timers.setInterval(jank, 1000 / 60);
        button.textContent = 'STOP JANK';
      } else {
        js.timers.clearInterval(interval);
        interval = null;
        button.textContent = 'START JANK';
        result.textContent = '';
      }
    });
    result = Browser.document.getElementById('result');
  }

  static function jank() {
    var number:Float = 0.0;
    for (i in 0...10000000) {
      number += Math.random();
    }
    result.textContent = Std.string(number);
  }
}