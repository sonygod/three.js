class Clock {
	var autoStart:Bool;
	var startTime:Float;
	var oldTime:Float;
	var elapsedTime:Float;
	var running:Bool;

	public function new(autoStart:Bool = true) {
		this.autoStart = autoStart;
		this.startTime = 0;
		this.oldTime = 0;
		this.elapsedTime = 0;
		this.running = false;
	}

	public function start():Void {
		this.startTime = now();
		this.oldTime = this.startTime;
		this.elapsedTime = 0;
		this.running = true;
	}

	public function stop():Void {
		this.getElapsedTime();
		this.running = false;
		this.autoStart = false;
	}

	public function getElapsedTime():Float {
		this.getDelta();
		return this.elapsedTime;
	}

	public function getDelta():Float {
		var diff:Float = 0;

		if (this.autoStart && !this.running) {
			this.start();
			return 0;
		}

		if (this.running) {
			var newTime = now();
			diff = (newTime - this.oldTime) / 1000;
			this.oldTime = newTime;
			this.elapsedTime += diff;
		}

		return diff;
	}
}

function now():Float {
	#if js
	return (typeof performance == "undefined" ? Date : performance).now();
	#end
}

class Export {
	public static var Clock:Clock;
}