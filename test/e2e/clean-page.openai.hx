package three.js.test.e2e;

import js.html.Element;
import js.html.StyleElement;
import js.html.Document;
import js.html.HeadElement;

class CleanPage {
  static function main() {
    // Remove start screen (or press some button )
    var button:Element = Document.getElementById('startButton');
    if (button != null) {
      button.dispatchEvent(new js.html.MouseEvent('click'));
    }

    // Remove gui and fonts
    var style:StyleElement = Document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = '#info, button, input, body > div.lil-gui, body > div.lbl { display: none !important; }';

    var head:HeadElement = Document.head;
    head.appendChild(style);

    // Remove Stats.js
    var elements:Array<Element> = Document.querySelectorAll('div');
    for (element in elements) {
      if (getComputedStyle(element).zIndex == '10000') {
        element.remove();
        break;
      }
    }
  }
}