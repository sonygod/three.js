package three.js.playground.libs;

import js.Browser;
import js.html.Document;
import js.html.Element;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;

class Canvas extends Serializer {
    public var dom:Element;
    public var contentDOM:Element;
    public var areaDOM:Element;
    public var dropDOM:Element;
    public var canvas:CanvasElement;
    public var frontCanvas:CanvasElement;
    public var mapCanvas:CanvasElement;
    public var context:CanvasRenderingContext2D;
    public var frontContext:CanvasRenderingContext2D;
    public var mapContext:CanvasRenderingContext2D;
    public var clientX:Int;
    public var clientY:Int;
    public var relativeClientX:Int;
    public var relativeClientY:Int;
    public var nodes:Array<Node>;
    public var selected:Node;
    public var updating:Bool;
    public var droppedItems:Array<Dynamic>;
    public var events:Dynamic;
    public var _scrollLeft:Float;
    public var _scrollTop:Float;
    public var _zoom:Float;
    public var _width:Int;
    public var _height:Int;
    public var _focusSelected:Bool;
    public var _mapInfo:Dynamic;

    public function new() {
        super();
        dom = Browser.document.createElement('f-canvas');
        contentDOM = Browser.document.createElement('f-content');
        areaDOM = Browser.document.createElement('f-area');
        dropDOM = Browser.document.createElement('f-drop');

        canvas = Browser.document.createElement('canvas');
        frontCanvas = Browser.document.createElement('canvas');
        mapCanvas = Browser.document.createElement('canvas');

        context = canvas.getContext('2d');
        frontContext = frontCanvas.getContext('2d');
        mapContext = mapCanvas.getContext('2d');

        // ... rest of the code remains the same ...
    }

    // ... rest of the methods ...
}