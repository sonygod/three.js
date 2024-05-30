class SVGLoader {
  static function createShapes(shapePath:Dynamic):Dynamic {
    const BIGNUMBER:Float = 999999999.0;

    class IntersectionLocationType {
      static var ORIGIN:Int = 0;
      static var DESTINATION:Int = 1;
      static var BETWEEN:Int = 2;
      static var LEFT:Int = 3;
      static var RIGHT:Int = 4;
      static var BEHIND:Int = 5;
      static var BEYOND:Int = 6;
    }

    var classifyResult:Dynamic = {
      loc: IntersectionLocationType.ORIGIN,
      t: 0
    };

    function findEdgeIntersection(a0:Dynamic, a1:Dynamic, b0:Dynamic, b1:Dynamic):Dynamic {
      // ...
    }

    function classifyPoint(p:Dynamic, edgeStart:Dynamic, edgeEnd:Dynamic):Void {
      // ...
    }

    function getIntersections(path1:Dynamic, path2:Dynamic):Dynamic {
      // ...
    }

    function getScanlineIntersections(scanline:Dynamic, boundingBox:Dynamic, paths:Dynamic):Dynamic {
      // ...
    }

    function isHoleTo(simplePath:Dynamic, allPaths:Dynamic, scanlineMinX:Float, scanlineMaxX:Float, _fillRule:String):Dynamic {
      // ...
    }

    // ...

    return shapesToReturn;
  }

  static function getStrokeStyle(width:Float, color:String, lineJoin:String, lineCap:String, miterLimit:Float):Dynamic {
    // ...
  }

  static function pointsToStroke(points:Dynamic, style:Dynamic, arcDivisions:Int, minDistance:Float):Dynamic {
    // ...
  }
}