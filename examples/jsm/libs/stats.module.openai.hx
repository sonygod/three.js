package three.js.examples.jsm.libs;

import js.html.Document;
import js.html.Element;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Window;

class Stats {
    private var mode:Int = 0;
    private var container:Element;
    private var fpsPanel:Panel;
    private var msPanel:Panel;
    private var memPanel:Panel;
    private var beginTime:Float;
    private var prevTime:Float;
    private var frames:Int;

    public function new() {
        container = Document.createElement("div");
        container.style.cssText = 'position:fixed;top:0;left:0;cursor:pointer;opacity:0.9;z-index:10000';
        container.addEventListener("click", function(event:Event) {
            event.preventDefault();
            showPanel(++mode % container.children.length);
        }, false);

        fpsPanel = addPanel(new Panel("FPS", "#0ff", "#002"));
        msPanel = addPanel(new Panel("MS", "#0f0", "#020"));

        if (Window.performance != null && Window.performance.memory != null) {
            memPanel = addPanel(new Panel("MB", "#f08", "#201"));
        }

        showPanel(0);

        beginTime = (Window.performance != null) ? Window.performance.now() : Date.now();
        prevTime = beginTime;
        frames = 0;
    }

    private function addPanel(panel:Panel):Panel {
        container.appendChild(panel.dom);
        return panel;
    }

    private function showPanel(id:Int) {
        for (i in 0...container.children.length) {
            container.children[i].style.display = (i == id) ? "block" : "none";
        }
        mode = id;
    }

    public function begin():Void {
        beginTime = (Window.performance != null) ? Window.performance.now() : Date.now();
    }

    public function end():Float {
        frames++;
        var time:Float = (Window.performance != null) ? Window.performance.now() : Date.now();
        msPanel.update(time - beginTime, 200);

        if (time >= prevTime + 1000) {
            fpsPanel.update((frames * 1000) / (time - prevTime), 100);
            prevTime = time;
            frames = 0;

            if (memPanel != null) {
                var memory = Window.performance.memory;
                memPanel.update(memory.usedJSHeapSize / 1048576, memory.jsHeapSizeLimit / 1048576);
            }
        }

        return time;
    }

    public function update():Void {
        beginTime = end();
    }

    public var dom:Element;
    public var domElement:Element;
    public var setMode:Int->Void;

    public static function main() {
        var stats = new Stats();
        stats.dom = stats.container;
        stats.domElement = stats.container;
        stats.setMode = stats.showPanel;
    }
}

class Panel {
    private var min:Float;
    private var max:Float;
    private var round:Float->Int;
    private var PR:Int;
    private var WIDTH:Int;
    private var HEIGHT:Int;
    private var TEXT_X:Int;
    private var TEXT_Y:Int;
    private var GRAPH_X:Int;
    private var GRAPH_Y:Int;
    private var GRAPH_WIDTH:Int;
    private var GRAPH_HEIGHT:Int;
    private var canvas:CanvasElement;
    private var context:CanvasRenderingContext2D;

    public function new(name:String, fg:String, bg:String) {
        min = Math.POSITIVE_INFINITY;
        max = 0;
        round = Math.round;
        PR = (Window.devicePixelRatio != null) ? Std.int(Window.devicePixelRatio) : 1;

        WIDTH = 80 * PR;
        HEIGHT = 48 * PR;
        TEXT_X = 3 * PR;
        TEXT_Y = 2 * PR;
        GRAPH_X = 3 * PR;
        GRAPH_Y = 15 * PR;
        GRAPH_WIDTH = 74 * PR;
        GRAPH_HEIGHT = 30 * PR;

        canvas = Document.createElement("canvas");
        canvas.width = WIDTH;
        canvas.height = HEIGHT;
        canvas.style.cssText = 'width:80px;height:48px';

        context = canvas.getContext("2d");
        context.font = 'bold ' + (9 * PR) + 'px Helvetica,Arial,sans-serif';
        context.textBaseline = 'top';

        context.fillStyle = bg;
        context.fillRect(0, 0, WIDTH, HEIGHT);

        context.fillStyle = fg;
        context.fillText(name, TEXT_X, TEXT_Y);
        context.fillRect(GRAPH_X, GRAPH_Y, GRAPH_WIDTH, GRAPH_HEIGHT);

        context.fillStyle = bg;
        context.globalAlpha = 0.9;
        context.fillRect(GRAPH_X, GRAPH_Y, GRAPH_WIDTH, GRAPH_HEIGHT);
    }

    public function update(value:Float, maxValue:Float) {
        min = Math.min(min, value);
        max = Math.max(max, value);

        context.fillStyle = bg;
        context.globalAlpha = 1;
        context.fillRect(0, 0, WIDTH, GRAPH_Y);
        context.fillStyle = fg;
        context.fillText(round(value) + ' ' + name + ' (' + round(min) + '-' + round(max) + ')', TEXT_X, TEXT_Y);

        context.drawImage(canvas, GRAPH_X + PR, GRAPH_Y, GRAPH_WIDTH - PR, GRAPH_HEIGHT, GRAPH_X, GRAPH_Y, GRAPH_WIDTH - PR, GRAPH_HEIGHT);

        context.fillRect(GRAPH_X + GRAPH_WIDTH - PR, GRAPH_Y, PR, GRAPH_HEIGHT);

        context.fillStyle = bg;
        context.globalAlpha = 0.9;
        context.fillRect(GRAPH_X + GRAPH_WIDTH - PR, GRAPH_Y, PR, round((1 - (value / maxValue)) * GRAPH_HEIGHT));
    }

    public var dom:Element;
}