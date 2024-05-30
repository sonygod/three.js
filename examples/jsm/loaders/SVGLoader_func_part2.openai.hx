package three.js.examples.jsm.loaders;

import three.math.Vector2;

class SVGLoader {
  static function createShapes(shapePath:Dynamic):Array<Shape> {
    // ...

    static var BIGNUMBER = 999999999;

    static var IntersectionLocationType = {
      ORIGIN: 0,
      DESTINATION: 1,
      BETWEEN: 2,
      LEFT: 3,
      RIGHT: 4,
      BEHIND: 5,
      BEYOND: 6
    };

    var classifyResult = {
      loc: IntersectionLocationType.ORIGIN,
      t: 0
    };

    function findEdgeIntersection(a0:Vector2, a1:Vector2, b0:Vector2, b1:Vector2):Dynamic {
      // ...
    }

    function classifyPoint(p:Vector2, edgeStart:Vector2, edgeEnd:Vector2):Void {
      // ...
    }

    function getIntersections(path1:Array<Vector2>, path2:Array<Vector2>):Array<Vector2> {
      // ...
    }

    function getScanlineIntersections(scanline:Array<Vector2>, boundingBox:Dynamic, paths:Array<Dynamic>):Array<Dynamic> {
      // ...
    }

    function isHoleTo(simplePath:Dynamic, allPaths:Array<Dynamic>, scanlineMinX:Float, scanlineMaxX:Float, _fillRule:String):Dynamic {
      // ...
    }

    // ...

    return shapesToReturn;
  }

  static function getStrokeStyle(width:Float, color:String, lineJoin:String, lineCap:String, miterLimit:Float):Dynamic {
    return {
      strokeColor: color,
      strokeWidth: width,
      strokeLineJoin: lineJoin,
      strokeLineCap: lineCap,
      strokeMiterLimit: miterLimit
    };
  }

  static function pointsToStroke(points:Array<Vector2>, style:Dynamic, arcDivisions:Int, minDistance:Float):BufferGeometry {
    var vertices:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];

    if (pointsToStrokeWithBuffers(points, style, arcDivisions, minDistance, vertices, normals, uvs) == 0) {
      return null;
    }

    var geometry:BufferGeometry = new BufferGeometry();
    geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
    geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

    return geometry;
  }
}