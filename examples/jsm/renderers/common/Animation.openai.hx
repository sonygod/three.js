package three.js.examples.jsm.renderers.common;

import js.htmlAnimationFrame;
import js.html.Window;

class Animation {
    public var nodes:Array<Dynamic>;
    public var info:Dynamic;
    public var animationLoop:Dynamic->Float->Void;
    public var requestId:Float;

    public function new(nodes:Array<Dynamic>, info:Dynamic) {
        this.nodes = nodes;
        this.info = info;
        requestId = 0;
        animationLoop = null;
        _init();
    }

    private function _init():Void {
        var update:Void->Void = function() {
            requestId = js.Browser.window.requestAnimationFrame(update);
            if (info.autoReset) info.reset();
            nodes.nodeFrame.update();
            info.frame = nodes.nodeFrame.frameId;
            if (animationLoop != null) animationLoop(0, 0); // assuming time and frame are not used
        };
        update();
    }

    public function dispose():Void {
        js.Browser.window.cancelAnimationFrame(requestId);
        requestId = 0;
    }

    public function setAnimationLoop(callback:Dynamic->Float->Void):Void {
        animationLoop = callback;
    }
}