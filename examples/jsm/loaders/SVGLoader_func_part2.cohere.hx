static function createShapes(shapePath:ShapePath):Array<Shape> {
	var BIGNUMBER = 999999999;

	enum IntersectionLocationType {
		ORIGIN,
		DESTINATION,
		BETWEEN,
		LEFT,
		RIGHT,
		BEHIND,
		BEYOND
	}

	var classifyResult = { loc: IntersectionLocationType.ORIGIN, t: 0 };

	function findEdgeIntersection(a0:Vector2D, a1:Vector2D, b0:Vector2D, b1:Vector2D):Vector2D {
		var x1 = a0.x;
		var x2 = a1.x;
		var x3 = b0.x;
		var x4 = b1.x;
		var y1 = a0.y;
		var y2 = a1.y;
		var y3 = b0.y;
		var y4 = b1.y;
		var nom1 = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
		var nom2 = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3);
		var denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
		var t1 = nom1 / denom;
		var t2 = nom2 / denom;

		if ((denom == 0 && nom1 != 0) || t1 <= 0 || t1 >= 1 || t2 < 0 || t2 > 1) {
			//1. lines are parallel or edges don't intersect
			return null;
		} else if (nom1 == 0 && denom == 0) {
			//2. lines are colinear
			//check if endpoints of edge2 (b0-b1) lies on edge1 (a0-a1)
			for (i in 0...2) {
				var p = i == 0 ? b0 : b1;
				classifyPoint(p, a0, a1);
				//find position of this endpoints relatively to edge1
				if (classifyResult.loc == IntersectionLocationType.ORIGIN) {
					return { x: p.x, y: p.y, t: classifyResult.t };
				} else if (classifyResult.loc == IntersectionLocationType.BETWEEN) {
					return { x: x1 + classifyResult.t * (x2 - x1), y: y1 + classifyResult.t * (y2 - y1), t: classifyResult.t };
				}
			}
			return null;
		} else {
			//3. edges intersect
			for (i in 0...2) {
				var p = i == 0 ? b0 : b1;
				classifyPoint(p, a0, a1);
				if (classifyResult.loc == IntersectionLocationType.ORIGIN) {
					return { x: p.x, y: p.y, t: classifyResult.t };
				}
			}
			return { x: x1 + t1 * (x2 - x1), y: y1 + t1 * (y2 - y1), t: t1 };
		}
	}

	function classifyPoint(p:Vector2D, edgeStart:Vector2D, edgeEnd:Vector2D) {
		var ax = edgeEnd.x - edgeStart.x;
		var ay = edgeEnd.y - edgeStart.y;
		var bx = p.x - edgeStart.x;
		var by = p.y - edgeStart.y;
		var sa = ax * by - bx * ay;

		if (p.x == edgeStart.x && p.y == edgeStart.y) {
			classifyResult.loc = IntersectionLocationType.ORIGIN;
			classifyResult.t = 0;
			return;
		}

		if (p.x == edgeEnd.x && p.y == edgeEnd.y) {
			classifyResult.loc = IntersectionLocationType.DESTINATION;
			classifyResult.t = 1;
			return;
		}

		if (sa < -Number.EPSILON) {
			classifyResult.loc = IntersectionLocationType.LEFT;
			return;
		}

		if (sa > Number.EPSILON) {
			classifyResult.loc = IntersectionLocationType.RIGHT;
			return;
		}

		if ((ax * bx) < 0 || (ay * by) < 0) {
			classifyResult.loc = IntersectionLocationType.BEHIND;
			return;
		}

		if (Math.sqrt(ax * ax + ay * ay) < Math.sqrt(bx * bx + by * by)) {
			classifyResult.loc = IntersectionLocationType.BEYOND;
			return;
		}

		var t:Float;
		if (ax != 0) t = bx / ax;
		else t = by / ay;

		classifyResult.loc = IntersectionLocationType.BETWEEN;
		classifyResult.t = t;
	}

	function getIntersections(path1:Array<Vector2D>, path2:Array<Vector2D>):Array<Vector2D> {
		var intersectionsRaw:Array<Vector2D> = [];
		var intersections:Array<Vector2D> = [];

		for (index in 1...path1.length) {
			var path1EdgeStart = path1[index - 1];
			var path1EdgeEnd = path1[index];

			for (index2 in 1...path2.length) {
				var path2EdgeStart = path2[index2 - 1];
				var path2EdgeEnd = path2[index2];

				var intersection = findEdgeIntersection(path1EdgeStart, path1EdgeEnd, path2EdgeStart, path2EdgeEnd);

				if (intersection != null && !intersectionsRaw.contains(i => i.t <= intersection.t + Number.EPSILON && i.t >= intersection.t - Number.EPSILON)) {
					intersectionsRaw.push(intersection);
					intersections.push(new Vector2D(intersection.x, intersection.y));
				}
			}
		}

		return intersections;
	}

	function getScanlineIntersections(scanline:Array<Vector2D>, boundingBox:Box2D, paths:Array<Shape>):Array<Vector2D> {
		var center = boundingBox.center();
		var allIntersections:Array<Vector2D> = [];

		for (path in paths) {
			// check if the center of the bounding box is in the bounding box of the paths.
			// this is a pruning method to limit the search of intersections in paths that can't envelop of the current path.
			// if a path envelops another path. The center of that oter path, has to be inside the bounding box of the enveloping path.
			if (path.boundingBox.containsPoint(center)) {
				var intersections = getIntersections(scanline, path.points);

				for (p in intersections) {
					allIntersections.push({ identifier: path.identifier, isCW: path.isCW, point: p });
				}
			}
		}

		allIntersections.sort((i1, i2) -> i1.point.x - i2.point.x);

		return allIntersections;
	}

	function isHoleTo(simplePath:Shape, allPaths:Array<Shape>, scanlineMinX:Float, scanlineMaxX:Float, _fillRule:String):Shape {
		if (_fillRule == null || _fillRule == "" || _fillRule == null) {
			_fillRule = "nonzero";
		}

		var centerBoundingBox = simplePath.boundingBox.center();
		var scanline = [new Vector2D(scanlineMinX, centerBoundingBox.y), new Vector2D(scanlineMaxX, centerBoundingBox.y)];

		var scanlineIntersections = getScanlineIntersections(scanline, simplePath.boundingBox, allPaths);

		scanlineIntersections.sort((i1, i2) -> i1.point.x - i2.point.x);

		var baseIntersections:Array<Vector2D> = [];
		var otherIntersections:Array<Vector2D> = [];

		for (i in scanlineIntersections) {
			if (i.identifier == simplePath.identifier) {
				baseIntersections.push(i);
			} else {
				otherIntersections.push(i);
			}
		}

		var firstXOfPath = baseIntersections[0].point.x;

		// build up the path hierarchy
		var stack:Array<Int> = [];
		var i = 0;

		while (i < otherIntersections.length && otherIntersections[i].point.x < firstXOfPath) {
			if (stack.length > 0 && stack[stack.length - 1] == otherIntersections[i].identifier) {
				stack.pop();
			} else {
				stack.push(otherIntersections[i].identifier);
			}

			i++;
		}

		stack.push(simplePath.identifier);

		if (_fillRule == "evenodd") {
			var isHole = stack.length % 2 == 0;
			var isHoleFor = stack[stack.length - 2];

			return { identifier: simplePath.identifier, isHole: isHole, for: isHoleFor };
		} else if (_fillRule == "nonzero") {
			// check if path is a hole by counting the amount of paths with alternating rotations it has to cross.
			var isHole = true;
			var isHoleFor = null;
			var lastCWValue = null;

			for (i in 0...stack.length) {
				var identifier = stack[i];
				if (isHole) {
					lastCWValue = allPaths[identifier].isCW;
					isHole = false;
					isHoleFor = identifier;
				} else if (lastCWValue != allPaths[identifier].isCW) {
					lastCWValue = allPaths[identifier].isCW;
					isHole = true;
				}
			}

			return { identifier: simplePath.identifier, isHole: isHole, for: isHoleFor };
		} else {
			trace("fill-rule: \"$_fillRule\" is currently not implemented.");
		}
	}

	// check for self intersecting paths
	// TODO

	// check intersecting paths
	// TODO

	// prepare paths for hole detection
	var scanlineMinX = BIGNUMBER;
	var scanlineMaxX = -BIGNUMBER;

	var simplePaths:Array<Shape> = [];

	for (path in shapePath.subPaths) {
		var points = path.getPoints();
		var maxY = -BIGNUMBER;
		var minY = BIGNUMBER;
		var maxX = -BIGNUMBER;
		var minX = BIGNUMBER;

		//points.forEach(p => p.y *= -1);

		for (i in 0...points.length) {
			var p = points[i];

			if (p.y > maxY) {
				maxY = p.y;
			}

			if (p.y < minY) {
				minY = p.y;
			}

			if (p.x > maxX) {
				maxX = p.x;
			}

			if (p.x < minX) {
				minX = p.x;
			}
		}

		//
		if (scanlineMaxX <= maxX) {
			scanlineMaxX = maxX + 1;
		}

		if (scanlineMinX >= minX) {
			scanlineMinX = minX - 1;
		}

		simplePaths.push({ curves: path.curves, points: points, isCW: ShapeUtils.isClockWise(points), identifier: -1, boundingBox: new Box2D(new Vector2D(minX, minY), new Vector2D(maxX, maxY)) });
	}

	simplePaths = simplePaths.filter(sp => sp.points.length > 1);

	for (identifier in 0...simplePaths.length) {
		simplePaths[identifier].identifier = identifier;
	}

	// check if path is solid or a hole
	var isAHole = simplePaths.map(p => isHoleTo(p, simplePaths, scanlineMinX, scanlineMaxX, shapePath.userData ? shapePath.userData.style.fillRule : null));


	var shapesToReturn:Array<Shape> = [];
	for (p in simplePaths) {
		var amIAHole = isAHole[p.identifier];

		if (!amIAHole.isHole) {
			var shape = new Shape();
			shape.curves = p.curves;
			var holes = isAHole.filter(h => h.isHole && h.for == p.identifier);

			for (hole in holes) {
				var hole = simplePaths[hole.identifier];
				var path = new Path();
				path.curves = hole.curves;
				shape.holes.push(path);
			}

			shapesToReturn.push(shape);
		}
	}

	return shapesToReturn;
}

static function getStrokeStyle(width:Float = 1, color:String = "#000", lineJoin:String = "miter", lineCap:String = "butt", miterLimit:Int = 4):Dynamic {
	return {
		strokeColor: color,
		strokeWidth: width,
		strokeLineJoin: lineJoin,
		strokeLineCap: lineCap,
		strokeMiterLimit: miterLimit
	};
}

static function pointsToStroke(points:Array<Vector2D>, style:Dynamic, arcDivisions:Int = 0, minDistance:Float = 0):BufferGeometry {
	var vertices:Array<Float> = [];
	var normals:Array<Float> = [];
	var uvs:Array<Float> = [];

	if (pointsToStrokeWithBuffers(points, style, arcDivisions, minDistance, vertices, normals, uvs) == 0) {
		return null;
	}

	var geometry = new BufferGeometry();
	geometry.setAttribute("position", new Float32BufferAttribute(vertices, 3));
	geometry.setAttribute("normal", new Float32BufferAttribute(normals, 3));
	geometry.setAttribute("uv", new Float32BufferAttribute(uvs, 2));

	return geometry;
}