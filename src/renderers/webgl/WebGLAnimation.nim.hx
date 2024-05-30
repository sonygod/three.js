import js.html.Window;

class WebGLAnimation {

	private var context:js.html.Window;
	private var isAnimating:Bool;
	private var animationLoop:Dynamic;
	private var requestId:Dynamic;

	public function new() {

		context = null;
		isAnimating = false;
		animationLoop = null;
		requestId = null;

		var onAnimationFrame = function( time, frame ) {

			animationLoop( time, frame );

			requestId = context.requestAnimationFrame( onAnimationFrame );

		}

	}

	public function start() {

		if ( isAnimating === true ) return;
		if ( animationLoop === null ) return;

		requestId = context.requestAnimationFrame( onAnimationFrame );

		isAnimating = true;

	}

	public function stop() {

		context.cancelAnimationFrame( requestId );

		isAnimating = false;

	}

	public function setAnimationLoop( callback:Dynamic ) {

		animationLoop = callback;

	}

	public function setContext( value:js.html.Window ) {

		context = value;

	}

}

export class Main {

	static function main() {

		var animation = new WebGLAnimation();

	}

}