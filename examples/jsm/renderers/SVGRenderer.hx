import three.math.Box2;
import three.math.Color;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Vector3;
import three.renderers.Projector;
import three.renderers.RenderableFace;
import three.renderers.RenderableLine;
import three.renderers.RenderableSprite;
import three.Scene;
import three.core.Camera;
import three.core.Object3D;
import three.math.SRGBColorSpace;

class SVGObject extends Object3D {

    public var node:Dynamic;

    public function new(node:Dynamic) {
        super();
        this.isSVGObject = true;
        this.node = node;
    }
}

class SVGRenderer {

    public var domElement:Dynamic;
    public var autoClear:Bool;
    public var sortObjects:Bool;
    public var sortElements:Bool;
    public var overdraw:Float;
    public var outputColorSpace:SRGBColorSpace;
    public var info:Dynamic;

    private var _renderData:Dynamic;
    private var _elements:Array<Dynamic>;
    private var _lights:Array<Dynamic>;
    private var _svgWidth:Int;
    private var _svgHeight:Int;
    private var _svgWidthHalf:Float;
    private var _svgHeightHalf:Float;
    private var _v1:Vector3;
    private var _v2:Vector3;
    private var _v3:Vector3;
    private var _svgNode:Dynamic;
    private var _pathCount:Int;
    private var _precision:Dynamic;
    private var _quality:Int;
    private var _currentPath:String;
    private var _currentStyle:String;
    private var _clipBox:Box2;
    private var _color:Color;
    private var _diffuseColor:Color;
    private var _ambientLight:Color;
    private var _directionalLights:Color;
    private var _pointLights:Color;
    private var _clearColor:Color;
    private var _vector3:Vector3;
    private var _centroid:Vector3;
    private var _normal:Vector3;
    private var _normalViewMatrix:Matrix3;
    private var _viewMatrix:Matrix4;
    private var _viewProjectionMatrix:Matrix4;
    private var _svgPathPool:Array<Dynamic>;
    private var _projector:Projector;
    private var _svg:Dynamic;

    public function new() {
        // initialize properties
        // ...

        // create SVG element
        _svg = Dom.createSvg('svg');
        this.domElement = _svg;

        // create Projector instance
        _projector = new Projector();

        // initialize methods
        // ...
    }

    // methods
    // ...
}