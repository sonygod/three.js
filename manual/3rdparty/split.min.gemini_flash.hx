import js.Lib;

class Split {

    public static function init(elements:Array<Dynamic>, options:Dynamic = null):SplitJS {
        return new SplitJS(elements, options);
    }
}

class SplitJS {

    private static var global:Dynamic = Lib.global;
    private static var document:Dynamic = global.document;

    private var elements:Array<Element>;
    private var gutters:Array<Gutter>;
    private var parent:Dynamic;
    private var direction:String;
    private var sizes:Array<Float>;
    private var minSizes:Array<Float>;
    private var gutterSize:Int;
    private var snapOffset:Int;
    private var cursor:String;
    private var onDragStart:Dynamic;
    private var onDrag:Dynamic;
    private var onDragEnd:Dynamic;

    public function new(elements:Array<Dynamic>, options:Dynamic = null) {
        this.elements = [];
        for (element in elements) {
            this.elements.push(cast(element, Dynamic));
        }

        this.parent = this.elements[0].parentNode;

        options = options != null ? options : {};

        this.direction = options.direction != null ? options.direction : "horizontal";
        this.sizes = options.sizes != null ? options.sizes : this.elements.map(function(_) return 100 / this.elements.length);
        var minSize = options.minSize != null ? options.minSize : 100;
        this.minSizes = Std.isOfType(minSize, Array) ? cast minSize : this.elements.map(function(_) return minSize);
        this.gutterSize = options.gutterSize != null ? options.gutterSize : 10;
        this.snapOffset = options.snapOffset != null ? options.snapOffset : 30;
        this.cursor = options.cursor != null ? options.cursor : (this.direction == "horizontal" ? "ew-resize" : "ns-resize");

        this.onDragStart = options.onDragStart;
        this.onDrag = options.onDrag;
        this.onDragEnd = options.onDragEnd;

        this.gutters = [];
        for (i in 1...this.elements.length) {
            this.gutters.push(new Gutter(this, i - 1));
        }

        this.setSizes(this.sizes);
    }

    public function setSizes(sizes:Array<Float>):Void {
        var totalSize = this.getTotalSize();
        var remainingSize = totalSize;

        for (i in 0...sizes.length) {
            var size = sizes[i];
            if (i == sizes.length - 1) {
                size = remainingSize;
            }
            this.sizes[i] = size / totalSize * 100;
            remainingSize -= size;
        }

        this.updateElements();
    }

    public function getSizes():Array<Float> {
        return this.sizes.copy();
    }

    public function collapse(index:Int):Void {
        var gutter = this.gutters[index];
        var prevSize = this.sizes[gutter.index];
        var nextSize = this.sizes[gutter.index + 1];
        this.sizes[gutter.index] = 0;
        this.sizes[gutter.index + 1] = prevSize + nextSize;
        this.updateElements();
    }

    public function destroy():Void {
        for (gutter in this.gutters) {
            gutter.destroy();
        }

        this.gutters = [];

        for (element in this.elements) {
            element.style.flex = null;
        }
    }

    private function getTotalSize():Float {
        if (this.direction == "horizontal") {
            return this.parent.offsetWidth;
        } else {
            return this.parent.offsetHeight;
        }
    }

    private function updateElements():Void {
        var totalSize = this.getTotalSize();
        var remainingSize = totalSize;

        for (i in 0...this.elements.length) {
            var element = this.elements[i];
            var size = this.sizes[i] / 100 * totalSize;
            if (i == this.elements.length - 1) {
                size = remainingSize;
            }

            if (this.direction == "horizontal") {
                element.style.flex = "0 0 " + size + "px";
            } else {
                element.style.flex = "0 0 " + size + "px";
            }

            remainingSize -= size;
        }
    }

