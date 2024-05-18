package three.extras.core;

import three.math.Color;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.core.ShapeUtils;

class ShapePath {

    public var type:String = 'ShapePath';

    public var color:Color;

    public var subPaths:Array<Path>;
    public var currentPath:Path;

    public function new() {
        color = new Color();
        subPaths = [];
        currentPath = null;
    }

    public function moveTo(x:Float, y:Float):ShapePath {
        currentPath = new Path();
        subPaths.push(currentPath);
        currentPath.moveTo(x, y);
        return this;
    }

    public function lineTo(x:Float, y:Float):ShapePath {
        currentPath.lineTo(x, y);
        return this;
    }

    public function quadraticCurveTo(aCPx:Float, aCPy:Float, aX:Float, aY:Float):ShapePath {
        currentPath.quadraticCurveTo(aCPx, aCPy, aX, aY);
        return this;
    }

    public function bezierCurveTo(aCP1x:Float, aCP1y:Float, aCP2x:Float, aCP2y:Float, aX:Float, aY:Float):ShapePath {
        currentPath.bezierCurveTo(aCP1x, aCP1y, aCP2x, aCP2y, aX, aY);
        return this;
    }

    public function splineThru(pts:Array<Dynamic>):ShapePath {
        currentPath.splineThru(pts);
        return this;
    }

    public function toShapes(isCCW:Bool):Array<Shape> {
        function toShapesNoHoles(inSubpaths:Array<Path>):Array<Shape> {
            var shapes:Array<Shape> = [];
            for (i in 0...inSubpaths.length) {
                var tmpPath:Path = inSubpaths[i];
                var tmpShape:Shape = new Shape();
                tmpShape.curves = tmpPath.curves;
                shapes.push(tmpShape);
            }
            return shapes;
        }

        function isPointInsidePolygon(inPt:Dynamic, inPolygon:Array<Dynamic>):Bool {
            var polyLen:Int = inPolygon.length;
            var inside:Bool = false;
            for (p in polyLen - 1...polyLen) {
                var edgeLowPt:Dynamic = inPolygon[p];
                var edgeHighPt:Dynamic = inPolygon[(p + 1) % polyLen];
                var edgeDx:Float = edgeHighPt.x - edgeLowPt.x;
                var edgeDy:Float = edgeHighPt.y - edgeLowPt.y;
                if (Math.abs(edgeDy) > Math.EPSILON) {
                    if (edgeDy < 0) {
                        edgeLowPt = inPolygon[(p + 1) % polyLen];
                        edgeDx = -edgeDx;
                        edgeHighPt = inPolygon[p];
                        edgeDy = -edgeDy;
                    }
                    if (inPt.y < edgeLowPt.y || inPt.y > edgeHighPt.y) continue;
                    if (inPt.y == edgeLowPt.y) {
                        if (inPt.x == edgeLowPt.x) return true; // inPt is on contour ?
                        continue; // no intersection or edgeLowPt => doesn't count !!!
                    } else {
                        var perpEdge:Float = edgeDy * (inPt.x - edgeLowPt.x) - edgeDx * (inPt.y - edgeLowPt.y);
                        if (perpEdge == 0) return true; // inPt is on contour ?
                        if (perpEdge < 0) continue;
                        inside = !inside; // true intersection left of inPt
                    }
                } else {
                    // parallel or collinear
                    if (inPt.y != edgeLowPt.y) continue; // parallel
                    // edge lies on the same horizontal line as inPt
                    if ((edgeHighPt.x <= inPt.x && inPt.x <= edgeLowPt.x) || (edgeLowPt.x <= inPt.x && inPt.x <= edgeHighPt.x)) return true; // inPt: Point on contour !
                    continue;
                }
            }
            return inside;
        }

        var isClockWise:Bool = ShapeUtils.isClockWise;
        var subPaths:Array<Path> = this.subPaths;
        if (subPaths.length == 0) return [];

        var solid:Bool, tmpPath:Path, tmpShape:Shape;
        var shapes:Array<Shape> = [];

        if (subPaths.length == 1) {
            tmpPath = subPaths[0];
            tmpShape = new Shape();
            tmpShape.curves = tmpPath.curves;
            shapes.push(tmpShape);
            return shapes;
        }

        var holesFirst:Bool = !isClockWise(subPaths[0].getPoints());
        holesFirst = isCCW ? !holesFirst : holesFirst;

        var betterShapeHoles:Array<Dynamic> = [];
        var newShapes:Array<Dynamic> = [];
        var newShapeHoles:Array<Dynamic> = [];
        var mainIdx:Int = 0;
        var tmpPoints:Array<Dynamic>;

        newShapes[mainIdx] = undefined;
        newShapeHoles[mainIdx] = [];

        for (i in 0...subPaths.length) {
            tmpPath = subPaths[i];
            tmpPoints = tmpPath.getPoints();
            solid = isClockWise(tmpPoints);
            solid = isCCW ? !solid : solid;

            if (solid) {
                if (!holesFirst && newShapes[mainIdx] != null) mainIdx++;
                newShapes[mainIdx] = { s: new Shape(), p: tmpPoints };
                newShapes[mainIdx].s.curves = tmpPath.curves;

                if (holesFirst) mainIdx++;
                newShapeHoles[mainIdx] = [];
            } else {
                newShapeHoles[mainIdx].push({ h: tmpPath, p: tmpPoints[0] });
            }
        }

        if (newShapes.length > 1) {
            var ambiguous:Bool = false;
            var toChange:Int = 0;

            for (sIdx in 0...newShapes.length) {
                betterShapeHoles[sIdx] = [];
            }

            for (sIdx in 0...newShapes.length) {
                var sho:Array<Dynamic> = newShapeHoles[sIdx];

                for (hIdx in 0...sho.length) {
                    var ho:Dynamic = sho[hIdx];
                    var hole_unassigned:Bool = true;

                    for (s2Idx in 0...newShapes.length) {
                        if (isPointInsidePolygon(ho.p, newShapes[s2Idx].p)) {
                            if (sIdx != s2Idx) toChange++;

                            if (hole_unassigned) {
                                hole_unassigned = false;
                                betterShapeHoles[s2Idx].push(ho);
                            } else {
                                ambiguous = true;
                            }
                        }
                    }

                    if (hole_unassigned) {
                        betterShapeHoles[sIdx].push(ho);
                    }
                }
            }

            if (toChange > 0 && !ambiguous) {
                newShapeHoles = betterShapeHoles;
            }
        }

        var tmpHoles:Array<Dynamic>;

        for (i in 0...newShapes.length) {
            tmpShape = newShapes[i].s;
            shapes.push(tmpShape);
            tmpHoles = newShapeHoles[i];

            for (j in 0...tmpHoles.length) {
                tmpShape.holes.push(tmpHoles[j].h);
            }
        }

        return shapes;
    }
}