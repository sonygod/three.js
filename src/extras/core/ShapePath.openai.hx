import js.three.math.Color;
import js.three.extras.core.Path;
import js.three.extras.core.Shape;
import js.three.extras.ShapeUtils;
import js.Lib;

class ShapePath {
  public var type:String;
  public var color:Color;
  public var subPaths:Array<Dynamic>;
  public var currentPath:Path;
  
  public function new() {
    this.type = 'ShapePath';
    this.color = new Color();
    this.subPaths = [];
    this.currentPath = null;
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
    function toShapesNoHoles(inSubpaths:Array<Path>):Array<Shape> {
      var shapes:Array<Shape> = [];
      var i = 0;
      var l = inSubpaths.length;
      while (i < l) {
        var tmpPath = inSubpaths[i];
        var tmpShape = new Shape();
        tmpShape.curves = tmpPath.curves;
        shapes.push(tmpShape);
        i++;
      }
      return shapes;
    }
    
    function isPointInsidePolygon(inPt:Dynamic, inPolygon:Array<Dynamic>):Bool {
      var polyLen = inPolygon.length;
      var inside = false;
      var p = polyLen - 1;
      var q = 0;
      while (q < polyLen) {
        var edgeLowPt = inPolygon[p];
        var edgeHighPt = inPolygon[q];
        var edgeDx = edgeHighPt.x - edgeLowPt.x;
        var edgeDy = edgeHighPt.y - edgeLowPt.y;
        
        if (Math.abs(edgeDy) > Number.EPSILON) {
          if (edgeDy < 0) {
            edgeLowPt = inPolygon[q];
            edgeDx = -edgeDx;
            edgeHighPt = inPolygon[p];
            edgeDy = -edgeDy;
          }
          
          if ((inPt.y < edgeLowPt.y) || (inPt.y > edgeHighPt.y))
            continue;
          
          if (inPt.y === edgeLowPt.y) {
            if (inPt.x === edgeLowPt.x) return true;
          } else {
            var perpEdge = edgeDy * (inPt.x - edgeLowPt.x) - edgeDx * (inPt.y - edgeLowPt.y);
            if (perpEdge === 0) return true;
            if (perpEdge < 0) continue;
            inside = !inside;
          }
        } else {
          if (inPt.y !== edgeLowPt.y) continue;
          if (((edgeHighPt.x <= inPt.x) && (inPt.x <= edgeLowPt.x)) || 
              ((edgeLowPt.x <= inPt.x) && (inPt.x <= edgeHighPt.x)))
                return true;
        }
        q++;
        p = q - 1;
      }
      return inside;
    }
    
    var isClockWise = ShapeUtils.isClockWise;
    var subPaths:Array<Path> = this.subPaths;
    if (subPaths.length === 0) return [];
    var solid:Bool;
    var tmpPath:Path;
    var tmpShape:Shape;
    var shapes:Array<Shape> = [];
    if (subPaths.length === 1) {
      tmpPath = subPaths[0];
      tmpShape = new Shape();
      tmpShape.curves = tmpPath.curves;
      shapes.push(tmpShape);
      return shapes;
    }
    var holesFirst = !isClockWise(subPaths[0].getPoints());
    holesFirst = isCCW ? !holesFirst : holesFirst;
    var betterShapeHoles:Array<Array<Dynamic>> = [];
    var newShapes:Array<Array<Dynamic>> = [];
    var newShapeHoles:Array<Array<Dynamic>> = [];
    var mainIdx = 0;
    var tmpPoints:Array<Dynamic> = null;
    newShapes[mainIdx] = null;
    newShapeHoles[mainIdx] = [];
    
    var i = 0;
    var l = subPaths.length;
    while (i < l) {
      tmpPath = subPaths[i];
      tmpPoints = tmpPath.getPoints();
      solid = isClockWise(tmpPoints);
      solid = isCCW ? !solid : solid;
      if (solid) {
        if ((!holesFirst) && (newShapes[mainIdx]))
            mainIdx++;
        newShapes[mainIdx] = {s: new Shape(), p: tmpPoints};
        newShapes[mainIdx].s.curves = tmpPath.curves;
        if (holesFirst)
          mainIdx++;
        newShapeHoles[mainIdx] = [];
      } else {
        newShapeHoles[mainIdx].push({h: tmpPath, p: tmpPoints[0]});
      }
      i++;
    }
    
    if (!newShapes[0])
      return toShapesNoHoles(subPaths);
    
    if (newShapes.length > 1) {
      var ambiguous = false;
      var toChange = 0;
      var sIdx = 0;
      var sLen = newShapes.length;
      while (sIdx < sLen) {
        betterShapeHoles[sIdx] = [];
        sIdx++;
      }
      sIdx = 0;
      while (sIdx < sLen) {
        var sho:Array<Dynamic> = newShapeHoles[sIdx];
        var hIdx = 0;
        var hLen = sho.length;
        while (hIdx < hLen) {
          var ho = sho[hIdx];
          var hole_unassigned = true;
          var s2Idx = 0;
          var s2Len = newShapes.length;
          while (s2Idx < s2Len) {
            if (isPointInsidePolygon(ho.p, newShapes[s2Idx].p)) {
              if (sIdx !== s2Idx) toChange++;
              if (hole_unassigned) {
                hole_unassigned = false;
                betterShapeHoles[s2Idx].push(ho);
              } else {
                ambiguous = true;
              }
            }
            s2Idx++;
          }
          if (hole_unassigned)
            betterShapeHoles[sIdx].push(ho);
          hIdx++;
        }
        sIdx++;
      }
      if (toChange > 0 && ambiguous === false)
        newShapeHoles = betterShapeHoles;
    }
    
    var tmpHoles:Array<Dynamic>;
    var i = 0;
    var il = newShapes.length;
    while (i < il) {
      tmpShape = newShapes[i].s;
      shapes.push(tmpShape);
      tmpHoles = newShapeHoles[i];
      var j = 0;
      var jl = tmpHoles.length;
      while (j < jl) {
        tmpShape.holes.push(tmpHoles[j].h);
        j++;
      }
      i++;
    }
    return shapes;
  }
}

