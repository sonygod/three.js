import haxe.ui.Color;
import haxe.ui.Path;
import haxe.ui.Shape;
import haxe.ui.ShapeUtils;

class ShapePath {
	public var type:String = "ShapePath";
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

	public function splineThru(pts:Array<haxe.ui.Point>):ShapePath {
		this.currentPath.splineThru(pts);
		return this;
	}

	public function toShapes(isCCW:Bool):Array<Shape> {
		function toShapesNoHoles(inSubpaths:Array<Path>):Array<Shape> {
			var shapes:Array<Shape> = [];
			for (i in 0...inSubpaths.length) {
				var tmpPath = inSubpaths[i];
				var tmpShape = new Shape();
				tmpShape.curves = tmpPath.curves;
				shapes.push(tmpShape);
			}
			return shapes;
		}

		function isPointInsidePolygon(inPt:haxe.ui.Point, inPolygon:Array<haxe.ui.Point>):Bool {
			var polyLen = inPolygon.length;
			var inside = false;
			for (p in 0...polyLen) {
				var q = (p + 1) % polyLen;
				var edgeLowPt = inPolygon[p];
				var edgeHighPt = inPolygon[q];
				var edgeDx = edgeHighPt.x - edgeLowPt.x;
				var edgeDy = edgeHighPt.y - edgeLowPt.y;
				if (Math.abs(edgeDy) > Number.EPSILON) {
					if (edgeDy < 0) {
						edgeLowPt = inPolygon[q]; edgeDx = - edgeDx;
						edgeHighPt = inPolygon[p]; edgeDy = - edgeDy;
					}
					if ((inPt.y < edgeLowPt.y) || (inPt.y > edgeHighPt.y)) continue;
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
					((edgeLowPt.x <= inPt.x) && (inPt.x <= edgeHighPt.x))) return true;
				}
			}
			return inside;
		}

		var isClockWise = ShapeUtils.isClockWise;
		var subPaths = this.subPaths;
		if (subPaths.length === 0) return [];
		var solid, tmpPath, tmpShape;
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
		var betterShapeHoles:Array<Array<{h:Path, p:haxe.ui.Point}>> = [];
		var newShapes:Array<{s:Shape, p:Array<haxe.ui.Point>}> = [];
		var newShapeHoles:Array<Array<{h:Path, p:haxe.ui.Point}>> = [];
		var mainIdx = 0;
		var tmpPoints;
		newShapes[mainIdx] = null;
		newShapeHoles[mainIdx] = [];
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
				newShapeHoles[mainIdx] = [];
			} else {
				newShapeHoles[mainIdx].push({h: tmpPath, p: tmpPoints[0]});
			}
		}
		if (newShapes[0] == null) return toShapesNoHoles(subPaths);
		if (newShapes.length > 1) {
			var ambiguous = false;
			var toChange = 0;
			for (sIdx in 0...newShapes.length) {
				betterShapeHoles[sIdx] = [];
			}
			for (sIdx in 0...newShapes.length) {
				var sho = newShapeHoles[sIdx];
				for (hIdx in 0...sho.length) {
					var ho = sho[hIdx];
					var hole_unassigned = true;
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
		var tmpHoles;
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