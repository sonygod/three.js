import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import three.math.Color;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.ShapeUtils;

class ShapePath {

    public var type:String = 'ShapePath';
    public var color:Color = new Color();
    public var subPaths:Array<Path> = [];
    public var currentPath:Path = null;

    public function new() {
    }

    public function moveTo(x:Float, y:Float):ShapePath {
        this.currentPath = new Path();
        this.subPaths.push(this.currentPath);
        this.currentPath.moveTo(x, y);
        return this;
    }

    public function lineTo(x:Float, y:Float):ShapePath {
        this.currentPath.lineTo(x, y);
        return this;
    }

    public function quadraticCurveTo(aCPx:Float, aCPy:Float, aX:Float, aY:Float):ShapePath {
        this.currentPath.quadraticCurveTo(aCPx, aCPy, aX, aY);
        return this;
    }

    public function bezierCurveTo(aCP1x:Float, aCP1y:Float, aCP2x:Float, aCP2y:Float, aX:Float, aY:Float):ShapePath {
        this.currentPath.bezierCurveTo(aCP1x, aCP1y, aCP2x, aCP2y, aX, aY);
        return this;
    }

    public function splineThru(pts:Array<Dynamic>):ShapePath {
        this.currentPath.splineThru(pts);
        return this;
    }

    public function toShapes(isCCW:Bool):Array<Shape> {
        // The function toShapes is somewhat complex and requires the use of Canvas API which is not directly available in Haxe.
        // Therefore, this function is left as a placeholder. You'll need to implement it yourself or use a library that provides similar functionality.
        return [];
    }

}