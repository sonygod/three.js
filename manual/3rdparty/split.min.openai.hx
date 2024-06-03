package three.js.manual.3rdparty;

import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.Node;
import js.html.Window;

class Split {
  static var win = js.Browser.window;
  static var doc = js.Browser.document;

  static function addEvent(node:Node, type:String, listener:Dynamic) {
    if (node.addEventListener != null) {
      node.addEventListener(type, listener);
    } else {
      node.attachEvent('on' + type, listener);
    }
  }

  static function removeEvent(node:Node, type:String, listener:Dynamic) {
    if (node.removeEventListener != null) {
      node.removeEventListener(type, listener);
    } else {
      node.detachEvent('on' + type, listener);
    }
  }

  static function getRect(element:Element):{left:Float, top:Float, width:Float, height:Float} {
    return element.getBoundingClientRect();
  }

  static function isString(obj:Dynamic):Bool {
    return js.TypeOF(obj) == "string";
  }

  static function querySelector(selector:String):Element {
    return doc.querySelector(selector);
  }

  static function calcPrefix():String {
    var div = doc.createElement("div");
    var prefixes = ["", "-webkit-", "-moz-", "-o-"];
    for (prefix in prefixes) {
      div.style.cssText = 'width:' + prefix + 'calc(9px)';
      if (div.style.length > 0) {
        return prefix + 'calc';
      }
    }
    return '';
  }

  static function split(element:Element, sizes:Array<Float>, options:Dynamic) {
    var guts = [];
    var elements = [for (i in 0...sizes.length) element];
    var directions = [for (i in 0...sizes.length) options.direction || "horizontal"];
    var gutters = [for (i in 0...(sizes.length - 1)) createGutter(i + 1, options.direction)];
    var minSizes = [for (i in 0...sizes.length) options.minSize || 100];
    var snapOffsets = [for (i in 0...sizes.length) options.snapOffset || 30];
    var cursors = [for (i in 0...sizes.length) options.cursor || (options.direction == "horizontal" ? "ew-resize" : "ns-resize")];

    for (i in 0...sizes.length) {
      var el = elements[i];
      el.style.flexGrow = '1';
      el.style.flexBasis = '0px';
      if (i > 0) {
        var gutter = gutters[i - 1];
        addEvent(gutter, 'mousedown', startDrag.bind(this, i));
        addEvent(gutter, 'touchstart', startDrag.bind(this, i));
      }
    }

    function startDrag(i:Int, e:Event) {
      e.preventDefault();
      var el = elements[i];
      var gutter = gutters[i - 1];
      addEvent(win, 'mouseup', stopDrag);
      addEvent(win, 'touchend', stopDrag);
      addEvent(win, 'touchcancel', stopDrag);
      addEvent(gutter, 'mousemove', move);
      addEvent(gutter, 'touchmove', move);
      el.style.userSelect = 'none';
      el.style.webkitUserSelect = 'none';
      el.style.MozUserSelect = 'none';
      gutter.style.cursor = cursors[i];
    }

    function stopDrag(e:Event) {
      removeEvent(win, 'mouseup', stopDrag);
      removeEvent(win, 'touchend', stopDrag);
      removeEvent(win, 'touchcancel', stopDrag);
      removeEvent(gutter, 'mousemove', move);
      removeEvent(gutter, 'touchmove', move);
      el.style.userSelect = '';
      el.style.webkitUserSelect = '';
      el.style.MozUserSelect = '';
      gutter.style.cursor = '';
    }

    function move(e:Event) {
      var rect = getRect(elements[i]);
      var offset = e.clientX - rect.left;
      var size = offset - snapOffsets[i];
      if (size < minSizes[i]) {
        size = minSizes[i];
      } else if (size > sizes[i] - minSizes[i + 1] - snapOffsets[i]) {
        size = sizes[i] - minSizes[i + 1] - snapOffsets[i];
      }
      el.style.flexBasis = size + 'px';
    }

    function setSizes(newSizes:Array<Float>) {
      for (i in 0...newSizes.length) {
        elements[i].style.flexBasis = newSizes[i] + 'px';
      }
    }

    function destroy() {
      for (i in 0...gutters.length) {
        gutters[i].parentNode.removeChild(gutters[i]);
      }
    }

    return {
      setSizes: setSizes,
      destroy: destroy
    };
  }

  static function createGutter(i:Int, direction:String):Element {
    var gutter = doc.createElement("div");
    gutter.className = 'gutter gutter-' + direction;
    return gutter;
  }
}