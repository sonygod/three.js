import js.Browser.document;
import js.html.Element;

class CleanPage {

    public function new() {
        var button = document.getElementById('startButton');
        if (button != null) button.click();

        var style = document.createElement('style');
        style.type = 'text/css';
        style.innerHTML = '#info, button, input, body > div.lil-gui, body > div.lbl { display: none !important; }';

        document.querySelector('head').appendChild(style);

        var elements = document.querySelectorAll('div');
        for (element in elements) {
            if (js.Browser.getComputedStyle(element).zIndex == '10000') {
                element.remove();
                break;
            }
        }
    }
}

new CleanPage();