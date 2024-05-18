package three.js.examples.jm.renderers.common;

import js.html.AnimationFrameRequest;
import js.html.Window;

class Animation {
    public var nodes:Dynamic;
    public var info:Dynamic;
    public var animationLoop:Dynamic->Float->Void;
    public var requestId:AnimationFrameRequest;

    public function new(nodes:Dynamic, info:Dynamic) {
        this.nodes = nodes;
        this.info = info;
        this.animationLoop = null;
        this.requestId = null;
        _init();
    }

    private function _init():Void {
        var update = function(time:Float, frame:Dynamic):Void {
            requestId = js.Browser.window.requestAnimationFrame(update);
            if (info.autoReset) info.reset();
            nodes.nodeFrame.update();
            info.frame = nodes.nodeFrame.frameId;
            if (animationLoop != null) animationLoop(time, frame);
        };
        update(null, null);
    }

    public function dispose():Void {
        js.Browser.window.cancelAnimationFrame(requestId);
        requestId = null;
    }

    public function setAnimationLoop(callback:Dynamic->Float->Void):Void {
        animationLoop = callback;
    }
}