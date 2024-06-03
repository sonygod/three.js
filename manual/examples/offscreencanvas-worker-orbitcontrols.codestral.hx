import three.EventDispatcher;
import three.manual.examples.shared_orbitcontrols.init;

class ElementProxyReceiver extends EventDispatcher {
    public var style = new haxe.ds.StringMap<Dynamic>();
    public var left: Float;
    public var top: Float;
    public var width: Float;
    public var height: Float;

    public function new() {
        super();
    }

    public function get_clientWidth(): Float {
        return this.width;
    }

    public function get_clientHeight(): Float {
        return this.height;
    }

    public function setPointerCapture() {}
    public function releasePointerCapture() {}

    public function getBoundingClientRect(): Dynamic {
        return {
            left: this.left,
            top: this.top,
            width: this.width,
            height: this.height,
            right: this.left + this.width,
            bottom: this.top + this.height
        };
    }

    public function handleEvent(data: Dynamic) {
        if (data.type == 'size') {
            this.left = data.left;
            this.top = data.top;
            this.width = data.width;
            this.height = data.height;
            return;
        }

        data.preventDefault = () -> {};
        data.stopPropagation = () -> {};
        this.dispatchEvent(data);
    }

    public function focus() {}
}

class ProxyManager {
    public var targets = new haxe.ds.StringMap<ElementProxyReceiver>();

    public function new() {
        this.handleEvent = this.handleEvent.bind(this);
    }

    public function makeProxy(data: Dynamic) {
        let id = data.id;
        let proxy = new ElementProxyReceiver();
        this.targets.set(id, proxy);
    }

    public function getProxy(id: String): ElementProxyReceiver {
        return this.targets.get(id);
    }

    public function handleEvent(data: Dynamic) {
        this.targets.get(data.id).handleEvent(data.data);
    }
}

var proxyManager = new ProxyManager();

function start(data: Dynamic) {
    let proxy = proxyManager.getProxy(data.canvasId);
    proxy.ownerDocument = proxy; // HACK!
    js.Browser.document = {}; // HACK!
    init({
        canvas: data.canvas,
        inputElement: proxy
    });
}

function makeProxy(data: Dynamic) {
    proxyManager.makeProxy(data);
}

var handlers = {
    "start": start,
    "makeProxy": makeProxy,
    "event": proxyManager.handleEvent
};

js.Browser.window.onmessage = function(e: MessageEvent) {
    let fn = Reflect.field(handlers, e.data.type);
    if (Std.is(fn, Function)) {
        cast fn(e.data);
    } else {
        throw new Error("no handler for type: " + e.data.type);
    }
};