import three.js.extras.core.Box2;
import three.js.extras.core.BufferGeometry;
import three.js.extras.loaders.FileLoader;
import three.js.extras.loaders.Loader;
import three.js.extras.math.Matrix3;
import three.js.extras.math.Path;
import three.js.extras.math.Shape;
import three.js.extras.math.ShapePath;
import three.js.extras.math.ShapeUtils;
import three.js.extras.math.Vector2;
import three.js.extras.math.Vector3;

class SVGLoader extends Loader {
    public var defaultDPI:Float = 90;
    public var defaultUnit:String = 'px';

    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch (e) {
                if (onError) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(text:String) {
        var scope = this;
        var paths:Array<ShapePath> = [];
        var stylesheets:Dynamic = new Dynamic();
        var transformStack:Array<Matrix3> = [];
        var tempTransform0:Matrix3 = new Matrix3();
        var tempTransform1:Matrix3 = new Matrix3();
        var tempTransform2:Matrix3 = new Matrix3();
        var tempTransform3:Matrix3 = new Matrix3();
        var tempV2:Vector2 = new Vector2();
        var tempV3:Vector3 = new Vector3();
        var currentTransform:Matrix3 = new Matrix3();
        var xml = new DOMParser().parseFromString(text, 'image/svg+xml');
        parseNode(xml.documentElement, {
            fill: '#000',
            fillOpacity: 1,
            strokeOpacity: 1,
            strokeWidth: 1,
            strokeLineJoin: 'miter',
            strokeLineCap: 'butt',
            strokeMiterLimit: 4
        });
        return {paths: paths, xml: xml.documentElement};
    }

    private function parseNode(node:Dynamic, style:Dynamic) {
        // ...
    }

    private function parsePathNode(node:Dynamic) {
        // ...
    }

    private function parseCSSStylesheet(node:Dynamic) {
        // ...
    }

    private function parseArcCommand(path:ShapePath, rx:Float, ry:Float, x_axis_rotation:Float, large_arc_flag:Float, sweep_flag:Float, start:Vector2, end:Vector2) {
        // ...
    }

    private function svgAngle(ux:Float, uy:Float, vx:Float, vy:Float) {
        // ...
    }

    private function parseRectNode(node:Dynamic) {
        // ...
    }

    private function parsePolygonNode(node:Dynamic) {
        // ...
    }

    private function parsePolylineNode(node:Dynamic) {
        // ...
    }

    private function parseCircleNode(node:Dynamic) {
        // ...
    }

    private function parseEllipseNode(node:Dynamic) {
        // ...
    }

    private function parseLineNode(node:Dynamic) {
        // ...
    }

    private function parseStyle(node:Dynamic, style:Dynamic) {
        // ...
    }

    private function getReflection(a:Float, b:Float) {
        // ...
    }

    private function parseFloats(input:String, flags:Array<String>, stride:Int) {
        // ...
    }

    private function parseFloatWithUnits(string:String) {
        // ...
    }

    private function getNodeTransform(node:Dynamic) {
        // ...
    }

    private function parseNodeTransform(node:Dynamic) {
        // ...
    }

    private function transformPath(path:ShapePath, m:Matrix3) {
        // ...
    }

    private function isTransformFlipped(m:Matrix3) {
        // ...
    }

    private function isTransformSkewed(m:Matrix3) {
        // ...
    }

    private function getTransformScaleX(m:Matrix3) {
        // ...
    }

    private function getTransformScaleY(m:Matrix3) {
        // ...
    }

    private function eigenDecomposition(A:Float, B:Float, C:Float) {
        // ...
    }
}