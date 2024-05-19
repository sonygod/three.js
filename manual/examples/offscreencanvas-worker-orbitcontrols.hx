import js.three.EventDispatcher;

class ElementProxyReceiver extends EventDispatcher {
    public var style:Dynamic = {};
    private var width:Int;
    private var height:Int;
    private var left:Float;
    private var top:Float;

    public function new() {
        super();
    }

    public var clientWidth(get, never):Int;
    private function get_clientWidth():Int {
        return width;
    }

    public var clientHeight(get, never):Int;
    private function get_clientHeight():Int {
        return height;
    }

    public function setPointerCapture():Void {}
    public function releasePointerCapture():Void {}
    public function getBoundingClientRect():{left:Float,top:Float,width:Int,height:Int,right:Float,bottom:Float} {
        return {
            left: left,
            top: top,
            width: width,
            height: height,
            right: left + width,
            bottom: top + height,
        };
    }

    public function handleEvent(data:Dynamic):Void {
        if (data.type == 'size') {
            left = data.left;
            top = data.top;
            width = data.width;
            height = data.height;
            return;
        }
        data.preventDefault = function():Void {};
        data.stopPropagation = function():Void {};
        dispatchEvent(data);
    }

    public function focus():Void {}
}

class ProxyManager {
    private var targets:Map<String, ElementProxyReceiver>;

    public function new() {
        targets = new Map();
    }

    public function makeProxy(data:Dynamic):Void {
        var id:String = data.id;
        var proxy:ElementProxyReceiver = new ElementProxyReceiver();
        targets.set(id, proxy);
    }

    public function getProxy(id:String):ElementProxyReceiver {
        return targets.get(id);
    }

    public function handleEvent(data:Dynamic):Void {
        targets.get(data.id).handleEvent(data.data);
    }
}

var proxyManager:ProxyManager = new ProxyManager();

function start(data:Dynamic):Void {
    var proxy:ElementProxyReceiver = proxyManager.getProxy(data.canvasId);
    proxy.ownerDocument = proxy; // HACK!
    untyped __global.document = {}; // HACK!
    init({
        canvas: data.canvas,
        inputElement: proxy,
    });
}

function makeProxy(data:Dynamic):Void {
    proxyManager.makeProxy(data);
}

var handlers:Dynamic = {
    start: start,
    makeProxy: makeProxy,
    event: proxyManager.handleEvent,
};

untyped __global.onmessage = function(e:Dynamic):Void {
    var fn:Dynamic = handlers[e.data.type];
    if (fn == null || !Reflect.isFunction(fn)) {
        throw new Error('no handler for type: ' + e.data.type);
    }
    fn(e.data);
};