class Deterministic {

	static function main() {

		// Deterministic random
		Math.random = Math._random;
		var seed:Float = Math.PI / 4;
		Math.random = function() {
			var x = Math.sin(seed++) * 10000;
			return x - Math.floor(x);
		};

		// Deterministic timer
		var frameId:Int = 0;
		var now = function() return frameId * 16;
		Date.now = now;
		Date.prototype.getTime = now;

		// Deterministic RAF
		var _renderStarted = false;
		var _renderFinished = false;
		var maxFrameId = 2;
		var RAF = js.Browser.window.requestAnimationFrame;
		js.Browser.window.requestAnimationFrame = function(cb) {
			if (!_renderStarted) {
				js.Browser.window.setTimeout(function() RAF(cb), 50);
			} else {
				RAF(function() {
					if (frameId++ < maxFrameId) {
						cb(now());
					} else {
						_renderFinished = true;
					}
				});
			}
		};

		// Semi-deterministic video
		var play = js.Browser.window.HTMLVideoElement.prototype.play;
		js.Browser.window.HTMLVideoElement.prototype.play = function() {
			play.call(this);
			this.addEventListener('timeupdate', function() this.pause());
			function renew() {
				this.load();
				play.call(this);
				RAF(renew);
			}
			RAF(renew);
		};

		// Additional variable for ~5 examples
		js.Browser.window.TESTING = true;
	}
}