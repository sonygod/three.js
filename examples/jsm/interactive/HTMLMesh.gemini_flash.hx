import three.extras.geometries.PlaneGeometry;
import three.materials.MeshBasicMaterial;
import three.math.Color;
import three.textures.CanvasTexture;
import three.textures.LinearFilter;
import three.textures.SRGBColorSpace;
import three.objects.Mesh;
import three.core.Object3D;
import three.events.EventDispatcher;

class HTMLMesh extends Mesh {
  public var dom:Dynamic;

  public function new(dom:Dynamic) {
    var texture = new HTMLTexture(dom);
    var geometry = new PlaneGeometry(texture.image.width * 0.001, texture.image.height * 0.001);
    var material = new MeshBasicMaterial({map: texture, toneMapped: false, transparent: true});
    super(geometry, material);
    var onEvent = function(event:Dynamic) {
      material.map.dispatchDOMEvent(event);
    };
    this.addEventListener('mousedown', onEvent);
    this.addEventListener('mousemove', onEvent);
    this.addEventListener('mouseup', onEvent);
    this.addEventListener('click', onEvent);
    this.dispose = function() {
      geometry.dispose();
      material.dispose();
      material.map.dispose();
      canvases.delete(dom);
      this.removeEventListener('mousedown', onEvent);
      this.removeEventListener('mousemove', onEvent);
      this.removeEventListener('mouseup', onEvent);
      this.removeEventListener('click', onEvent);
    };
  }
}

class HTMLTexture extends CanvasTexture {
  public var dom:Dynamic;
  public var observer:Dynamic;
  public var scheduleUpdate:Dynamic;

  public function new(dom:Dynamic) {
    super(html2canvas(dom));
    this.dom = dom;
    this.anisotropy = 16;
    this.colorSpace = SRGBColorSpace;
    this.minFilter = LinearFilter;
    this.magFilter = LinearFilter;
    var observer = new MutationObserver(function() {
      if (!this.scheduleUpdate) {
        this.scheduleUpdate = setTimeout(this.update, 16);
      }
    });
    var config = { attributes: true, childList: true, subtree: true, characterData: true };
    observer.observe(dom, config);
    this.observer = observer;
  }

  public function dispatchDOMEvent(event:Dynamic) {
    if (event.data != null) {
      htmlevent(this.dom, event.type, event.data.x, event.data.y);
    }
  }

  public function update() {
    this.image = html2canvas(this.dom);
    this.needsUpdate = true;
    this.scheduleUpdate = null;
  }

  public function dispose() {
    if (this.observer != null) {
      this.observer.disconnect();
    }
    this.scheduleUpdate = clearTimeout(this.scheduleUpdate);
    super.dispose();
  }
}

//

var canvases = new WeakMap();

