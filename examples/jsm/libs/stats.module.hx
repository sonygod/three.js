package three.js.examples.jsm.libs;

import js.html.Document;
import js.html.DivElement;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Window;

class Stats {
    private var mode:Int = 0;
    private var container:DivElement;
    private var beginTime:Float;
    private var prevTime:Float;
    private var frames:Int = 0;

    public function new() {
        container = Document.createElement("div");
        container.style.cssText = 'position:fixed;top:0;left:0;cursor:pointer;opacity:0.9;z-index:10000';
        container.addEventListener("click", function(event) {
            event.preventDefault();
            showPanel(++mode % container.children.length);
        }, false);

        beginTime = (Window.performance != null ? Window.performance.now() : Date.now());
        prevTime = beginTime;
    }

    private function addPanel(panel:Panel):Panel {
        container.appendChild(panel.dom);
        return panel;
    }

    private function showPanel(id:Int) {
        for (i in 0...container.children.length) {
            container.children[i].style.display = i == id ? 'block' : 'none';
        }
        mode = id;
    }

    private var fpsPanel:Panel;
    private var msPanel:Panel;
    private var memPanel:Panel;

    public function new() {
        fpsPanel = addPanel(new Panel("FPS", "#0ff", "#002"));
        msPanel = addPanel(new Panel("MS", "#0f0", "#020"));

        if (Window.performance != null && Window.performance.memory != null) {
            memPanel = addPanel(new Panel("MB", "#f08", "#201"));
        }

        showPanel(0);

        this.REVISION = 16;
        this.dom = container;
        this.addPanel = addPanel;
        this.showPanel = showPanel;

        this.begin = function() {
            beginTime = Window.performance != null ? Window.performance.now() : Date.now();
        }

        this.end = function() {
            frames++;
            var time = Window.performance != null ? Window.performance.now() : Date.now();
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

        this.update = function() {
            beginTime = this.end();
        }

        // Backwards Compatibility
        this.domElement = container;
        this.setMode = showPanel;
    }
}

class Panel {
    private var min:Float = Math.POSITIVE_INFINITY;
    private var max:Float = 0;
    private var round:Float->Int = Math.round;
    private var PR:Float = Window.devicePixelRatio != null ? Window.devicePixelRatio : 1;
    private var WIDTH:Int = 80 * PR;
    private var HEIGHT:Int = 48 * PR;
    private var TEXT_X:Int = 3 * PR;
    private var TEXT_Y:Int = 2 * PR;
    private var GRAPH_X:Int = 3 * PR;
    private var GRAPH_Y:Int = 15 * PR;
    private var GRAPH_WIDTH:Int = 74 * PR;
    private var GRAPH_HEIGHT:Int = 30 * PR;

    private var canvas:CanvasElement;
    private var context:CanvasRenderingContext2D;

    public function new(name:String, fg:String, bg:String) {
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

    public var dom(get, never):CanvasElement;

    private function get_dom():CanvasElement {
        return canvas;
    }
}