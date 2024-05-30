class SVGLoader {
    static var BIGNUMBER:Float = 999999999;

    static var IntersectionLocationType = {
        ORIGIN: 0,
        DESTINATION: 1,
        BETWEEN: 2,
        LEFT: 3,
        RIGHT: 4,
        BEHIND: 5,
        BEYOND: 6
    };

    static var classifyResult = {
        loc: IntersectionLocationType.ORIGIN,
        t: 0
    };

    static function findEdgeIntersection(a0:Vector2, a1:Vector2, b0:Vector2, b1:Vector2):Dynamic {
        // ...
    }

    static function classifyPoint(p:Vector2, edgeStart:Vector2, edgeEnd:Vector2):Void {
        // ...
    }

    static function getIntersections(path1:Array<Vector2>, path2:Array<Vector2>):Array<Vector2> {
        // ...
    }

    static function getScanlineIntersections(scanline:Array<Vector2>, boundingBox:Box2, paths:Array<Dynamic>):Array<Dynamic> {
        // ...
    }

    static function isHoleTo(simplePath:Dynamic, allPaths:Array<Dynamic>, scanlineMinX:Float, scanlineMaxX:Float, _fillRule:String):Dynamic {
        // ...
    }

    static function createShapes(shapePath:Dynamic):Array<Shape> {
        // ...
    }

    static function getStrokeStyle(width:Float, color:String, lineJoin:String, lineCap:String, miterLimit:Float):Dynamic {
        // ...
    }

    static function pointsToStroke(points:Array<Vector2>, style:Dynamic, arcDivisions:Int, minDistance:Float):BufferGeometry {
        // ...
    }
}