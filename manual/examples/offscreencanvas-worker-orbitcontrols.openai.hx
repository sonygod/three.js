package three.js.manual.examples;

import js.html.Element;
import js.html.Document;
import three.module.Three;

class ElementProxyReceiver extends three.event.EventDispatcher {
    public var style:Dynamic = {};
    public var clientWidth(get, never):Int;
    public var clientHeight(get, never):Int;

    public function new() {
        super();
    }

    private function get_clientWidth():Int {
        return width;
    }

    private function get_clientHeight():Int {
        return height;
    }

    public function setPointerCapture():Void {}
    public function releasePointerCapture():Void {}
    public function getBoundingClientRect():{ left:Int, top:Int, width:Int, height:Int, right:Int, bottom:Int } {
        return { left: left, top: top, width: width, height: height, right: left + width, bottom: top + height };
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
    public var targets:Map<String, ElementProxyReceiver> = new Map();
    public function new() {
        handleEvent = handleEvent.bind(this);
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
    self.document = {}; // HACK!
    init({ canvas: data.canvas, inputElement: proxy });
}

function makeProxy(data:Dynamic):Void {
    proxyManager.makeProxy(data);
}

var handlers:Dynamic = {
    start: start,
    makeProxy: makeProxy,
    event: proxyManager.handleEvent
};

self.onmessage = function(e:Dynamic):Void {
    var fn:Dynamic = handlers[e.data.type];
    if (Reflect.isFunction(fn)) {
        fn(e.data);
    } else {
        throw new Error('no handler for type: ' + e.data.type);
    }
};