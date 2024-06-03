import js.Browser;
import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.Window;

class Split {
    private var window: Window = js.Browser.window;
    private var document: Document = js.Browser.document;
    private var addEventListener: String = "addEventListener";
    private var removeEventListener: String = "removeEventListener";
    private var getBoundingClientRect: String = "getBoundingClientRect";
    private var preventDefault: Dynamic = function(e: Event) { e.preventDefault(); };
    private var isTouchDevice: Bool = js.Browser.hasEvent("touchstart");
    private var calcPrefix: String;
    private var elements: Array<SplitElement>;
    private var gutters: Array<SplitGutter>;
    private var options: SplitOptions;

    public function new(elements: Array<Element>, options: SplitOptions) {
        this.options = options;
        this.elements = elements.map(function(element) {
            return new SplitElement(element, options);
        });
        this.gutters = [];
        this.calcPrefix = getCalcPrefix();

        for (i in 0...elements.length) {
            if (i > 0) {
                var gutter = new SplitGutter(i - 1, i, options);
                this.gutters.push(gutter);
            }
        }
    }

    private function getCalcPrefix(): String {
        var prefixes = ["", "-webkit-", "-moz-", "-o-"];
        for (prefix in prefixes) {
            var div = document.createElement("div");
            div.style.cssText = "width:" + prefix + "calc(9px)";
            if (div.style.length > 0) {
                return prefix + "calc";
            }
        }
        return "";
    }

    public function setSizes(sizes: Array<Float>) {
        for (i in 1...sizes.length) {
            var gutter = this.gutters[i - 1];
            var elementA = this.elements[gutter.a];
            var elementB = this.elements[gutter.b];
            elementA.size = sizes[i - 1];
            elementB.size = sizes[i];
            elementA.element.style[options.direction] = elementA.size + "%";
            elementB.element.style[options.direction] = elementB.size + "%";
        }
    }

    public function destroy() {
        for (gutter in this.gutters) {
            gutter.parent.removeChild(gutter.gutter);
            this.elements[gutter.a].element.style[options.direction] = "";
            this.elements[gutter.b].element.style[options.direction] = "";
        }
    }
}

class SplitElement {
    public var element: Element;
    public var size: Float;
    public var minSize: Float;

    public function new(element: Element, options: SplitOptions) {
        this.element = element;
        this.size = options.sizes[elements.indexOf(element)];
        this.minSize = options.minSize;
    }
}

class SplitGutter {
    public var a: Int;
    public var b: Int;
    public var dragging: Bool;
    public var isFirst: Bool;
    public var isLast: Bool;
    public var direction: String;
    public var parent: Element;
    public var gutter: Element;
    public var aGutterSize: Float;
    public var bGutterSize: Float;

    public function new(a: Int, b: Int, options: SplitOptions) {
        this.a = a;
        this.b = b;
        this.dragging = false;
        this.isFirst = a == 0;
        this.isLast = b == options.elements.length - 1;
        this.direction = options.direction;
        this.parent = options.elements[a].element.parentNode;
        this.gutter = document.createElement("div");
        this.gutter.className = "gutter gutter-" + direction;
        this.parent.insertBefore(this.gutter, options.elements[b].element);
        this.aGutterSize = options.gutterSize;
        this.bGutterSize = options.gutterSize;

        if (this.isFirst) {
            this.aGutterSize /= 2;
        }
        if (this.isLast) {
            this.bGutterSize /= 2;
        }

        this.gutter.addEventListener("mousedown", onMouseDown);
        this.gutter.addEventListener("touchstart", onMouseDown);
    }

    private function onMouseDown(e: Event) {
        e.preventDefault();
        this.dragging = true;
        window.addEventListener("mouseup", onMouseUp);
        window.addEventListener("touchend", onMouseUp);
        window.addEventListener("touchcancel", onMouseUp);
        parent.addEventListener("mousemove", onMouseMove);
        parent.addEventListener("touchmove", onMouseMove);
    }

    private function onMouseUp(e: Event) {
        this.dragging = false;
        window.removeEventListener("mouseup", onMouseUp);
        window.removeEventListener("touchend", onMouseUp);
        window.removeEventListener("touchcancel", onMouseUp);
        parent.removeEventListener("mousemove", onMouseMove);
        parent.removeEventListener("touchmove", onMouseMove);
    }

    private function onMouseMove(e: Event) {
        // Implement mouse move logic here
    }
}

class SplitOptions {
    public var sizes: Array<Float>;
    public var minSize: Float;
    public var gutterSize: Float;
    public var snapOffset: Float;
    public var direction: String;
    public var cursor: String;
    public var gutter: Dynamic;
    public var elementStyle: Dynamic;
    public var gutterStyle: Dynamic;
    public var elements: Array<Element>;
}