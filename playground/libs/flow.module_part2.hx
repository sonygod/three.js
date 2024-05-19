package three.js.playground.libs;

class PointerMonitor {
    
    public var x:Float = 0;
    public var y:Float = 0;
    public var started:Bool = false;

    private var _onMoveEvent:Dynamic->Void;

    public function new() {
        _onMoveEvent = function(e:Dynamic) {
            var event:Dynamic = e.touches != null ? e.touches[0] : e;
            x = event.clientX;
            y = event.clientY;
        };
    }

    public function start():PointerMonitor {
        if (started) return this;
        started = true;

        js.Browser.window.addEventListener('wheel', _onMoveEvent, true);
        js.Browser.window.addEventListener('mousedown', _onMoveEvent, true);
        js.Browser.window.addEventListener('touchstart', _onMoveEvent, true);
        js.Browser.window.addEventListener('mousemove', _onMoveEvent, true);
        js.Browser.window.addEventListener('touchmove', _onMoveEvent, true);
        js.Browser.window.addEventListener('dragover', _onMoveEvent, true);

        return this;
    }
}