extern class ShapePath {
  public var type:String;
  public var color:Color;
  public var subPaths:Array<Dynamic>;
  public var currentPath:Path;
  
  public function new():Void;
  
  public function moveTo(x:Float, y:Float):ShapePath;
  
  public function lineTo(x:Float, y:Float):ShapePath;
  
  public function quadraticCurveTo(aCPx:Float, aCPy:Float, aX:Float, aY:Float):ShapePath;
  
  public function bezierCurveTo(aCP1x:Float, aCP1y:Float, aCP2x:Float, aCP2y:Float, aX:Float, aY:Float):ShapePath;
  
  public function splineThru(pts:Array<Dynamic>):ShapePath;
  
  public function toShapes(isCCW:Bool):Array<Shape>;
}

class ShapeUtils {
  public static function isClockWise(pts:Array<Dynamic>):Bool { return false; }
}

class Color {
  public function new():Void;
}

class Path {
  public function new():Void;
  
  public function moveTo(x:Float, y:Float):Void;
  
  public function lineTo(x:Float, y:Float):Void;
  
  public function quadraticCurveTo(aCPx:Float, aCPy:Float, aX:Float, aY:Float):Void;
  
  public function bezierCurveTo(aCP1x:Float, aCP1y:Float, aCP2x:Float, aCP2y:Float, aX:Float, aY:Float):Void;
  
  public function splineThru(pts:Array<Dynamic>):Void;
  
  public function getPoints():Array<Dynamic> { return null; }
  
  public var curves:Array<Dynamic>;
}

class Shape {
  public var curves:Array<Dynamic>;
  public var holes:Array<Dynamic>;
  
  public function new():Void;
}

class Main {
  static function main() {
    var shapePath = new ShapePath();
    // Call methods on shapePath
  }
}