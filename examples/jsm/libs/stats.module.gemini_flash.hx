import js.html.Element;
import js.html.CanvasElement;
import js.html.Window;
import js.html.Performance;
import js.html.Document;

class Stats {
  private var mode:Int = 0;
  private var container:Element;
  private var beginTime:Float;
  private var prevTime:Float;
  private var frames:Int = 0;
  private var fpsPanel:Panel;
  private var msPanel:Panel;
  private var memPanel:Panel;

  public function new() {
    container = Document.window.document.createElement('div');
    container.style.cssText = 'position:fixed;top:0;left:0;cursor:pointer;opacity:0.9;z-index:10000';
    container.addEventListener('click', function(event:Dynamic) {
      event.preventDefault();
      showPanel(++mode % container.children.length);
    }, false);

    beginTime = (Performance.now ? Performance.now() : Date.now());
    prevTime = beginTime;

    fpsPanel = addPanel(new Panel('FPS', '#0ff', '#002'));
    msPanel = addPanel(new Panel('MS', '#0f0', '#020'));

    if (Window.self.performance && Window.self.performance.memory) {
      memPanel = addPanel(new Panel('MB', '#f08', '#201'));
    }

    showPanel(0);
  }

  public var REVISION:Int = 16;

  public var dom:Element = container;

  public function addPanel(panel:Panel):Panel {
    container.appendChild(panel.dom);
    return panel;
  }

  public function showPanel(id:Int):Void {
    for (i in 0...container.children.length) {
      container.children[i].style.display = (i == id) ? 'block' : 'none';
    }
    mode = id;
  }

  public function begin():Void {
    beginTime = (Performance.now ? Performance.now() : Date.now());
  }

  public function end():Float {
    frames++;
    var time = (Performance.now ? Performance.now() : Date.now());
    msPanel.update(time - beginTime, 200);

    if (time >= prevTime + 1000) {
      fpsPanel.update((frames * 1000) / (time - prevTime), 100);
      prevTime = time;
      frames = 0;

      if (memPanel != null) {
        var memory = Performance.memory;
        memPanel.update(memory.usedJSHeapSize / 1048576, memory.jsHeapSizeLimit / 1048576);
      }
    }

    return time;
  }

  public function update():Void {
    beginTime = end();
  }

  public var domElement:Element = container;

  public function setMode(id:Int):Void {
    showPanel(id);
  }
}

class Panel {
  private var min:Float = Math.POSITIVE_INFINITY;
  private var max:Float = 0;
  private var canvas:CanvasElement;
  private var context:js.html.CanvasRenderingContext2D;
  private var PR:Int;

  public function new(name:String, fg:String, bg:String) {
    PR = Math.round(Window.devicePixelRatio || 1);
    canvas = Document.window.document.createElement('canvas');
    canvas.width = 80 * PR;
    canvas.height = 48 * PR;
    canvas.style.cssText = 'width:80px;height:48px';
    context = canvas.getContext('2d');
    context.font = 'bold ' + (9 * PR) + 'px Helvetica,Arial,sans-serif';
    context.textBaseline = 'top';
    context.fillStyle = bg;
    context.fillRect(0, 0, canvas.width, canvas.height);
    context.fillStyle = fg;
    context.fillText(name, 3 * PR, 2 * PR);
    context.fillRect(3 * PR, 15 * PR, 74 * PR, 30 * PR);
    context.fillStyle = bg;
    context.globalAlpha = 0.9;
    context.fillRect(3 * PR, 15 * PR, 74 * PR, 30 * PR);
  }

  public var dom:CanvasElement = canvas;

  public function update(value:Float, maxValue:Float):Void {
    min = Math.min(min, value);
    max = Math.max(max, value);
    context.fillStyle = '#000';
    context.globalAlpha = 1;
    context.fillRect(0, 0, canvas.width, 15 * PR);
    context.fillStyle = '#0ff';
    context.fillText(Math.round(value) + ' ' + 'FPS' + ' (' + Math.round(min) + '-' + Math.round(max) + ')', 3 * PR, 2 * PR);
    context.drawImage(canvas, 4 * PR, 15 * PR, 73 * PR, 30 * PR, 3 * PR, 15 * PR, 73 * PR, 30 * PR);
    context.fillRect(77 * PR, 15 * PR, PR, 30 * PR);
    context.fillStyle = '#000';
    context.globalAlpha = 0.9;
    context.fillRect(77 * PR, 15 * PR, PR, Math.round((1 - (value / maxValue)) * 30 * PR));
  }
}