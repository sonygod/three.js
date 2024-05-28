package three.js.src.extras.core;

import three.math.Color;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.utils.ShapeUtils;

class ShapePath {
    public var type:String;
    public var color:Color;
    public var subPaths:Array<Path>;
    public var currentPath:Path;

    public function new() {
        this.type = 'ShapePath';
        this.color = new Color();
        this.subPaths = new Array<Path>();
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

    public function splineThru(pts:Array<Float>):ShapePath {
        this.currentPath.splineThru(pts);
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

        function isPointInsidePolygon(inPt:Array<Float>, inPolygon:Array<Float>):Bool {
            var polyLen:Int = inPolygon.length;
            var inside:Bool = false;
            for (p in polyLen - 1...polyLen) {
                var edgeLowPt:Array<Float> = inPolygon[p];
                var edgeHighPt:Array<Float> = inPolygon[(p + 1) % polyLen];
                var edgeDx:Float = edgeHighPt[0] - edgeLowPt[0];
                var edgeDy:Float = edgeHighPt[1] - edgeLowPt[1];

                if (Math.abs(edgeDy) > Math.EPSILON) {
                    if (edgeDy < 0) {
                        edgeLowPt = inPolygon[(p + 1) % polyLen];
                        edgeDx = -edgeDx;
                        edgeHighPt = inPolygon[p];
                        edgeDy = -edgeDy;
                    }

                    if (inPt[1] < edgeLowPt[1] || inPt[1] > edgeHighPt[1]) continue;

                    if (inPt[1] == edgeLowPt[1]) {
                        if (inPt[0] == edgeLowPt[0]) return true; // inPt is on contour ?
                        continue; // no intersection or edgeLowPt => doesn't count !!!
                    } else {
                        var perpEdge:Float = edgeDy * (inPt[0] - edgeLowPt[0]) - edgeDx * (inPt[1] - edgeLowPt[1]);
                        if (perpEdge == 0) return true; // inPt is on contour ?
                        if (perpEdge < 0) continue;
                        inside = !inside; // true intersection left of inPt
                    }
                } else {
                    if (inPt[1] != edgeLowPt[1]) continue; // parallel
                    if ((edgeHighPt[0] <= inPt[0] && inPt[0] <= edgeLowPt[0]) || (edgeLowPt[0] <= inPt[0] && inPt[0] <= edgeHighPt[0])) return true; // inPt: Point on contour !
                }
            }
            return inside;
        }

        var isClockWise:Bool = ShapeUtils.isClockWise;
        var subPaths:Array<Path> = this.subPaths;
        if (subPaths.length == 0) return new Array<Shape>();

        var solid:Bool;
        var tmpPath:Path;
        var tmpShape:Shape;
        var shapes:Array<Shape> = new Array<Shape>();

        if (subPaths.length == 1) {
            tmpPath = subPaths[0];
            tmpShape = new Shape();
            tmpShape.curves = tmpPath.curves;
            shapes.push(tmpShape);
            return shapes;
        }

        var holesFirst:Bool = !isClockWise(subPaths[0].getPoints());
        holesFirst = isCCW ? !holesFirst : holesFirst;

        var betterShapeHoles:Array<Array<Dynamic>> = new Array<Array<Dynamic>>();
        var newShapes:Array<Dynamic> = new Array<Dynamic>();
        var newShapeHoles:Array<Array<Dynamic>> = new Array<Array<Dynamic>>();
        var mainIdx:Int = 0;
        var tmpPoints:Array<Float>;

        newShapes[mainIdx] = undefined;
        newShapeHoles[mainIdx] = new Array<Dynamic>();

        for (i in 0...subPaths.length) {
            tmpPath = subPaths[i];
            tmpPoints = tmpPath.getPoints();
            solid = isClockWise(tmpPoints);
            solid = isCCW ? !solid : solid;

            if (solid) {
                if ((!holesFirst) && (newShapes[mainIdx] != null)) mainIdx++;

                newShapes[mainIdx] = {s: new Shape(), p: tmpPoints};
                newShapes[mainIdx].s.curves = tmpPath.curves;

                if (holesFirst) mainIdx++;
                newShapeHoles[mainIdx] = new Array<Dynamic>();
            } else {
                newShapeHoles[mainIdx].push({h: tmpPath, p: tmpPoints[0]});
            }
        }

        if (newShapes[0] == null) return toShapesNoHoles(subPaths);

        if (newShapes.length > 1) {
            var ambiguous:Bool = false;
            var toChange:Int = 0;

            for (sIdx in 0...newShapes.length) {
                betterShapeHoles[sIdx] = new Array<Dynamic>();
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

            if (toChange > 0 && ambiguous == false) {
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