import js.Browser;

var interval:Null<js.html.Interval> = null;
var result:Null<Browser.HtmlElement> = null;

function initJank():Void {

	var button = Browser.document.getElementById( 'button' );
	button.addEventListener( 'click', function () {

		if ( interval == null ) {

			interval = Browser.setInterval( jank, 1000 / 60 );

			button.textContent = 'STOP JANK';

		} else {

			Browser.clearInterval( interval );
			interval = null;

			button.textContent = 'START JANK';
			result.textContent = '';

		}

	} );

	result = Browser.document.getElementById( 'result' );

}

function jank():Void {

	var number = 0;

	for ( i in 0...10000000 ) {

		number += Math.random();

	}

	result.textContent = number;

}

@:keep
class Main {
    static function main() {
        initJank();
    }
}