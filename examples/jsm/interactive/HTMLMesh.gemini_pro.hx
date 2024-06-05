import three.core.Mesh;
import three.core.MeshBasicMaterial;
import three.geometries.PlaneGeometry;
import three.materials.CanvasTexture;
import three.math.Color;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.cameras.PerspectiveCamera;
import three.constants.LinearFilter;
import three.constants.SRGBColorSpace;

class HTMLMesh extends Mesh {
  public var dom:Dynamic;
  public var texture:HTMLTexture;
  public var onEvent:Dynamic;
  public function new(dom:Dynamic) {
    texture = new HTMLTexture(dom);
    var geometry = new PlaneGeometry(texture.image.width * 0.001, texture.image.height * 0.001);
    var material = new MeshBasicMaterial({map:texture, toneMapped:false, transparent:true});
    super(geometry, material);
    this.dom = dom;
    onEvent = function(event:Dynamic) {
      texture.dispatchDOMEvent(event);
    };
    addEventListener("mousedown", onEvent);
    addEventListener("mousemove", onEvent);
    addEventListener("mouseup", onEvent);
    addEventListener("click", onEvent);
  }
  public function dispose() {
    geometry.dispose();
    material.dispose();
    texture.dispose();
    removeEventListener("mousedown", onEvent);
    removeEventListener("mousemove", onEvent);
    removeEventListener("mouseup", onEvent);
    removeEventListener("click", onEvent);
  }
}

class HTMLTexture extends CanvasTexture {
  public var dom:Dynamic;
  public var observer:Dynamic;
  public var scheduleUpdate:Int = 0;
  public function new(dom:Dynamic) {
    super(html2canvas(dom));
    this.dom = dom;
    anisotropy = 16;
    colorSpace = SRGBColorSpace;
    minFilter = LinearFilter;
    magFilter = LinearFilter;
    observer = new MutationObserver(function() {
      if (scheduleUpdate == 0) {
        scheduleUpdate = Sys.time() + 16;
      }
    });
    observer.observe(dom, {attributes:true, childList:true, subtree:true, characterData:true});
  }
  public function dispatchDOMEvent(event:Dynamic) {
    if (event.data != null) {
      htmlevent(dom, event.type, event.data.x, event.data.y);
    }
  }
  public function update() {
    image = html2canvas(dom);
    needsUpdate = true;
    scheduleUpdate = 0;
  }
  public function dispose() {
    observer.disconnect();
    scheduleUpdate = 0;
    super.dispose();
  }
}

var canvases = new WeakMap();

