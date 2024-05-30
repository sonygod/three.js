package three.js.test.e2e;

class DeterministicInjection {
    public function new() {
        // Deterministic random
        var originalRandom = Math.random;
        Math.random = function() {
            seed++;
            var x = Math.sin(seed) * 10000;
            return x - Math.floor(x);
        };
        var seed = Math.PI / 4;

        // Deterministic timer
        var originalNow = js.Browser.window.performance.now;
        var frameId = 0;
        js.Browser.window.performance.now = function() {
            return frameId * 16;
        };
        js.Browser.window.Date.now = function() {
            return frameId * 16;
        };
        js.Browser.Date.prototype.getTime = function() {
            return frameId * 16;
        };

        // Deterministic RAF
        var RAF = js.Browser.window.requestAnimationFrame;
        js.Browser.window._renderStarted = false;
        js.Browser.window._renderFinished = false;
        var maxFrameId = 2;
        js.Browser.window.requestAnimationFrame = function(cb) {
            if (!js.Browser.window._renderStarted) {
                haxe.Timer.delay(function() {
                    RAF(cb);
                }, 50);
            } else {
                RAF(function() {
                    if (frameId++ < maxFrameId) {
                        cb(js.Browser.window.performance.now());
                    } else {
                        js.Browser.window._renderFinished = true;
                    }
                });
            }
        };

        // Semi-deterministic video
        var originalPlay = js.Browser.HTMLVideoElement.prototype.play;
        js.Browser.HTMLVideoElement.prototype.play = function() {
            originalPlay.call(this);
            this.addEventListener("timeupdate", function() {
                this.pause();
            });
            function renew() {
                this.load();
                originalPlay.call(this);
                RAF(renew);
            }
            RAF(renew);
        };

        // Additional variable for ~5 examples
        js.Browser.window.TESTING = true;
    }
}