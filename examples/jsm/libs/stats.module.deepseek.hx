class Stats {

    var mode:Int = 0;
    var container:js.html.Element;

    public function new() {

        container = js.Browser.document.createElement('div');
        container.style.cssText = 'position:fixed;top:0;left:0;cursor:pointer;opacity:0.9;z-index:10000';
        container.addEventListener('click', function(event:js.html.MouseEvent) {

            event.preventDefault();
            showPanel(++mode % container.children.length);

        }, false);

        var beginTime:Float = js.Date.now();
        var prevTime:Float = beginTime;
        var frames:Int = 0;

        var fpsPanel = addPanel(new Stats.Panel('FPS', '#0ff', '#002'));
        var msPanel = addPanel(new Stats.Panel('MS', '#0f0', '#020'));

        if (js.Browser.performance && js.Browser.performance.memory) {

            var memPanel = addPanel(new Stats.Panel('MB', '#f08', '#201'));

        }

        showPanel(0);
    }

    public function addPanel(panel:Stats.Panel):Stats.Panel {

        container.appendChild(panel.dom);
        return panel;

    }

    public function showPanel(id:Int) {

        for (i in 0...container.children.length) {

            container.children[i].style.display = (i == id) ? 'block' : 'none';

        }

        mode = id;

    }

    public function begin() {

        beginTime = js.Date.now();

    }

    public function end():Float {

        frames++;

        var time:Float = js.Date.now();

        msPanel.update(time - beginTime, 200);

        if (time >= prevTime + 1000) {

            fpsPanel.update((frames * 1000) / (time - prevTime), 100);

            prevTime = time;
            frames = 0;

            if (memPanel) {

                var memory = js.Browser.performance.memory;
                memPanel.update(memory.usedJSHeapSize / 1048576, memory.jsHeapSizeLimit / 1048576);

            }

        }

        return time;

    }

    public function update() {

        beginTime = this.end();

    }

    public var dom:js.html.Element {
        return container;
    }

    public var domElement:js.html.Element {
        return container;
    }

    public var setMode(id:Int) {
        showPanel(id);
    }

    public static var REVISION:Int = 16;

}

class Stats.Panel {

    var min:Float = Infinity;
    var max:Float = 0;
    var round:Int->Int = js.Browser.Math.round;
    var PR:Int = round(js.Browser.window.devicePixelRatio || 1);

    var WIDTH:Int = 80 * PR;
    var HEIGHT:Int = 48 * PR;
    var TEXT_X:Int = 3 * PR;
    var TEXT_Y:Int = 2 * PR;
    var GRAPH_X:Int = 3 * PR;
    var GRAPH_Y:Int = 15 * PR;
    var GRAPH_WIDTH:Int = 74 * PR;
    var GRAPH_HEIGHT:Int = 30 * PR;

    var canvas:js.html.Element;
    var context:js.html.CanvasRenderingContext2D;

    public function new(name:String, fg:String, bg:String) {

        canvas = js.Browser.document.createElement('canvas');
        canvas.width = WIDTH;
        canvas.height = HEIGHT;
        canvas.style.cssText = 'width:80px;height:48px';

        context = canvas.getContext('2d');
        context.font = 'bold ' + (9 * PR) + 'px Helvetica,Arial,sans-serif';
        context.textBaseline = 'top';

        context.fillStyle = bg;
        context.fillRect(0, 0, WIDTH, HEIGHT);

        context.fillStyle = fg;
        context.fillText(round(0) + ' ' + name + ' (' + round(min) + '-' + round(max) + ')', TEXT_X, TEXT_Y);
        context.fillRect(GRAPH_X, GRAPH_Y, GRAPH_WIDTH, GRAPH_HEIGHT);

        context.fillStyle = bg;
        context.globalAlpha = 0.9;
        context.fillRect(GRAPH_X, GRAPH_Y, GRAPH_WIDTH, GRAPH_HEIGHT);

    }

    public function update(value:Float, maxValue:Float) {

        min = js.Math.min(min, value);
        max = js.Math.max(max, value);

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

    public var dom:js.html.Element {
        return canvas;
    }

}