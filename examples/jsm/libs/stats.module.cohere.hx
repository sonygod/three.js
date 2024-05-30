class Stats {
    var mode:Int = 0;
    var container:HTMLDivElement = document.createElement("div");
    container.style.cssText = "position:fixed;top:0;left:0;cursor:pointer;opacity:0.9;z-index:10000";
    container.addEventListener("click", function(event:Event) {
        event.preventDefault();
        showPanel(++mode % container.children.length);
    }, false);

    function addPanel(panel:Panel) {
        container.appendChild(panel.dom);
        return panel;
    }

    function showPanel(id:Int) {
        var i:Int;
        for (i = 0; i < container.children.length; i++) {
            container.children[i].style.display = i == id ? "block" : "none";
        }
        mode = id;
    }

    var beginTime:Float = (performance != null ? performance : Date).now();
    var prevTime:Float = beginTime;
    var frames:Int = 0;

    var fpsPanel:Panel = addPanel(new Panel("FPS", "#0ff", "#002"));
    var msPanel:Panel = addPanel(new Panel("MS", "#0f0", "#020"));

    if (performance != null && performance.memory != null) {
        var memPanel:Panel = addPanel(new Panel("MB", "#f08", "#201"));
    }

    showPanel(0);

    public function get REVISION():Int {
        return 16;
    }

    public function get dom():HTMLDivElement {
        return container;
    }

    public function addPanel(panel:Panel):Panel {
        return addPanel(panel);
    }

    public function showPanel(id:Int):Void {
        showPanel(id);
    }

    public function begin():Void {
        beginTime = (performance != null ? performance : Date).now();
    }

    public function end():Float {
        frames++;
        var time:Float = (performance != null ? performance : Date).now();
        msPanel.update(time - beginTime, 200);
        if (time >= prevTime + 1000) {
            fpsPanel.update(Std.int(frames * 1000 / (time - prevTime)), 100);
            prevTime = time;
            frames = 0;
            if (memPanel != null) {
                var memory:MemoryUsage = performance.memory;
                memPanel.update(memory.usedJSHeapSize / 1048576, memory.jsHeapSizeLimit / 1048576);
            }
        }
        return time;
    }

    public function update():Float {
        beginTime = end();
    }

    public function get domElement():HTMLDivElement {
        return container;
    }

    public function setMode(id:Int):Void {
        showPanel(id);
    }
}

class Panel {
    var min:Float = Math.POSITIVE_INFINITY;
    var max:Float = 0;
    var round:Float -> Int = Math.round;
    var PR:Float = Math.round(window.devicePixelRatio != null ? window.devicePixelRatio : 1);

    static var WIDTH:Int = 80 * PR;
    static var HEIGHT:Int = 48 * PR;
    static var TEXT_X:Int = 3 * PR;
    static var TEXT_Y:Int = 2 * PR;
    static var GRAPH_X:Int = 3 * PR;
    static var GRAPH_Y:Int = 15 * PR;
    static var GRAPH_WIDTH:Int = 74 * PR;
    static var GRAPH_HEIGHT:Int = 30 * PR;

    var canvas:HTMLCanvasElement = document.createElement("canvas");
    canvas.width = WIDTH;
    canvas.height = HEIGHT;
    canvas.style.cssText = "width:80px;height:48px";

    var context:CanvasRenderingContext2D = canvas.getContext2d();
    context.font = "bold " + (9 * PR) + "px Helvetica,Arial,sans-serif";
    context.textBaseline = "top";

    context.fillStyle = "#002";
    context.fillRect(0, 0, WIDTH, HEIGHT);

    context.fillStyle = "#0ff";
    context.fillText(name, TEXT_X, TEXT_Y);
    context.fillRect(GRAPH_X, GRAPH_Y, GRAPH_WIDTH, GRAPH_HEIGHT);

    context.fillStyle = "#002";
    context.globalAlpha = 0.9;
    context.fillRect(GRAPH_X, GRAPH_Y, GRAPH_WIDTH, GRAPH_HEIGHT);

    public function get dom():HTMLCanvasElement {
        return canvas;
    }

    public function update(value:Float, maxValue:Float) {
        min = Math.min(min, value);
        max = Math.max(max, value);
        context.fillStyle = "#002";
        context.globalAlpha = 1;
        context.fillRect(0, 0, WIDTH, GRAPH_Y);
        context.fillStyle = "#0ff";
        context.fillText(round(value) + " " + name + " (" + round(min) + "-" + round(max) + ")", TEXT_X, TEXT_Y);
        context.drawImage(canvas, GRAPH_X + PR, GRAPH_Y, GRAPH_WIDTH - PR, GRAPH_HEIGHT, GRAPH_X, GRAPH_Y, GRAPH_WIDTH - PR, GRAPH_HEIGHT);
        context.fillRect(GRAPH_X + GRAPH_WIDTH - PR, GRAPH_Y, PR, GRAPH_HEIGHT);
        context.fillStyle = "#002";
        context.globalAlpha = 0.9;
        context.fillRect(GRAPH_X + GRAPH_WIDTH - PR, GRAPH_Y, PR, round((1 - (value / maxValue)) * GRAPH_HEIGHT));
    }

    var name:String;
    var fg:String;
    var bg:String;

    public function new(name:String, fg:String, bg:String) {
        this.name = name;
        this.fg = fg;
        this.bg = bg;
    }
}