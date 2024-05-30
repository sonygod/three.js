package three.js.playground;

import js.html.DOMElement;
import js.html.Document;
import js.html.Event;
import js.html.MouseEvent;

class SplitscreenManager {
  public var editor:Dynamic;
  public var renderer:Dynamic;
  public var composer:Dynamic;
  public var gutter:DOMElement;
  public var gutterMoving:Bool;
  public var gutterOffset:Float;

  public function new(editor:Dynamic) {
    this.editor = editor;
    this.renderer = editor.renderer;
    this.composer = editor.composer;
    this.gutter = null;
    this.gutterMoving = false;
    this.gutterOffset = 0.6;
  }

  public function setSplitview(value:Bool) {
    var nodeDOM:DOMElement = editor.domElement;
    var rendererContainer:DOMElement = renderer.domElement.parentNode;

    if (value) {
      addGutter(rendererContainer, nodeDOM);
    } else {
      removeGutter(rendererContainer, nodeDOM);
    }
  }

  private function addGutter(rendererContainer:DOMElement, nodeDOM:DOMElement) {
    rendererContainer.style.zIndex = "20";

    gutter = Document.createElement("f-gutter");
    nodeDOM.parentNode.appendChild(gutter);

    var onGutterMovement = function() {
      var offset:Float = gutterOffset;
      gutter.style.left = Std.string(100 * offset) + "%";
      rendererContainer.style.left = Std.string(100 * offset) + "%";
      rendererContainer.style.width = Std.string(100 * (1 - offset)) + "%";
      nodeDOM.style.width = Std.string(100 * offset) + "%";
    };

    gutter.addEventListener("mousedown", function(_), false);
    gutterMoving = true;

    Document.addEventListener("mousemove", function(event:MouseEvent) {
      if (gutter != null && gutterMoving) {
        gutterOffset = Math.max(0, Math.min(1, event.clientX / window.innerWidth));
        onGutterMovement();
      }
    }, false);

    Document.addEventListener("mouseup", function(_), false);
    gutterMoving = false;

    onGutterMovement();
  }

  private function removeGutter(rendererContainer:DOMElement, nodeDOM:DOMElement) {
    rendererContainer.style.zIndex = "0";
    gutter.remove();
    gutter = null;

    rendererContainer.style.left = "0%";
    rendererContainer.style.width = "100%";
    nodeDOM.style.width = "100%";
  }
}