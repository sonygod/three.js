package three.js.src.extras.core;

import three.math.Color;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.core.ShapeUtils;

class ShapePath {
    public var type:String;

    public var color:Color;

    public var subPaths:Array<Path>;
    public var currentPath:Path;

    public function new() {
        type = 'ShapePath';
        color = new Color();

        subPaths = new Array<Path>();
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

    public function splineThru(pts:Array<Float>):ShapePath {
        currentPath.splineThru(pts);

        return this;
    }

    public function toShapes(isCCW:Bool):Array<Shape> {
        function toShapesNoHoles(inSubpaths:Array<Path>):Array<Shape> {
            var shapes:Array<Shape> = new Array<Shape>();

            for (i in 0...inSubpaths.length) {
                var tmpPath:Path = inSubpaths[i];
                var tmpShape:Shape = new Shape();
                tmpShape.curves = tmpPath.curves;

                shapes.push(tmpShape);
            }

            return shapes;
        }

        function isPointInsidePolygon(inPt:Point, inPolygon:Array<Point>):Bool {
            var polyLen:Int = inPolygon.length;
            var inside:Bool = false;

            for (p in polyLen - 1...polyLen) {
                var edgeLowPt:Point = inPolygon[p];
                var edgeHighPt:Point = inPolygon[polyLen - p - 1];

                var edgeDx:Float = edgeHighPt.x - edgeLowPt.x;
                var edgeDy:Float = edgeHighPt.y - edgeLowPt.y;

                if (Math.abs(edgeDy) > Math.EPSILON) {
                    if (edgeDy < 0) {
                        edgeLowPt = inPolygon[polyLen - p - 1];
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
                    if (inPt.y != edgeLowPt.y) continue; // parallel
                    if ((edgeHighPt.x <= inPt.x) && (inPt.x <= edgeLowPt.x) || (edgeLowPt.x <= inPt.x) && (inPt.x <= edgeHighPt.x)) return true; // inPt: Point on contour !
                }
            }

            return inside;
        }

        var isClockWise:Bool = ShapeUtils.isClockWise;

        var subPaths:Array<Path> = this.subPaths;
        if (subPaths.length == 0) return [];

        var shapes:Array<Shape> = new Array<Shape>();

        if (subPaths.length == 1) {
            var tmpPath:Path = subPaths[0];
            var tmpShape:Shape = new Shape();
            tmpShape.curves = tmpPath.curves;
            shapes.push(tmpShape);
            return shapes;
        }

        var holesFirst:Bool = !isClockWise(subPaths[0].getPoints());
        holesFirst = isCCW ? !holesFirst : holesFirst;

        var betterShapeHoles:Array<Array<{h:Path, p:Point}>> = new Array<Array<{h:Path, p:Point}>>();
        var newShapes:Array<{s:Shape, p:Array<Point>}>;
        var newShapeHoles:Array<Array<{h:Path, p:Point}>>;
        var mainIdx:Int = 0;
        var tmpPoints:Array<Point>;

        newShapes[mainIdx] = null;
        newShapeHoles[mainIdx] = new Array<{h:Path, p:Point}>();

        for (i in 0...subPaths.length) {
            var tmpPath:Path = subPaths[i];
            tmpPoints = tmpPath.getPoints();
            var solid:Bool = isClockWise(tmpPoints);
            solid = isCCW ? !solid : solid;

            if (solid) {
                if (!((!holesFirst) && (newShapes[mainIdx] != null))) mainIdx++;

                newShapes[mainIdx] = {s: new Shape(), p: tmpPoints};
                newShapes[mainIdx].s.curves = tmpPath.curves;

                if (holesFirst) mainIdx++;
                newShapeHoles[mainIdx] = new Array<{h:Path, p:Point}>();
            } else {
                newShapeHoles[mainIdx].push({h: tmpPath, p: tmpPoints[0]});
            }
        }

        if (newShapes[0] == null) return toShapesNoHoles(subPaths);

        if (newShapes.length > 1) {
            var ambiguous:Bool = false;
            var toChange:Int = 0;

            for (sIdx in 0...newShapes.length) {
                betterShapeHoles[sIdx] = new Array<{h:Path, p:Point}>();
            }

            for (sIdx in 0...newShapes.length) {
                var sho:Array<{h:Path, p:Point}> = newShapeHoles[sIdx];

                for (hIdx in 0...sho.length) {
                    var ho:{h:Path, p:Point} = sho[hIdx];
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

        var tmpHoles:Array<{h:Path, p:Point}>;

        for (i in 0...newShapes.length) {
            var tmpShape:Shape = newShapes[i].s;
            shapes.push(tmpShape);
            tmpHoles = newShapeHoles[i];

            for (j in 0...tmpHoles.length) {
                tmpShape.holes.push(tmpHoles[j].h);
            }
        }

        return shapes;
    }
}