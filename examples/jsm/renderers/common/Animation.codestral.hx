class Animation {

    public var nodes:Dynamic;
    public var info:Dynamic;
    public var animationLoop:Dynamic;
    public var requestId:Int;

    public function new(nodes:Dynamic, info:Dynamic) {
        this.nodes = nodes;
        this.info = info;
        this.animationLoop = null;
        this.requestId = null;
        this._init();
    }

    private function _init() {
        var update = function(time:Float, frame:Int) {
            this.requestId = js.Browser.window.requestAnimationFrame(update);
            if (this.info.autoReset) this.info.reset();
            this.nodes.nodeFrame.update();
            this.info.frame = this.nodes.nodeFrame.frameId;
            if (this.animationLoop != null) this.animationLoop(time, frame);
        };
        update(0, 0); // Initial call with dummy values
    }

    public function dispose() {
        js.Browser.window.cancelAnimationFrame(this.requestId);
        this.requestId = null;
    }

    public function setAnimationLoop(callback:Dynamic) {
        this.animationLoop = callback;
    }
}