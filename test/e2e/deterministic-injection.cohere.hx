import js.Browser.Window;
import js.html.HTMLVideoElement;

class MathOverride {
    static var _randomSeed = Math.PI / 4;

    static function random() {
        _randomSeed += 1;
        var x = Math.sin(_randomSeed) * 10000;
        return x - Math.floor(x);
    }
}

class TimerOverride {
    static var _frameId = 0;

    static function now() {
        return _frameId * 16;
    }
}

class RequestAnimationFrameOverride {
    static var _renderStarted = false;
    static var _renderFinished = false;
    static var _maxFrameId = 2;

    static function requestAnimationFrame(cb:Void->Void) {
        if (!_renderStarted) {
            js.Browser.window.setTimeout(function() {
                RequestAnimationFrameOverride.requestAnimationFrame(cb);
            }, 50);
        } else {
            js.Browser.window.requestAnimationFrame(function() {
                if (_frameId < _maxFrameId) {
                    cb(TimerOverride.now());
                } else {
                    _renderFinished = true;
                }
                _frameId += 1;
            });
        }
    }
}

class VideoOverride {
    static function playAsync(video:HTMLVideoElement) {
        video.play();
        video.addEventListener('timeupdate', function() {
            video.pause();
        });

        function renew() {
            video.load();
            video.play();
            js.Browser.window.requestAnimationFrame(renew);
        }

        js.Browser.window.requestAnimationFrame(renew);
    }
}

class Testing {
    static var TESTING = true;
}

class Main {
    static function main() {
        js.Browser.window.Math.random = MathOverride.random;
        js.Browser.window.Date.now = TimerOverride.now;
        js.Browser.window.Date.prototype.getTime = TimerOverride.now;
        js.Browser.window.performance.now = TimerOverride.now;
        js.Browser.window.requestAnimationFrame = RequestAnimationFrameOverride.requestAnimationFrame;
        HTMLVideoElement.prototype.play = function() {
            VideoOverride.playAsync(this);
        };
        js.Browser.window.TESTING = Testing.TESTING;
    }
}

Main.main();