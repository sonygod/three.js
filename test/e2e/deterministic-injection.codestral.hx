import js.Browser.window;

class DeterministicInjection {
    public function new() {
        // Deterministic random
        define("window.Math._random", window.Math.random);
        var seed = Math.PI / 4;
        window.Math.random = () -> {
            var x = Math.sin(seed++) * 10000;
            return x - Math.floor(x);
        };

        // Deterministic timer
        define("window.performance._now", window.performance.now);
        var frameId = 0;
        var now = () -> frameId * 16;
        window.Date.now = now;
        window.Date.prototype.getTime = now;
        window.performance.now = now;

        // Deterministic RAF
        var RAF = window.requestAnimationFrame;
        define("window._renderStarted", false);
        define("window._renderFinished", false);
        var maxFrameId = 2;
        window.requestAnimationFrame = (cb : Dynamic) -> {
            if (!window._renderStarted) {
                js.Browser.window.setTimeout(() -> {
                    RAF(cb);
                }, 50);
            } else {
                RAF(() -> {
                    if (frameId++ < maxFrameId) {
                        cb(now());
                    } else {
                        window._renderFinished = true;
                    }
                });
            }
        };

        // Semi-determitistic video
        var play = js.Browser.document.createElement("video").play;
        js.Browser.document.createElement("video").play = async function() {
            this.play();
            this.addEventListener("timeupdate", () -> this.pause());
            var renew = () => {
                this.load();
                this.play();
                RAF(renew);
            };
            RAF(renew);
        };

        // Additional variable for ~5 examples
        define("window.TESTING", true);
    }
}

new DeterministicInjection();