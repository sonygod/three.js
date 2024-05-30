import js.html.Document;
import js.html.Element;
import js.html.CanvasElement;
import js.html.Performance;
import js.html.PerformanceMemory;
import js.html.CanvasRenderingContext2D;
import js.html.Event;
import js.html.MouseEvent;
import js.html.Window;

class Stats {
    public static function main() {
        var stats = new Stats();
        Document.current.body.appendChild(stats.dom);
    }

    private var mode:Int;
    private var container:Element;
    private var beginTime:Float;
    private var prevTime:Float;
    private var frames:Int;
    private var fpsPanel:Panel;
    private var msPanel:Panel;
    private var memPanel:Panel;

    public function new() {
        mode = 0;

        container = Document.current.createElement('div');
        container.style.cssText = 'position:fixed;top:0;left:0;cursor:pointer;opacity:0.9;z-index:10000';
        container.addEventListener('click', function(event:Event) {
            event.preventDefault();
            showPanel(++mode % container.children.length);
        }, false);

        fpsPanel = addPanel(new Panel('FPS', '#0ff', '#002'));
        msPanel = addPanel(new Panel('MS', '#0f0', '#020'));

        if (Window.current.performance.memory != null) {
            memPanel = addPanel(new Panel('MB', '#f08', '#201'));
        }

        showPanel(0);
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

    public function begin():Void {
        beginTime = (Performance.currentTimeMillis() / 1000.0);
    }

    public function end():Float {
        frames++;
        var time:Float = (Performance.currentTimeMillis() / 1000.0);
        msPanel.update(time - beginTime, 200);

        if (time >= prevTime + 1000) {
            fpsPanel.update((frames * 1000) / (time - prevTime), 100);
            prevTime = time;
            frames = 0;

            if (memPanel != null) {
                var memory:PerformanceMemory = Window.current.performance.memory;
                memPanel.update(memory.usedJSHeapSize / 1048576, memory.jsHeapSizeLimit / 1048576);
            }
        }

        return time;
    }

    public function update():Void {
        beginTime = this.end();
    }

    public var dom(get, never):Element {
        return container;
    }

    public var REVISION(get, never):Int {
        return 16;
    }

    public var domElement(get, never):Element {
        return container;
    }

    public function setMode(id:Int):Void {
        showPanel(id);
    }
}

class Panel {
    public var dom:CanvasElement;
    private var context:CanvasRenderingContext2D;
    private var min:Float;
    private var max:Float;
    private var round:Float;
    private var PR:Float;
    private var WIDTH:Float;
    private var HEIGHT:Float;
    private var TEXT_X:Float;
    private var TEXT_Y:Float;
    private var GRAPH_X:Float;
    private var GRAPH_Y:Float;
    private var GRAPH_WIDTH:Float;
    private var GRAPH_HEIGHT:Float;

    public function new(name:String, fg:String, bg:String) {
        min = Float.POSITIVE_INFINITY;
        max = 0;
        round = Math.round;
        PR = round(Window.current.devicePixelRatio || 1);

        WIDTH = 80 * PR;
        HEIGHT = 48 * PR;
        TEXT_X = 3 * PR;
        TEXT_Y = 2 * PR;
        GRAPH_X = 3 * PR;
        GRAPH_Y = 15 * PR;
        GRAPH_WIDTH = 74 * PR;
        GRAPH_HEIGHT = 30 * PR;

        dom = cast Document.current.createElement('canvas');
        dom.width = WIDTH;
        dom.height = HEIGHT;
        dom.style.cssText = 'width:80px;height:48px';

        context = cast dom.getContext('2d');
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

    public function update(value:Float, maxValue:Float):Void {
        min = Math.min(min, value);
        max = Math.max(max, value);

        context.fillStyle = bg;
        context.globalAlpha = 1;
        context.fillRect(0, 0, WIDTH, GRAPH_Y);
        context.fillStyle = fg;
        context.fillText(round(value) + ' ' + name + ' (' + round(min) + '-' + round(max) + ')', TEXT_X, TEXT_Y);

        context.drawImage(dom, GRAPH_X + PR, GRAPH_Y, GRAPH_WIDTH - PR, GRAPH_HEIGHT, GRAPH_X, GRAPH_Y, GRAPH_WIDTH - PR, GRAPH_HEIGHT);

        context.fillRect(GRAPH_X + GRAPH_WIDTH - PR, GRAPH_Y, PR, GRAPH_HEIGHT);

        context.fillStyle = bg;
        context.globalAlpha = 0.9;
        context.fillRect(GRAPH_X + GRAPH_WIDTH - PR, GRAPH_Y, PR, round((1 - (value / maxValue)) * GRAPH_HEIGHT));
    }
}