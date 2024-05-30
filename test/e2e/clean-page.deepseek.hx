class CleanPage {
    static function main() {
        /* Remove start screen (or press some button ) */
        var button = js.Browser.document.getElementById('startButton');
        if (button != null) button.click();

        /* Remove gui and fonts */
        var style = js.Browser.document.createElement('style');
        style.type = 'text/css';
        style.innerHTML = '#info, button, input, body > div.lil-gui, body > div.lbl { display: none !important; }';

        js.Browser.document.querySelector('head').appendChild(style);

        /* Remove Stats.js */
        for (element in js.Browser.document.querySelectorAll('div')) {
            if (js.Browser.getComputedStyle(element).zIndex == '10000') {
                element.remove();
                break;
            }
        }
    }

    static function __hx_ctor_static_0() {
        CleanPage.main();
    }
}