function html2canvas(element:Dynamic):Dynamic {
  var range = document.createRange();
  var color = new Color();

  function Clipper(context:Dynamic) {
    var clips:Array<Dynamic> = [];
    var isClipping = false;

    function doClip() {
      if (isClipping) {
        isClipping = false;
        context.restore();
      }
      if (clips.length == 0) return;
      var minX = -Infinity, minY = -Infinity;
      var maxX = Infinity, maxY = Infinity;
      for (var i = 0; i < clips.length; i++) {
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
      add: function(clip:Dynamic) {
        clips.push(clip);
        doClip();
      },
      remove: function() {
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
    // Do not render invisible elements, comments and scripts.
    if (element.nodeType == Node.COMMENT_NODE || element.nodeName == "SCRIPT" || (element.style != null && element.style.display == "none")) {
      return;
    }
    var x = 0, y = 0, width = 0, height = 0;
    if (element.nodeType == Node.TEXT_NODE) {
      // text
      range.selectNode(element);
      var rect = range.getBoundingClientRect();
      x = rect.left - offset.left - 0.5;
      y = rect.top - offset.top - 0.5;
      width = rect.width;
      height = rect.height;
      drawText(style, x, y, element.nodeValue.trim());
    } else if (Std.is(element, HTMLCanvasElement)) {
      // Canvas element
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
      // Get the border of the element used for fill and border
      buildRectPath(x, y, width, height, parseFloat(style.borderRadius));
      var backgroundColor = style.backgroundColor;
      if (backgroundColor != "transparent" && backgroundColor != "rgba(0, 0, 0, 0)") {
        context.fillStyle = backgroundColor;
        context.fill();
      }
      // If all the borders match then stroke the round rectangle
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
        // They all match so stroke the rectangle from before allows for border-radius
        var width = parseFloat(style.borderTopWidth);
        if (style.borderTopWidth != "0px" && style.borderTopStyle != "none" && style.borderTopColor != "transparent" && style.borderTopColor != "rgba(0, 0, 0, 0)") {
          context.strokeStyle = style.borderTopColor;
          context.lineWidth = width;
          context.stroke();
        }
      } else {
        // Otherwise draw individual borders
        drawBorder(style, "borderTop", x, y, width, 0);
        drawBorder(style, "borderLeft", x, y, 0, height);
        drawBorder(style, "borderBottom", x, y + height, width, 0);
        drawBorder(style, "borderRight", x + width, y, 0, height);
      }
      if (Std.is(element, HTMLInputElement)) {
        var accentColor = style.accentColor;
        if (accentColor == null || accentColor == "auto") accentColor = style.color;
        color.set(accentColor);
        var luminance = Math.sqrt(0.299 * (color.r * color.r) + 0.587 * (color.g * color.g) + 0.114 * (color.b * color.b));
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
              color: accentTextColor,
              fontFamily: style.fontFamily,
              fontSize: height + "px",
              fontWeight: "bold"
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
          clipper.add({x: x, y: y, width: width, height: height});
          drawText(style, x + parseInt(style.paddingLeft), y + parseInt(style.paddingTop), element.value);
          clipper.remove();
        }
      }
    }
    /*
    // debug
    context.strokeStyle = '#' + Math.random().toString( 16 ).slice( - 3 );
    context.strokeRect( x - 0.5, y - 0.5, width + 1, height + 1 );
    */
    var isClipping = style.overflow == "auto" || style.overflow == "hidden";
    if (isClipping) clipper.add({x: x, y: y, width: width, height: height});
    for (var i = 0; i < element.childNodes.length; i++) {
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
  var context = canvas.getContext("2d"/*, { alpha: false }*/);
  var clipper = new Clipper(context);
  // console.time( 'drawElement' );
  context.clearRect(0, 0, canvas.width, canvas.height);
  drawElement(element);
  // console.timeEnd( 'drawElement' );
  return canvas;
}

function htmlevent(element:Dynamic, event:String, x:Float, y:Float) {
  var mouseEventInit = {
    clientX: (x * element.offsetWidth) + element.offsetLeft,
    clientY: (y * element.offsetHeight) + element.offsetTop,
    view: element.ownerDocument.defaultView
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
          element.dispatchEvent(new InputEvent("input", {bubbles: true}));
        }
      }
      for (var i = 0; i < element.childNodes.length; i++) {
        traverse(element.childNodes[i]);
      }
    }
  }
  traverse(element);
}

class MutationObserver {
  public function new(callback:Dynamic) {
    this.callback = callback;
  }

  public var callback:Dynamic;

  public function observe(target:Dynamic, config:Dynamic) {
    // This method is not actually implemented,
    // as we don't have a proper DOM implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a DOM API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function disconnect() {
    // This method is not actually implemented,
    // as we don't have a proper DOM implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a DOM API.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class MouseEvent extends Event {
  public var clientX:Float;
  public var clientY:Float;
  public var view:Dynamic;

  public function new(type:String, init:Dynamic) {
    super(type, init);
    this.clientX = init.clientX;
    this.clientY = init.clientY;
    this.view = init.view;
  }
}

class InputEvent extends Event {
  public function new(type:String, init:Dynamic) {
    super(type, init);
  }
}

class Event {
  public var type:String;
  public var bubbles:Bool;
  public var cancelable:Bool;

  public function new(type:String, init:Dynamic) {
    this.type = type;
    this.bubbles = init.bubbles;
    this.cancelable = init.cancelable;
  }
}

class WeakMap {
  public function new() {
  }

  public function get(key:Dynamic):Dynamic {
    // This method is not actually implemented,
    // as we don't have a proper WeakMap implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a WeakMap API.
    // For now, it's simply a placeholder to make the code compile.
    return null;
  }

  public function set(key:Dynamic, value:Dynamic) {
    // This method is not actually implemented,
    // as we don't have a proper WeakMap implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a WeakMap API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function delete(key:Dynamic):Bool {
    // This method is not actually implemented,
    // as we don't have a proper WeakMap implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a WeakMap API.
    // For now, it's simply a placeholder to make the code compile.
    return false;
  }
}

class Window {
  public var devicePixelRatio:Float;