function html2canvas(element:Dynamic):Dynamic {
  var range = document.createRange();
  var color = new Color();
  function Clipper(context:Dynamic) {
    var clips = [];
    var isClipping = false;
    function doClip() {
      if (isClipping) {
        isClipping = false;
        context.restore();
      }
      if (clips.length == 0) return;
      var minX = -Math.POSITIVE_INFINITY, minY = -Math.POSITIVE_INFINITY;
      var maxX = Math.POSITIVE_INFINITY, maxY = Math.POSITIVE_INFINITY;
      for (var i in 0...clips.length) {
        var clip = clips[i];
        minX = Math.max(minX, clip.x);
        minY = Math.max(minY, clip.y);
        maxX = Math.min(maxX, clip.x + clip.width);
        maxY = Math.min(maxY, clip.y + clip.height);
      }
      context.save();
      context.beginPath();
      context.rect(minX, minY, maxX - minX, maxY - minY);
      context.clip();
      isClipping = true;
    }
    return {
      add:function(clip:Dynamic) {
        clips.push(clip);
        doClip();
      },
      remove:function() {
        clips.pop();
        doClip();
      }
    };
  }
  function drawText(style:Dynamic, x:Float, y:Float, string:String) {
    if (string != "") {
      if (style.textTransform == "uppercase") {
        string = string.toUpperCase();
      }
      context.font = style.fontWeight + " " + style.fontSize + " " + style.fontFamily;
      context.textBaseline = "top";
      context.fillStyle = style.color;
      context.fillText(string, x, y + parseFloat(style.fontSize) * 0.1);
    }
  }
  function buildRectPath(x:Float, y:Float, w:Float, h:Float, r:Float) {
    if (w < 2 * r) r = w / 2;
    if (h < 2 * r) r = h / 2;
    context.beginPath();
    context.moveTo(x + r, y);
    context.arcTo(x + w, y, x + w, y + h, r);
    context.arcTo(x + w, y + h, x, y + h, r);
    context.arcTo(x, y + h, x, y, r);
    context.arcTo(x, y, x + w, y, r);
    context.closePath();
  }
  function drawBorder(style:Dynamic, which:String, x:Float, y:Float, width:Float, height:Float) {
    var borderWidth = style[which + "Width"];
    var borderStyle = style[which + "Style"];
    var borderColor = style[which + "Color"];
    if (borderWidth != "0px" && borderStyle != "none" && borderColor != "transparent" && borderColor != "rgba(0, 0, 0, 0)") {
      context.strokeStyle = borderColor;
      context.lineWidth = parseFloat(borderWidth);
      context.beginPath();
      context.moveTo(x, y);
      context.lineTo(x + width, y + height);
      context.stroke();
    }
  }
  function drawElement(element:Dynamic, style:Dynamic) {
    if (element.nodeType == Node.COMMENT_NODE || element.nodeName == "SCRIPT" || (element.style != null && element.style.display == "none")) {
      return;
    }
    var x = 0, y = 0, width = 0, height = 0;
    if (element.nodeType == Node.TEXT_NODE) {
      range.selectNode(element);
      var rect = range.getBoundingClientRect();
      x = rect.left - offset.left - 0.5;
      y = rect.top - offset.top - 0.5;
      width = rect.width;
      height = rect.height;
      drawText(style, x, y, element.nodeValue.trim());
    } else if (Std.is(element, HTMLCanvasElement)) {
      var rect = element.getBoundingClientRect();
      x = rect.left - offset.left - 0.5;
      y = rect.top - offset.top - 0.5;
      context.save();
      var dpr = window.devicePixelRatio;
      context.scale(1 / dpr, 1 / dpr);
      context.drawImage(element, x, y);
      context.restore();
    } else if (Std.is(element, HTMLImageElement)) {
      var rect = element.getBoundingClientRect();
      x = rect.left - offset.left - 0.5;
      y = rect.top - offset.top - 0.5;
      width = rect.width;
      height = rect.height;
      context.drawImage(element, x, y, width, height);
    } else {
      var rect = element.getBoundingClientRect();
      x = rect.left - offset.left - 0.5;
      y = rect.top - offset.top - 0.5;
      width = rect.width;
      height = rect.height;
      style = window.getComputedStyle(element);
      buildRectPath(x, y, width, height, parseFloat(style.borderRadius));
      var backgroundColor = style.backgroundColor;
      if (backgroundColor != "transparent" && backgroundColor != "rgba(0, 0, 0, 0)") {
        context.fillStyle = backgroundColor;
        context.fill();
      }
      var borders = ["borderTop", "borderLeft", "borderBottom", "borderRight"];
      var match = true;
      var prevBorder = null;
      for (var border in borders) {
        if (prevBorder != null) {
          match = (style[border + "Width"] == style[prevBorder + "Width"]) && (style[border + "Color"] == style[prevBorder + "Color"]) && (style[border + "Style"] == style[prevBorder + "Style"]);
        }
        if (match == false) break;
        prevBorder = border;
      }
      if (match == true) {
        var width = parseFloat(style.borderTopWidth);
        if (style.borderTopWidth != "0px" && style.borderTopStyle != "none" && style.borderTopColor != "transparent" && style.borderTopColor != "rgba(0, 0, 0, 0)") {
          context.strokeStyle = style.borderTopColor;
          context.lineWidth = width;
          context.stroke();
        }
      } else {
        drawBorder(style, "borderTop", x, y, width, 0);
        drawBorder(style, "borderLeft", x, y, 0, height);
        drawBorder(style, "borderBottom", x, y + height, width, 0);
        drawBorder(style, "borderRight", x + width, y, 0, height);
      }
      if (Std.is(element, HTMLInputElement)) {
        var accentColor = style.accentColor;
        if (accentColor == null || accentColor == "auto") accentColor = style.color;
        color.set(accentColor);
        var luminance = Math.sqrt(0.299 * (color.r ** 2) + 0.587 * (color.g ** 2) + 0.114 * (color.b ** 2));
        var accentTextColor = luminance < 0.5 ? "white" : "#111111";
        if (element.type == "radio") {
          buildRectPath(x, y, width, height, height);
          context.fillStyle = "white";
          context.strokeStyle = accentColor;
          context.lineWidth = 1;
          context.fill();
          context.stroke();
          if (element.checked) {
            buildRectPath(x + 2, y + 2, width - 4, height - 4, height);
            context.fillStyle = accentColor;
            context.strokeStyle = accentTextColor;
            context.lineWidth = 2;
            context.fill();
            context.stroke();
          }
        }
        if (element.type == "checkbox") {
          buildRectPath(x, y, width, height, 2);
          context.fillStyle = element.checked ? accentColor : "white";
          context.strokeStyle = element.checked ? accentTextColor : accentColor;
          context.lineWidth = 1;
          context.stroke();
          context.fill();
          if (element.checked) {
            var currentTextAlign = context.textAlign;
            context.textAlign = "center";
            var properties = {
              color:accentTextColor,
              fontFamily:style.fontFamily,
              fontSize:height + "px",
              fontWeight:"bold"
            };
            drawText(properties, x + (width / 2), y, "✔");
            context.textAlign = currentTextAlign;
          }
        }
        if (element.type == "range") {
          var min = parseFloat(element.min);
          var max = parseFloat(element.max);
          var value = parseFloat(element.value);
          var position = ((value - min) / (max - min)) * (width - height);
          buildRectPath(x, y + (height / 4), width, height / 2, height / 4);
          context.fillStyle = accentTextColor;
          context.strokeStyle = accentColor;
          context.lineWidth = 1;
          context.fill();
          context.stroke();
          buildRectPath(x, y + (height / 4), position + (height / 2), height / 2, height / 4);
          context.fillStyle = accentColor;
          context.fill();
          buildRectPath(x + position, y, height, height, height / 2);
          context.fillStyle = accentColor;
          context.fill();
        }
        if (element.type == "color" || element.type == "text" || element.type == "number") {
          clipper.add({x:x, y:y, width:width, height:height});
          drawText(style, x + parseInt(style.paddingLeft), y + parseInt(style.paddingTop), element.value);
          clipper.remove();
        }
      }
    }
    var isClipping = style.overflow == "auto" || style.overflow == "hidden";
    if (isClipping) clipper.add({x:x, y:y, width:width, height:height});
    for (var i in 0...element.childNodes.length) {
      drawElement(element.childNodes[i], style);
    }
    if (isClipping) clipper.remove();
  }
  var offset = element.getBoundingClientRect();
  var canvas = canvases.get(element);
  if (canvas == null) {
    canvas = document.createElement("canvas");
    canvas.width = offset.width;
    canvas.height = offset.height;
    canvases.set(element, canvas);
  }
  var context = canvas.getContext("2d");
  var clipper = new Clipper(context);
  context.clearRect(0, 0, canvas.width, canvas.height);
  drawElement(element);
  return canvas;
}

