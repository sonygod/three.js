package three.js.test.e2e;

class DeterministicInjection {

    static function main() {
        // Deterministic random
        Math._random = Math.random;
        var seed:Float = Math.PI / 4;
        Math.random = function():Float {
            var x:Float = Math.sin(seed++) * 10000;
            return x - Math.floor(x);
        };

        // Deterministic timer
        untyped __js__("window.performance._now = performance.now");
        var frameId:Int = 0;
        var now:Void->Float = function():Float {
            return frameId * 16;
        };
        untyped __js__("window.Date.now = now");
        untyped __js__("window.Date.prototype.getTime = now");
        untyped __js__("window.performance.now = now");

        // Deterministic RAF
        var RAF:Dynamic = untyped __js__("window.requestAnimationFrame");
        untyped __js__("window._renderStarted = false");
        untyped __js__("window._renderFinished = false");

        var maxFrameId:Int = 2;
        untyped __js__("window.requestAnimationFrame = function(cb) {
            if (!window._renderStarted) {
                setTimeout(function() {
                    RAF(cb);
                }, 50);
            } else {
                RAF(function() {
                    if (frameId++ < maxFrameId) {
                        cb(now());
                    } else {
                        window._renderFinished = true;
                    }
                });
            }
        }");

        // Semi-deterministic video
        var play:Dynamic = untyped __js__("HTMLVideoElement.prototype.play");
        untyped __js__("HTMLVideoElement.prototype.play = async function() {
            play.call(this);
            this.addEventListener('timeupdate', function() {
                this.pause();
            });
            function renew() {
                this.load();
                play.call(this);
                RAF(renew);
            }
            RAF(renew);
        }");

        // Additional variable for ~5 examples
        untyped __js__("window.TESTING = true");
    }
}