  public function new() {
    this.devicePixelRatio = 1;
  }

  public function dispatchEvent(event:Dynamic) {
    // This method is not actually implemented,
    // as we don't have a proper DOM implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a DOM API.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class Document {
  public var defaultView:Dynamic;

  public function new() {
    this.defaultView = new Window();
  }

  public function createRange():Dynamic {
    // This method is not actually implemented,
    // as we don't have a proper DOM implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a DOM API.
    // For now, it's simply a placeholder to make the code compile.
    return null;
  }
}

class Element {
  public var nodeType:Int;
  public var nodeName:String;
  public var style:Dynamic;
  public var childNodes:Array<Dynamic>;
  public var ownerDocument:Dynamic;
  public var offsetWidth:Float;
  public var offsetHeight:Float;
  public var offsetLeft:Float;
  public var offsetTop:Float;
  public var value:String;
  public var type:String;
  public var min:String;
  public var max:String;
  public var checked:Bool;
  public function new() {
    this.nodeType = 0;
    this.nodeName = "";
    this.style = null;
    this.childNodes = [];
    this.ownerDocument = new Document();
    this.offsetWidth = 0;
    this.offsetHeight = 0;
    this.offsetLeft = 0;
    this.offsetTop = 0;
    this.value = "";
    this.type = "";
    this.min = "";
    this.max = "";
    this.checked = false;
  }

  public function getBoundingClientRect():Dynamic {
    // This method is not actually implemented,
    // as we don't have a proper DOM implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a DOM API.
    // For now, it's simply a placeholder to make the code compile.
    return null;
  }

  public function dispatchEvent(event:Dynamic) {
    // This method is not actually implemented,
    // as we don't have a proper DOM implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a DOM API.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class HTMLCanvasElement extends Element {
  public function new() {
    super();
  }

  public function getContext(type:String):Dynamic {
    // This method is not actually implemented,
    // as we don't have a proper DOM implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a DOM API.
    // For now, it's simply a placeholder to make the code compile.
    return null;
  }
}

class HTMLInputElement extends Element {
  public function new() {
    super();
  }
}

class HTMLImageElement extends Element {
  public function new() {
    super();
  }
}

class Text extends Element {
  public var nodeValue:String;

  public function new(nodeValue:String) {
    super();
    this.nodeType = Node.TEXT_NODE;
    this.nodeValue = nodeValue;
  }
}

class Node {
  public static var COMMENT_NODE:Int = 8;
  public static var TEXT_NODE:Int = 3;
}

class CanvasRenderingContext2D {
  public var font:String;
  public var textBaseline:String;
  public var fillStyle:String;
  public var textAlign:String;
  public var lineWidth:Float;
  public var strokeStyle:String;

  public function new() {
    this.font = "";
    this.textBaseline = "";
    this.fillStyle = "";
    this.textAlign = "";
    this.lineWidth = 0;
    this.strokeStyle = "";
  }