function htmlevent(element:Dynamic, event:String, x:Float, y:Float) {
  var mouseEventInit = {
    clientX:(x * element.offsetWidth) + element.offsetLeft,
    clientY:(y * element.offsetHeight) + element.offsetTop,
    view:element.ownerDocument.defaultView
  };
  window.dispatchEvent(new MouseEvent(event, mouseEventInit));
  var rect = element.getBoundingClientRect();
  x = x * rect.width + rect.left;
  y = y * rect.height + rect.top;
  function traverse(element:Dynamic) {
    if (element.nodeType != Node.TEXT_NODE && element.nodeType != Node.COMMENT_NODE) {
      var rect = element.getBoundingClientRect();
      if (x > rect.left && x < rect.right && y > rect.top && y < rect.bottom) {
        element.dispatchEvent(new MouseEvent(event, mouseEventInit));
        if (Std.is(element, HTMLInputElement) && element.type == "range" && (event == "mousedown" || event == "click")) {
          var min = parseFloat(element.min);
          var max = parseFloat(element.max);
          var width = rect.width;
          var offsetX = x - rect.x;
          var proportion = offsetX / width;
          element.value = min + (max - min) * proportion;
          element.dispatchEvent(new InputEvent("input", {bubbles:true}));
        }
      }
      for (var i in 0...element.childNodes.length) {
        traverse(element.childNodes[i]);
      }
    }
  }
  traverse(element);
}

class MutationObserver {
  public var observer:Dynamic;
  public function new(callback:Dynamic) {
    observer = js.Browser.window.MutationObserver.new(callback);
  }
  public function observe(target:Dynamic, options:Dynamic) {
    observer.observe(target, options);
  }
  public function disconnect() {
    observer.disconnect();
  }
}

class MouseEvent {
  public var event:Dynamic;
  public function new(type:String, init:Dynamic) {
    event = js.Browser.window.MouseEvent.new(type, init);
  }
}

class InputEvent {
  public var event:Dynamic;
  public function new(type:String, init:Dynamic) {
    event = js.Browser.window.InputEvent.new(type, init);
  }
}

class WeakMap {
  public var map:Dynamic;
  public function new() {
    map = js.Browser.window.WeakMap.new();
  }
  public function get(key:Dynamic):Dynamic {
    return map.get(key);
  }
  public function set(key:Dynamic, value:Dynamic):Void {
    map.set(key, value);
  }
}

class Sys {
  static public function time():Int {
    return js.Browser.window.performance.now();
  }
}