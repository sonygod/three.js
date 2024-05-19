package three.js.test.e2e;

import js.html.Document;
import js.html.Element;
import js.html.HeadingElement;
import js.html.StyleElement;
import js.html.NodeList;

class CleanPage {
    public function new() {
        // Remove start screen (or press some button )
        var button:Element = Document.getViewById('startButton');
        if (button != null) button.dispatchEvent(new js.html.MouseEvent('click'));

        // Remove gui and fonts
        var style:StyleElement = Document.createElement('style');
        style.type = 'text/css';
        style.innerHTML = '#info, button, input, body > div.lil-gui, body > div.lbl { display: none !important; }';
        Document.head.appendChild(style);

        // Remove Stats.js
        var elements:NodeList = Document.body.querySelectorAll('div');
        for (element in elements) {
            if (getComputedStyle(element).zIndex == '10000') {
                element.remove();
                break;
            }
        }
    }

    public static function main() {
        new CleanPage();
    }
}