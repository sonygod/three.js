import qunit.QUnit;
import three.core.Clock;

class ClockTest extends qunit.QUnit {

	static function main() {
		new ClockTest().run();
	}

	override function run() {
		super.run();
		module("Core", function() {
			module("Clock", function() {
				function mockPerformance() {
					js.Browser.window.performance = {
						deltaTime: 0,
						next: function(delta:Float) {
							this.deltaTime += delta;
						},
						now: function():Float {
							return this.deltaTime;
						}
					};
				}

				// INSTANCING
				test("Instancing", function(assert:qunit.Assert) {
					// no params
					var object = new Clock();
					assert.ok(object, "Can instantiate a Clock.");
					// autostart
					var object_all = new Clock(false);
					assert.ok(object_all, "Can instantiate a Clock with autostart.");
				});

				// PROPERTIES
				todo("autoStart", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});
				todo("startTime", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});
				todo("oldTime", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});
				todo("elapsedTime", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});
				todo("running", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				// PUBLIC
				todo("start", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});
				todo("stop", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});
				todo("getElapsedTime", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});
				todo("getDelta", function(assert:qunit.Assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				// OTHERS
				test("clock with performance", function(assert:qunit.Assert) {
					if (js.Browser.window.performance == null) {
						assert.expect(0);
						return;
					}
					mockPerformance();
					var clock = new Clock(false);
					clock.start();
					js.Browser.window.performance.next(123);
					assert.numEqual(clock.getElapsedTime(), 0.123, "okay");
					js.Browser.window.performance.next(100);
					assert.numEqual(clock.getElapsedTime(), 0.223, "okay");
					clock.stop();
					js.Browser.window.performance.next(1000);
					assert.numEqual(clock.getElapsedTime(), 0.223, "don't update time if the clock was stopped");
				});
			});
		});
	}
}

class qunit.Assert {
	public function ok(v:Bool, msg:String) : Void {
		js.Browser.window.console.log(msg);
	}

	public function numEqual(a:Float, b:Float, msg:String) : Void {
		js.Browser.window.console.log(msg);
	}

	public function expect(v:Int) : Void {
		js.Browser.window.console.log(v);
	}
}

class qunit.QUnit {
	public function run() : Void {
		js.Browser.window.console.log("QUnit run");
	}

	public function module(name:String, callback:Dynamic->Void) : Void {
		js.Browser.window.console.log("QUnit module");
		callback(null);
	}

	public function test(name:String, callback:qunit.Assert->Void) : Void {
		js.Browser.window.console.log("QUnit test");
		callback(null);
	}

	public function todo(name:String, callback:qunit.Assert->Void) : Void {
		js.Browser.window.console.log("QUnit todo");
		callback(null);
	}
}

class Dynamic {
}