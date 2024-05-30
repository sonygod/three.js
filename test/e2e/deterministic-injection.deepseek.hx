class Main {
    static function main() {
        // Deterministic random
        js.Browser.window.Math._random = js.Browser.window.Math.random;
        var seed = Math.PI / 4;
        js.Browser.window.Math.random = function () {
            const x = Math.sin(seed++) * 10000;
            return x - Math.floor(x);
        };

        // Deterministic timer
        js.Browser.window.performance._now = js.Browser.window.performance.now;
        var frameId = 0;
        var now = function () return frameId * 16;
        js.Browser.window.Date.now = now;
        js.Browser.window.Date.prototype.getTime = now;
        js.Browser.window.performance.now = now;

        // Deterministic RAF
        var RAF = js.Browser.window.requestAnimationFrame;
        js.Browser.window._renderStarted = false;
        js.Browser.window._renderFinished = false;
        var maxFrameId = 2;
        js.Browser.window.requestAnimationFrame = function (cb) {
            if (!js.Browser.window._renderStarted) {
                js.Browser.window.setTimeout(function () {
                    js.Browser.window.requestAnimationFrame(cb);
                }, 50);
            } else {
                RAF(function () {
                    if (frameId++ < maxFrameId) {
                        cb(now());
                    } else {
                        js.Browser.window._renderFinished = true;
                    }
                });
            }
        };

        // Semi-deterministic video
        var play = js.Browser.HTMLVideoElement.prototype.play;
        js.Browser.HTMLVideoElement.prototype.play = function () {
            play.call(this);
            this.addEventListener('timeupdate', function () {
                this.pause();
            });
            var renew = function () {
                this.load();
                play.call(this);
                RAF(renew);
            }.bind(this);
            RAF(renew);
        };

        // Additional variable for ~5 examples
        js.Browser.window.TESTING = true;
    }
}