    private function startDragging(gutter:Gutter, event:Dynamic):Void {
        event.preventDefault();

        gutter.dragging = true;

        var eventTarget = event.target != null ? event.target : event;
        if (eventTarget.touches != null && eventTarget.touches.length > 0) {
            gutter.startX = eventTarget.touches[0].clientX;
        } else {
            gutter.startX = event.clientX;
        }

        document.addEventListener("mousemove", gutter.onMouseMove);
        document.addEventListener("mouseup", gutter.onMouseUp);
        document.addEventListener("touchmove", gutter.onMouseMove);
        document.addEventListener("touchend", gutter.onMouseUp);

        this.parent.style.cursor = this.cursor;

        if (this.onDragStart != null) {
            this.onDragStart();
        }
    }

    private function onMouseMove(gutter:Gutter, event:Dynamic):Void {
        if (!gutter.dragging) {
            return;
        }

        var eventTarget = event.target != null ? event.target : event;
        var x = eventTarget.touches != null && eventTarget.touches.length > 0 ? eventTarget.touches[0].clientX : event.clientX;

        var deltaX = x - gutter.startX;

        var prevSize = this.sizes[gutter.index];
        var nextSize = this.sizes[gutter.index + 1];

        var newPrevSize = (prevSize / 100 * this.getTotalSize() + deltaX) / this.getTotalSize() * 100;
        var newNextSize = (nextSize / 100 * this.getTotalSize() - deltaX) / this.getTotalSize() * 100;

        if (newPrevSize < this.minSizes[gutter.index] / this.getTotalSize() * 100) {
            newPrevSize = this.minSizes[gutter.index] / this.getTotalSize() * 100;
            newNextSize = prevSize + nextSize - newPrevSize;
        } else if (newNextSize < this.minSizes[gutter.index + 1] / this.getTotalSize() * 100) {
            newNextSize = this.minSizes[gutter.index + 1] / this.getTotalSize() * 100;
            newPrevSize = prevSize + nextSize - newNextSize;
        }

        this.sizes[gutter.index] = newPrevSize;
        this.sizes[gutter.index + 1] = newNextSize;

        this.updateElements();

        if (this.onDrag != null) {
            this.onDrag();
        }
    }

    private function stopDragging(gutter:Gutter, event:Dynamic):Void {
        gutter.dragging = false;

        document.removeEventListener("mousemove", gutter.onMouseMove);
        document.removeEventListener("mouseup", gutter.onMouseUp);
        document.removeEventListener("touchmove", gutter.onMouseMove);
        document.removeEventListener("touchend", gutter.onMouseUp);

        this.parent.style.cursor = "default";

        if (this.onDragEnd != null) {
            this.onDragEnd();
        }
    }
}

class Gutter {

    public var index:Int;
    public var dragging:Bool = false;
    public var startX:Float = 0;
    private var onMouseMove:Dynamic;
    private var onMouseUp:Dynamic;
    private var gutterElement:Dynamic;
    private var parent:Dynamic;

    public function new(split:SplitJS, index:Int) {
        this.index = index;
        this.parent = split;
        this.gutterElement = this.createGutterElement();
        split.parent.insertBefore(this.gutterElement, split.elements[index + 1]);

        this.onMouseMove = function(event) split.onMouseMove(this, event);
        this.onMouseUp = function(event) split.stopDragging(this, event);

        this.gutterElement.addEventListener("mousedown", function(event) split.startDragging(this, event));
        this.gutterElement.addEventListener("touchstart", function(event) split.startDragging(this, event));
    }

    public function destroy():Void {
        this.parent.parent.removeChild(this.gutterElement);
    }

    private function createGutterElement():Dynamic {
        var gutterElement = document.createElement("div");
        gutterElement.className = "gutter gutter-" + this.parent.direction;
        gutterElement.style.width = (this.parent.direction == "horizontal" ? this.parent.gutterSize : "100%") + "px";
        gutterElement.style.height = (this.parent.direction == "vertical" ? this.parent.gutterSize : "100%") + "px";
        gutterElement.style.cursor = this.parent.cursor;
        return gutterElement;
    }
}