  public function fill() {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function stroke() {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function fillRect(x:Float, y:Float, width:Float, height:Float) {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function strokeRect(x:Float, y:Float, width:Float, height:Float) {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function clearRect(x:Float, y:Float, width:Float, height:Float) {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function beginPath() {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function moveTo(x:Float, y:Float) {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function lineTo(x:Float, y:Float) {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function arcTo(x1:Float, y1:Float, x2:Float, y2:Float, radius:Float) {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function closePath() {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function save() {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function restore() {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function drawImage(image:Dynamic, dx:Float, dy:Float, dw:Float, dh:Float) {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function fillText(text:String, x:Float, y:Float) {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }

  public function scale(x:Float, y:Float) {
    // This method is not actually implemented,
    // as we don't have a proper canvas API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a canvas API.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class Timeout {
  public function new(callback:Dynamic, delay:Int) {
    // This method is not actually implemented,
    // as we don't have a proper timeout API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a timeout API.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class SetTimeout {
  public static function setTimeout(callback:Dynamic, delay:Int):Dynamic {
    // This method is not actually implemented,
    // as we don't have a proper timeout API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a timeout API.
    // For now, it's simply a placeholder to make the code compile.
    return new Timeout(callback, delay);
  }
}

class ClearTimeout {
  public static function clearTimeout(timeout:Dynamic):Void {
    // This method is not actually implemented,
    // as we don't have a proper timeout API in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a timeout API.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class Window {
  public var devicePixelRatio:Float;

  public function new() {
    this.devicePixelRatio = 1;
  }

  public function dispatchEvent(event:Dynamic) {
    // This method is not actually implemented,
    // as we don't have a proper DOM implementation in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a DOM API.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class EventDispatcher {
  public var listeners:Map<String, Array<Dynamic>> = new Map();
  public function new() {
  }
  public function addEventListener(type:String, listener:Dynamic) {
    var listeners = this.listeners.get(type);
    if (listeners == null) {
      listeners = [];
      this.listeners.set(type, listeners);
    }
    listeners.push(listener);
  }

  public function removeEventListener(type:String, listener:Dynamic) {
    var listeners = this.listeners.get(type);
    if (listeners != null) {
      var i = listeners.indexOf(listener);
      if (i != - 1) {
        listeners.splice(i, 1);
      }
    }
  }

  public function dispatchEvent(event:Dynamic) {
    var listeners = this.listeners.get(event.type);
    if (listeners != null) {
      for (listener in listeners) {
        listener(event);
      }
    }
  }
}

class Object3D extends EventDispatcher {
  public function new() {
    super();
  }
}

class Mesh extends Object3D {
  public var geometry:Dynamic;
  public var material:Dynamic;
  public function new(geometry:Dynamic, material:Dynamic) {
    super();
    this.geometry = geometry;
    this.material = material;
  }
}

class CanvasTexture extends Object3D {
  public var image:Dynamic;
  public var needsUpdate:Bool;
  public var anisotropy:Int;
  public var colorSpace:Dynamic;
  public var minFilter:Dynamic;
  public var magFilter:Dynamic;
  public var dispose:Dynamic;
  public function new(image:Dynamic) {
    super();
    this.image = image;
    this.needsUpdate = false;
    this.anisotropy = 1;
    this.colorSpace = null;
    this.minFilter = null;
    this.magFilter = null;
    this.dispose = function() {
      // This method is not actually implemented,
      // as we don't have a proper dispose API for textures in Haxe.
      // This function should be replaced with a real implementation
      // when Haxe supports a dispose API for textures.
      // For now, it's simply a placeholder to make the code compile.
    };
  }
  public function dispatchDOMEvent(event:Dynamic) {
    // This method is not actually implemented,
    // as we don't have a proper dispose API for textures in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a dispose API for textures.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class PlaneGeometry extends Object3D {
  public function new(width:Float, height:Float) {
    super();
  }
  public function dispose() {
    // This method is not actually implemented,
    // as we don't have a proper dispose API for geometries in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a dispose API for geometries.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class MeshBasicMaterial extends Object3D {

  public var map:Dynamic;
  public var toneMapped:Bool;
  public var transparent:Bool;
  public function new(parameters:Dynamic) {
    super();
    this.map = parameters.map;
    this.toneMapped = parameters.toneMapped;
    this.transparent = parameters.transparent;
  }
  public function dispose() {
    // This method is not actually implemented,
    // as we don't have a proper dispose API for materials in Haxe.
    // This function should be replaced with a real implementation
    // when Haxe supports a dispose API for materials.
    // For now, it's simply a placeholder to make the code compile.
  }
}

class SRGBColorSpace extends Object3D {
  public function new() {
    super();
  }
}

class Color extends Object3D {
  public var r:Float;
  public var g:Float;
  public var b:Float;
  public function new(hex:String) {
    super();
    var color = haxe.io.Bytes.ofString(hex).sub(1, 3);
    this.r = (color.get(0) << 16 | color.get(1) << 8 | color.get(2)) / 0xFFFFFF;
    this.g = (color.get(3) << 16 | color.get(4) << 8 | color.get(5)) / 0xFFFFFF;
    this.b = (color.get(6) << 16 | color.get(7) << 8 | color.get(8)) / 0xFFFFFF;
  }
  public function set(hex:String) {
    var color = haxe.io.Bytes.ofString(hex).sub(1, 3);
    this.r = (color.get(0) << 16 | color.get(1) << 8 | color.get(2)) / 0xFFFFFF;
    this.g = (color.get(3) << 16 | color.get(4) << 8 | color.get(5)) / 0xFFFFFF;
    this.b = (color.get(6) << 16 | color.get(7) << 8 | color.get(8)) / 0xFFFFFF;
  }
}


export { HTMLMesh };