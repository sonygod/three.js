class SVGLoader {

	static function createShapes(shapePath:ShapePath):Array<Shape> {

		// Param shapePath: a shapepath as returned by the parse function of this class
		// Returns Shape object

		const BIGNUMBER = 999999999;

		enum IntersectionLocationType {
			ORIGIN = 0;
			DESTINATION = 1;
			BETWEEN = 2;
			LEFT = 3;
			RIGHT = 4;
			BEHIND = 5;
			BEYOND = 6;
		}

		var classifyResult = {
			loc: IntersectionLocationType.ORIGIN,
			t: 0
		};

		function findEdgeIntersection(a0:Vector2, a1:Vector2, b0:Vector2, b1:Vector2):{x:Float,y:Float,t:Float}? {

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

			if ( (denom == 0 && nom1 != 0) || t1 <= 0 || t1 >= 1 || t2 < 0 || t2 > 1 ) {

				//1. lines are parallel or edges don't intersect

				return null;

			} else if (nom1 == 0 && denom == 0) {

				//2. lines are colinear

				//check if endpoints of edge2 (b0-b1) lies on edge1 (a0-a1)
				for (i in 0...2) {

					classifyPoint(if (i == 0) b0 else b1, a0, a1);
					//find position of this endpoints relatively to edge1
					if (classifyResult.loc == IntersectionLocationType.ORIGIN) {

						var point = if (i == 0) b0 else b1;
						return {x: point.x, y: point.y, t: classifyResult.t};

					} else if (classifyResult.loc == IntersectionLocationType.BETWEEN) {

						var x = Std.parseFloat((x1 + classifyResult.t * (x2 - x1)).toPrecision(10));
						var y = Std.parseFloat((y1 + classifyResult.t * (y2 - y1)).toPrecision(10));
						return {x: x, y: y, t: classifyResult.t, };

					}

				}

				return null;

			} else {

				//3. edges intersect

				for (i in 0...2) {

					classifyPoint(if (i == 0) b0 else b1, a0, a1);

					if (classifyResult.loc == IntersectionLocationType.ORIGIN) {

						var point = if (i == 0) b0 else b1;
						return {x: point.x, y: point.y, t: classifyResult.t};

					}

				}

				var x = Std.parseFloat((x1 + t1 * (x2 - x1)).toPrecision(10));
				var y = Std.parseFloat((y1 + t1 * (y2 - y1)).toPrecision(10));
				return {x: x, y: y, t: t1};

			}

		}

		function classifyPoint(p:Vector2, edgeStart:Vector2, edgeEnd:Vector2):Void {

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

			if (sa < -Math.EPSILON) {

				classifyResult.loc = IntersectionLocationType.LEFT;
				return;

			}

			if (sa > Math.EPSILON) {

				classifyResult.loc = IntersectionLocationType.RIGHT;
				return;


			}

			if ( (ax * bx) < 0 || (ay * by) < 0 ) {

				classifyResult.loc = IntersectionLocationType.BEHIND;
				return;

			}

			if (Math.sqrt(ax * ax + ay * ay) < Math.sqrt(bx * bx + by * by)) {

				classifyResult.loc = IntersectionLocationType.BEYOND;
				return;

			}

			var t:Float;

			if (ax != 0) {

				t = bx / ax;

			} else {

				t = by / ay;

			}

			classifyResult.loc = IntersectionLocationType.BETWEEN;
			classifyResult.t = t;

		}

		function getIntersections(path1:Array<Vector2>, path2:Array<Vector2>):Array<Vector2> {

			var intersectionsRaw:Array<{x:Float,y:Float,t:Float}> = [];
			var intersections:Array<Vector2> = [];

			for (index in 1...path1.length) {

				var path1EdgeStart = path1[index - 1];
				var path1EdgeEnd = path1[index];

				for (index2 in 1...path2.length) {

					var path2EdgeStart = path2[index2 - 1];
					var path2EdgeEnd = path2[index2];

					var intersection = findEdgeIntersection(path1EdgeStart, path1EdgeEnd, path2EdgeStart, path2EdgeEnd);

					if (intersection != null && intersectionsRaw.filter(i -> i.t <= intersection.t + Math.EPSILON && i.t >= intersection.t - Math.EPSILON).length == 0) {

						intersectionsRaw.push(intersection);
						intersections.push(new Vector2(intersection.x, intersection.y));

					}

				}

			}

			return intersections;

		}

		function getScanlineIntersections(scanline:Array<Vector2>, boundingBox:Box2, paths:Array<SimplePath>):Array<{identifier:Int,isCW:Bool,point:Vector2}> {

			var center = new Vector2();
			boundingBox.getCenter(center);

			var allIntersections:Array<{identifier:Int,isCW:Bool,point:Vector2}> = [];

			paths.forEach(path -> {

				// check if the center of the bounding box is in the bounding box of the paths.
				// this is a pruning method to limit the search of intersections in paths that can't envelop of the current path.
				// if a path envelops another path. The center of that oter path, has to be inside the bounding box of the enveloping path.
				if (path.boundingBox.containsPoint(center)) {

					var intersections = getIntersections(scanline, path.points);

					intersections.forEach(p -> {

						allIntersections.push({identifier: path.identifier, isCW: path.isCW, point: p});

					});

				}

			});

			allIntersections.sort((i1, i2) -> i1.point.x - i2.point.x);

			return allIntersections;

		}

		function isHoleTo(simplePath:SimplePath, allPaths:Array<SimplePath>, scanlineMinX:Float, scanlineMaxX:Float, _fillRule:String):{identifier:Int,isHole:Bool,for:Int?} {

			if (_fillRule == null || _fillRule == "" || _fillRule == undefined) {

				_fillRule = "nonzero";

			}

			var centerBoundingBox = new Vector2();
			simplePath.boundingBox.getCenter(centerBoundingBox);

			var scanline = [new Vector2(scanlineMinX, centerBoundingBox.y), new Vector2(scanlineMaxX, centerBoundingBox.y)];

			var scanlineIntersections = getScanlineIntersections(scanline, simplePath.boundingBox, allPaths);

			scanlineIntersections.sort((i1, i2) -> i1.point.x - i2.point.x);

			var baseIntersections:Array<{identifier:Int,isCW:Bool,point:Vector2}> = [];
			var otherIntersections:Array<{identifier:Int,isCW:Bool,point:Vector2}> = [];

			scanlineIntersections.forEach(i -> {

				if (i.identifier == simplePath.identifier) {

					baseIntersections.push(i);

				} else {

					otherIntersections.push(i);

				}

			});

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

				var isHole = stack.length % 2 == 0 ? true : false;
				var isHoleFor = stack[stack.length - 2];

				return {identifier: simplePath.identifier, isHole: isHole, for: isHoleFor};

			} else if (_fillRule == "nonzero") {

				// check if path is a hole by counting the amount of paths with alternating rotations it has to cross.
				var isHole = true;
				var isHoleFor:Int? = null;
				var lastCWValue:Bool? = null;

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

				return {identifier: simplePath.identifier, isHole: isHole, for: isHoleFor};

			} else {

				Sys.println('fill-rule: "' + _fillRule + '" is currently not implemented.');

			}

		}

		// check for self intersecting paths
		// TODO

		// check intersecting paths
		// TODO

		// prepare paths for hole detection
		var scanlineMinX = BIGNUMBER;
		var scanlineMaxX = -BIGNUMBER;

		var simplePaths:Array<SimplePath> = shapePath.subPaths.map(p -> {

			var points = p.getPoints();
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

			return {curves: p.curves, points: points, isCW: ShapeUtils.isClockWise(points), identifier: -1, boundingBox: new Box2(new Vector2(minX, minY), new Vector2(maxX, maxY))};

		});

		simplePaths = simplePaths.filter(sp -> sp.points.length > 1);

		for (identifier in 0...simplePaths.length) {

			simplePaths[identifier].identifier = identifier;

		}

		// check if path is solid or a hole
		var isAHole = simplePaths.map(p -> isHoleTo(p, simplePaths, scanlineMinX, scanlineMaxX, (shapePath.userData != null && shapePath.userData.style != null) ? shapePath.userData.style.fillRule : undefined));


		var shapesToReturn:Array<Shape> = [];
		simplePaths.forEach(p -> {

			var amIAHole = isAHole[p.identifier];

			if (!amIAHole.isHole) {

				var shape = new Shape();
				shape.curves = p.curves;
				var holes = isAHole.filter(h -> h.isHole && h.for == p.identifier);
				holes.forEach(h -> {

					var hole = simplePaths[h.identifier];
					var path = new Path();
					path.curves = hole.curves;
					shape.holes.push(path);

				});
				shapesToReturn.push(shape);

			}

		});

		return shapesToReturn;

	}

	static function getStrokeStyle(width:Float, color:String, lineJoin:String, lineCap:String, miterLimit:Float):{strokeColor:String,strokeWidth:Float,strokeLineJoin:String,strokeLineCap:String,strokeMiterLimit:Float} {

		// Param width: Stroke width
		// Param color: As returned by THREE.Color.getStyle()
		// Param lineJoin: One of "round", "bevel", "miter" or "miter-limit"
		// Param lineCap: One of "round", "square" or "butt"
		// Param miterLimit: Maximum join length, in multiples of the "width" parameter (join is truncated if it exceeds that distance)
		// Returns style object

		width = width != null ? width : 1;
		color = color != null ? color : "#000";
		lineJoin = lineJoin != null ? lineJoin : "miter";
		lineCap = lineCap != null ? lineCap : "butt";
		miterLimit = miterLimit != null ? miterLimit : 4;

		return {
			strokeColor: color,
			strokeWidth: width,
			strokeLineJoin: lineJoin,
			strokeLineCap: lineCap,
			strokeMiterLimit: miterLimit
		};

	}

	static function pointsToStroke(points:Array<Vector2>, style:Dynamic, arcDivisions:Int, minDistance:Float):BufferGeometry? {

		// Generates a stroke with some width around the given path.
		// The path can be open or closed (last point equals to first point)
		// Param points: Array of Vector2D (the path). Minimum 2 points.
		// Param style: Object with SVG properties as returned by SVGLoader.getStrokeStyle(), or SVGLoader.parse() in the path.userData.style object
		// Params arcDivisions: Arc divisions for round joins and endcaps. (Optional)
		// Param minDistance: Points closer to this distance will be merged. (Optional)
		// Returns BufferGeometry with stroke triangles (In plane z = 0). UV coordinates are generated ('u' along path. 'v' across it, from left to right)

		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		if (SVGLoader.pointsToStrokeWithBuffers(points, style, arcDivisions, minDistance, vertices, normals, uvs) == 0) {

			return null;

		}

		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		geometry.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		geometry.setAttribute("uv", new Float32BufferAttribute(uvs, 2));

		return geometry;

	}

	static function pointsToStrokeWithBuffers(points:Array<Vector2>, style:Dynamic, arcDivisions:Int, minDistance:Float, vertices:Array<Float>, normals:Array<Float>, uvs:Array<Float>):Int {

		// Generates a stroke with some width around the given path.
		// The path can be open or closed (last point equals to first point)
		// Param points: Array of Vector2D (the path). Minimum 2 points.
		// Param style: Object with SVG properties as returned by SVGLoader.getStrokeStyle(), or SVGLoader.parse() in the path.userData.style object
		// Params arcDivisions: Arc divisions for round joins and endcaps. (Optional)
		// Param minDistance: Points closer to this distance will be merged. (Optional)
		// Param vertices: Array of floats to store the stroke vertices.
		// Param normals: Array of floats to store the stroke normals.
		// Param uvs: Array of floats to store the stroke uvs.
		// Returns number of vertices generated

		var width = style.strokeWidth != null ? style.strokeWidth : 1;
		var lineJoin = style.strokeLineJoin != null ? style.strokeLineJoin : "miter";
		var lineCap = style.strokeLineCap != null ? style.strokeLineCap : "butt";
		var miterLimit = style.strokeMiterLimit != null ? style.strokeMiterLimit : 4;

		var halfWidth = width / 2;

		// When miterLimit is 4 (default), the miter joins will be truncated when their length exceeds 4 times the width.
		// If we want to truncate before that, we can adjust the miterLimit to a lower value.

		var miterLimitFactor = miterLimit;

		if (points.length < 2) return 0;

		// Generate normals (perpendicular to the line)

		var normalsArray = new Array<Vector2>();
		for (i in 1...points.length) {
			var p0 = points[i - 1];
			var p1 = points[i];
			var normal = new Vector2(p1.y - p0.y, -(p1.x - p0.x)).normalize();
			normalsArray.push(normal);
		}

		if (points[points.length - 1] != points[0]) {
			// If the path is open, we need to add a normal for the last segment (connecting the last point to the first one)
			var p0 = points[points.length - 1];
			var p1 = points[0];
			var normal = new Vector2(p1.y - p0.y, -(p1.x - p0.x)).normalize();
			normalsArray.push(normal);
		}

		// Assign normal to the first point (if open path) or the last one (if closed path)
		if (points[points.length - 1] != points[0]) {
			normalsArray.unshift(normalsArray[normalsArray.length - 1]);
		} else {
			normalsArray.unshift(normalsArray[normalsArray.length - 2]);
		}

		// Generate vertices

		var n = points.length;

		var v = 0;

		// Add first point vertices
		if (lineCap == "round") {
			// Add arc vertices for round cap
			var arcAngle = Math.PI / 2;
			var arcStep = arcAngle / arcDivisions;
			var normal = normalsArray[0];
			for (i in 0...arcDivisions + 1) {
				var angle = arcStep * i;
				var x = points[0].x + Math.cos(angle) * halfWidth * normal.x + Math.sin(angle) * halfWidth * normal.y;
				var y = points[0].y + Math.cos(angle) * halfWidth * normal.y - Math.sin(angle) * halfWidth * normal.x;
				vertices.push(x, y, 0);
				normals.push(normal.x, normal.y, 0);
				uvs.push(0, i / arcDivisions);
				v++;
			}
		} else if (lineCap == "square") {
			// Add square cap vertices
			var normal = normalsArray[0];
			var x = points[0].x + normal.x * halfWidth;
			var y = points[0].y + normal.y * halfWidth;
			vertices.push(x, y, 0);
			normals.push(normal.x, normal.y, 0);
			uvs.push(0, 0);
			v++;
			x = points[0].x - normal.x * halfWidth;
			y = points[0].y - normal.y * halfWidth;
			vertices.push(x, y, 0);
			normals.push(normal.x, normal.y, 0);
			uvs.push(0, 1);
			v++;
		} else {
			// Add butt cap vertices
			var normal = normalsArray[0];
			var x = points[0].x + normal.x * halfWidth;
			var y = points[0].y + normal.y * halfWidth;
			vertices.push(x, y, 0);
			normals.push(normal.x, normal.y, 0);
			uvs.push(0, 0);
			v++;
			vertices.push(x, y, 0);
			normals.push(normal.x, normal.y, 0);
			uvs.push(0, 1);
			v++;
		}

		// Add inner vertices for each segment
		for (i in 1...n) {
			var p0 = points[i - 1];
			var p1 = points[i];
			var normal0 = normalsArray[i - 1];
			var normal1 = normalsArray[i];
			var x0 = p0.x + normal0.x * halfWidth;
			var y0 = p0.y + normal0.y * halfWidth;
			var x1 = p1.x + normal1.x * halfWidth;
			var y1 = p1.y + normal1.y * halfWidth;
			vertices.push(x0, y0, 0);
			normals.push(normal0.x, normal0.y, 0);
			uvs.push(i - 1, 0);
			v++;
			vertices.push(x1, y1, 0);
			normals.push(normal1.x, normal1.y, 0);
			uvs.push(i, 0);
			v++;
			x0 = p0.x - normal0.x * halfWidth;
			y0 = p0.y - normal0.y * halfWidth;
			x1 = p1.x - normal1.x * halfWidth;
			y1 = p1.y - normal1.y * halfWidth;
			vertices.push(x1, y1, 0);
			normals.push(normal1.x, normal1.y, 0);
			uvs.push(i, 1);
			v++;
			vertices.push(x0, y0, 0);
			normals.push(normal0.x, normal0.y, 0);
			uvs.push(i - 1, 1);
			v++;
		}

		// Add last point vertices
		if (lineCap == "round") {
			// Add arc vertices for round cap
			var arcAngle = Math.PI / 2;
			var arcStep = arcAngle / arcDivisions;
			var normal = normalsArray[normalsArray.length - 1];
			for (i in 0...arcDivisions + 1) {
				var angle = arcStep * i;
				var x = points[points.length - 1].x + Math.cos(angle) * halfWidth * normal.x + Math.sin(angle) * halfWidth * normal.y;
				var y = points[points.length - 1].y + Math.cos(angle) * halfWidth * normal.y - Math.sin(angle) * halfWidth * normal.x;
				vertices.push(x, y, 0);
				normals.push(normal.x, normal.y, 0);
				uvs.push(points.length - 1, i / arcDivisions);
				v++;
			}
		} else if (lineCap == "square") {
			// Add square cap vertices
			var normal = normalsArray[normalsArray.length - 1];
			var x = points[points.length - 1].x + normal.x * halfWidth;
			var y = points[points.length - 1].y + normal.y * halfWidth;
			vertices.push(x, y, 0);
			normals.push(normal.x, normal.y, 0);
			uvs.push(points.length - 1, 0);
			v++;
			x = points[points.length - 1].x - normal.x * halfWidth;
			y = points[points.length - 1].y - normal.y * halfWidth;
			vertices.push(x, y, 0);
			normals.push(normal.x, normal.y, 0);
			uvs.push(points.length - 1, 1);
			v++;
		} else {
			// Add butt cap vertices
			var normal = normalsArray[normalsArray.length - 1];
			var x = points[points.length - 1].x + normal.x * halfWidth;
			var y = points[points.length - 1].y + normal.y * halfWidth;
			vertices.push(x, y, 0);
			normals.push(normal.x, normal.y, 0);
			uvs.push(points.length - 1, 0);
			v++;
			vertices.push(x, y, 0);
			normals.push(normal.x, normal.y, 0);
			uvs.push(points.length - 1, 1);
			v++;
		}

		// Add join vertices
		for (i in 1...n - 1) {
			var p0 = points[i - 1];
			var p1 = points[i];
			var p2 = points[i + 1];
			var normal0 = normalsArray[i - 1];
			var normal1 = normalsArray[i];
			var normal2 = normalsArray[i + 1];
			var x0 = p0.x + normal0.x * halfWidth;
			var y0 = p0.y + normal0.y * halfWidth;
			var x1 = p1.x + normal1.x * halfWidth;
			var y1 = p1.y + normal1.y * halfWidth;
			var x2 = p2.x + normal2.x * halfWidth;
			var y2 = p2.y + normal2.y * halfWidth;
			var miterLength = halfWidth * miterLimitFactor;

			// Calculate miter join point
			var miterPoint = getIntersection(p0, normal0, p2, normal2);

			// Check if miter length exceeds the miter limit
			var miterLengthSquared = (miterPoint.x - p1.x) * (miterPoint.x - p1.x) + (miterPoint.y - p1.y) * (miterPoint.y - p1.y);
			if (miterLengthSquared > miterLength * miterLength) {
				// If miter length exceeds the miter limit, use bevel join
				vertices.push(x1, y1, 0);
				normals.push(normal1.x, normal1.y, 0);
				uvs.push(i, 0);
				v++;
				vertices.push(x0, y0, 0);
				normals.push(normal0.x, normal0.y, 0);
				uvs.push(i - 1, 0);
				v++;
				vertices.push(x2, y2, 0);
				normals.push(normal2.x, normal2.y, 0);
				uvs.push(i + 1, 0);
				v++;
				vertices.push(x2, y2, 0);
				normals.push(normal2.x, normal2.y, 0);
				uvs.push(i + 1, 0);
				v++;
				vertices.push(x0, y0, 0);
				normals.push(normal0.x, normal0.y, 0);
				uvs.push(i - 1, 0);
				v++;
				vertices.push(x1, y1, 0);
				normals.push(normal1.x, normal1.y, 0);
				uvs.push(i, 0);
				v++;
			} else {
				// If miter length does not exceed the miter limit, use miter join
				vertices.push(x1, y1, 0);
				normals.push(normal1.x, normal1.y, 0);
				uvs.push(i, 0);
				v++;
				vertices.push(miterPoint.x, miterPoint.y, 0);
				normals.push((miterPoint.x - p1.x), (miterPoint.y - p1.y), 0);
				uvs.push(i, 0.5);
				v++;
				vertices.push(x0, y0, 0);
				normals.push(normal0.x, normal0.y, 0);
				uvs.push(i - 1, 0);
				v++;
				vertices.push(x0, y0, 0);
				normals.push(normal0.x, normal0.y, 0);
				uvs.push(i - 1, 0);
				v++;
				vertices.push(miterPoint.x, miterPoint.y, 0);
				normals.push((miterPoint.x - p1.x), (miterPoint.y - p1.y), 0);
				uvs.push(i, 0.5);
				v++;
				vertices.push(x1, y1, 0);
				normals.push(normal1.x, normal1.y, 0);
				uvs.push(i, 0);
				v++;
			}
			x0 = p0.x - normal0.x * halfWidth;
			y0 = p0.y - normal0.y * halfWidth;
			x1 = p1.x - normal1.x * halfWidth;
			y1 = p1.y - normal1.y * halfWidth;
			x2 = p2.x - normal2.x * halfWidth;
			y2 = p2.y - normal2.y * halfWidth;

			// Calculate miter join point
			miterPoint = getIntersection(p0, normal0, p2, normal2);

			// Check if miter length exceeds the miter limit
			miterLengthSquared = (miterPoint.x - p1.x) * (miterPoint.x - p1.x) + (miterPoint.y - p1.y) * (miterPoint.y - p1.y);
			if (miterLengthSquared > miterLength * miterLength) {
				// If miter length exceeds the miter limit, use bevel join
				vertices.push(x1, y1, 0);
				normals.push(normal1.x, normal1.y, 0);
				uvs.push(i, 1);
				v++;
				vertices.push(x2, y2, 0);
				normals.push(normal2.x, normal2.y, 0);
				uvs.push(i + 1, 1);
				v++;
				vertices.push(x0, y0, 0);
				normals.push(normal0.x, normal0.y, 0);
				uvs.push(i - 1, 1);
				v++;
				vertices.push(x0, y0, 0);
				normals.push(normal0.x, normal0.y, 0);
				uvs.push(i - 1, 1);
				v++;
				vertices.push(x2, y2, 0);
				normals.push(normal2.x, normal2.y, 0);
				uvs.push(i + 1, 1);
				v++;
				vertices.push(x1, y1, 0);
				normals.push(normal1.x, normal1.y, 0);
				uvs.push(i, 1);
				v++;
			} else {
				// If miter length does not exceed the miter limit, use miter join
				vertices.push(x1, y1, 0);
				normals.push(normal1.x, normal1.y, 0);
				uvs.push(i, 1);
				v++;
				vertices.push(x0, y0, 0);
				normals.push(normal0.x, normal0.y, 0);
				uvs.push(i - 1, 1);
				v++;
				vertices.push(miterPoint.x, miterPoint.y, 0);
				normals.push((miterPoint.x - p1.x), (miterPoint.y - p1.y), 0);
				uvs.push(i, 0.5);
				v++;
				vertices.push(miterPoint.
				v++;
				vertices.push(x0, y0, 0);
				normals.push(normal0.x, normal0.y, 0);
				uvs.push(i - 1, 1);
				v++;
				vertices.push(miterPoint.x, miterPoint.y, 0);
				normals.push((miterPoint.x - p1.x), (miterPoint.y - p1.y), 0);
				uvs.push(i, 0.5);
				v++;
				vertices.push(x1, y1, 0);
				normals.push(normal1.x, normal1.y, 0);
				uvs.push(i, 1);
				v++;
			}
		}

		if (minDistance != null && minDistance > 0) {
			// Merge vertices that are closer than minDistance
			var newVertices:Array<Float> = [];
			var newNormals:Array<Float> = [];
			var newUvs:Array<Float> = [];
			var j = 0;
			for (i in 0...v) {
				if (i > 0 && i < v - 1) {
					var dx = vertices[i * 3] - vertices[(i - 1) * 3];
					var dy = vertices[i * 3 + 1] - vertices[(i - 1) * 3 + 1];
					var distance = Math.sqrt(dx * dx + dy * dy);
					if (distance < minDistance) {
						continue;
					}
				}
				newVertices.push(vertices[i * 3], vertices[i * 3 + 1], vertices[i * 3 + 2]);
				newNormals.push(normals[i * 3], normals[i * 3 + 1], normals[i * 3 + 2]);
				newUvs.push(uvs[i * 2], uvs[i * 2 + 1]);
				j++;
			}
			vertices = newVertices;
			normals = newNormals;
			uvs = newUvs;
			v = j;
		}

		return v;
	}

	static function getIntersection(p0:Vector2, normal0:Vector2, p2:Vector2, normal2:Vector2):Vector2 {
		// Calculate the intersection point of two lines
		var denom = normal0.x * normal2.y - normal0.y * normal2.x;
		var x = (p0.x * normal0.y - normal0.x * p0.y) * normal2.x - (p2.x * normal2.y - normal2.x * p2.y) * normal0.x;
		var y = (p0.x * normal0.y - normal0.x * p0.y) * normal2.y - (p2.x * normal2.y - normal2.x * p2.y) * normal0.y;
		return new Vector2(x / denom, y / denom);
	}
}