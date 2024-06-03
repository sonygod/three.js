import haxe.ui.InteractiveObject;
import haxe.ui.HtmlElement;
import haxe.ui.HtmlDisplay;
import haxe.Timer;
import js.Browser;

class Stats {
    private var mode: Int = 0;
    private var container: HtmlElement;
    private var fpsPanel: StatsPanel;
    private var msPanel: StatsPanel;
    private var memPanel: StatsPanel = null;
    private var beginTime: Float;
    private var prevTime: Float;
    private var frames: Int = 0;

    public function new() {
        this.container = new HtmlElement("div");
        this.container.style.set("position", "fixed");
        this.container.style.set("top", "0");
        this.container.style.set("left", "0");
        this.container.style.set("cursor", "pointer");
        this.container.style.set("opacity", "0.9");
        this.container.style.set("zIndex", "10000");

        this.container.addEventListener("click", (event: Event) -> {
            event.preventDefault();
            this.showPanel(++this.mode % this.container.children.length);
        });

        this.beginTime = Browser.window.performance != null ? Browser.window.performance.now() : Date.now();
        this.prevTime = this.beginTime;

        this.fpsPanel = this.addPanel(new StatsPanel("FPS", "#0ff", "#002"));
        this.msPanel = this.addPanel(new StatsPanel("MS", "#0f0", "#020"));

        if (js.Browser.performance != null && js.Browser.performance.memory != null) {
            this.memPanel = this.addPanel(new StatsPanel("MB", "#f08", "#201"));
        }

        this.showPanel(0);

        Browser.document.body.appendChild(this.container);
    }

    public function addPanel(panel: StatsPanel): StatsPanel {
        this.container.appendChild(panel.dom);
        return panel;
    }

    public function showPanel(id: Int) {
        for (i in 0...this.container.children.length) {
            this.container.children[i].style.set("display", i == id ? "block" : "none");
        }

        this.mode = id;
    }

    public function begin(): Void {
        this.beginTime = Browser.window.performance != null ? Browser.window.performance.now() : Date.now();
    }

    public function end(): Float {
        this.frames++;
        var time: Float = Browser.window.performance != null ? Browser.window.performance.now() : Date.now();

        this.msPanel.update(time - this.beginTime, 200);

        if (time >= this.prevTime + 1000) {
            this.fpsPanel.update((this.frames * 1000) / (time - this.prevTime), 100);

            this.prevTime = time;
            this.frames = 0;

            if (this.memPanel != null) {
                var memory = Browser.window.performance.memory;
                this.memPanel.update(memory.usedJSHeapSize / 1048576, memory.jsHeapSizeLimit / 1048576);
            }
        }

        return time;
    }

    public function update(): Void {
        this.beginTime = this.end();
    }

    public function get dom(): HtmlElement {
        return this.container;
    }

    public function setMode(id: Int): Void {
        this.showPanel(id);
    }

    public function get domElement(): HtmlElement {
        return this.container;
    }
}

class StatsPanel {
    private var min: Float = Float.POSITIVE_INFINITY;
    private var max: Float = 0;
    private var PR: Int = Math.round(js.Browser.window.devicePixelRatio != null ? js.Browser.window.devicePixelRatio : 1);
    private var WIDTH: Int = 80 * this.PR;
    private var HEIGHT: Int = 48 * this.PR;
    private var TEXT_X: Int = 3 * this.PR;
    private var TEXT_Y: Int = 2 * this.PR;
    private var GRAPH_X: Int = 3 * this.PR;
    private var GRAPH_Y: Int = 15 * this.PR;
    private var GRAPH_WIDTH: Int = 74 * this.PR;
    private var GRAPH_HEIGHT: Int = 30 * this.PR;
    private var canvas: HtmlElement;
    private var context: CanvasRenderingContext2D;

    public function new(name: String, fg: String, bg: String) {
        this.canvas = new HtmlElement("canvas");
        this.canvas.width = this.WIDTH;
        this.canvas.height = this.HEIGHT;
        this.canvas.style.set("width", "80px");
        this.canvas.style.set("height", "48px");

        this.context = this.canvas.canvas.getContext("2d");
        this.context.font = "bold " + (9 * this.PR) + "px Helvetica,Arial,sans-serif";
        this.context.textBaseline = "top";

        this.context.fillStyle = bg;
        this.context.fillRect(0, 0, this.WIDTH, this.HEIGHT);

        this.context.fillStyle = fg;
        this.context.fillText(name, this.TEXT_X, this.TEXT_Y);
        this.context.fillRect(this.GRAPH_X, this.GRAPH_Y, this.GRAPH_WIDTH, this.GRAPH_HEIGHT);

        this.context.fillStyle = bg;
        this.context.globalAlpha = 0.9;
        this.context.fillRect(this.GRAPH_X, this.GRAPH_Y, this.GRAPH_WIDTH, this.GRAPH_HEIGHT);
    }

    public function update(value: Float, maxValue: Float): Void {
        this.min = Math.min(this.min, value);
        this.max = Math.max(this.max, value);

        this.context.fillStyle = bg;
        this.context.globalAlpha = 1;
        this.context.fillRect(0, 0, this.WIDTH, this.GRAPH_Y);
        this.context.fillStyle = fg;
        this.context.fillText(Math.round(value) + ' ' + name + ' (' + Math.round(this.min) + '-' + Math.round(this.max) + ')', this.TEXT_X, this.TEXT_Y);

        this.context.drawImage(this.canvas.canvas, this.GRAPH_X + this.PR, this.GRAPH_Y, this.GRAPH_WIDTH - this.PR, this.GRAPH_HEIGHT, this.GRAPH_X, this.GRAPH_Y, this.GRAPH_WIDTH - this.PR, this.GRAPH_HEIGHT);

        this.context.fillRect(this.GRAPH_X + this.GRAPH_WIDTH - this.PR, this.GRAPH_Y, this.PR, this.GRAPH_HEIGHT);

        this.context.fillStyle = bg;
        this.context.globalAlpha = 0.9;
        this.context.fillRect(this.GRAPH_X + this.GRAPH_WIDTH - this.PR, this.GRAPH_Y, this.PR, Math.round((1 - (value / maxValue)) * this.GRAPH_HEIGHT));
    }

    public function get dom(): HtmlElement {
        return this.canvas;
    }
}