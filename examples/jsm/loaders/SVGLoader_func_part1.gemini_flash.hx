import three.core.Box2;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Matrix3;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.core.ShapePath;
import three.extras.ShapeUtils;
import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;

class SVGLoader extends Loader {
	public var defaultDPI:Float = 90;
	public var defaultUnit:String = "px";

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String):Dynamic {
		var scope = this;

		var paths:Array<ShapePath> = [];
		var stylesheets:Map<String, Map<String, String>> = new Map();

		var transformStack:Array<Matrix3> = [];
		var tempTransform0 = new Matrix3();
		var tempTransform1 = new Matrix3();
		var tempTransform2 = new Matrix3();
		var tempTransform3 = new Matrix3();
		var tempV2 = new Vector2();
		var tempV3 = new Vector3();

		var currentTransform = new Matrix3();

		var xml = new DOMParser().parseFromString(text, "image/svg+xml");

		function parseNode(node:Dynamic, style:Map<String, String>) {
			if (node.nodeType != 1) return;

			var transform = getNodeTransform(node);
			var isDefsNode = false;

			var path:ShapePath = null;

			switch (node.nodeName) {
				case "svg":
					style = parseStyle(node, style);
					break;
				case "style":
					parseCSSStylesheet(node);
					break;
				case "g":
					style = parseStyle(node, style);
					break;
				case "path":
					style = parseStyle(node, style);
					if (node.hasAttribute("d")) path = parsePathNode(node);
					break;
				case "rect":
					style = parseStyle(node, style);
					path = parseRectNode(node);
					break;
				case "polygon":
					style = parseStyle(node, style);
					path = parsePolygonNode(node);
					break;
				case "polyline":
					style = parseStyle(node, style);
					path = parsePolylineNode(node);
					break;
				case "circle":
					style = parseStyle(node, style);
					path = parseCircleNode(node);
					break;
				case "ellipse":
					style = parseStyle(node, style);
					path = parseEllipseNode(node);
					break;
				case "line":
					style = parseStyle(node, style);
					path = parseLineNode(node);
					break;
				case "defs":
					isDefsNode = true;
					break;
				case "use":
					style = parseStyle(node, style);
					var href = node.getAttributeNS("http://www.w3.org/1999/xlink", "href") || "";
					var usedNodeId = href.substring(1);
					var usedNode = node.viewportElement.getElementById(usedNodeId);
					if (usedNode != null) {
						parseNode(usedNode, style);
					} else {
						console.warn("SVGLoader: 'use node' references non-existent node id: " + usedNodeId);
					}
					break;
				default:
					// console.log(node);
			}

			if (path != null) {
				if (style.get("fill") != null && style.get("fill") != "none") {
					path.color.setStyle(style.get("fill"), Color.SRGB);
				}
				transformPath(path, currentTransform);
				paths.push(path);
				path.userData = {node: node, style: style};
			}

			var childNodes = node.childNodes;
			for (i in 0...childNodes.length) {
				var node = childNodes[i];
				if (isDefsNode && node.nodeName != "style" && node.nodeName != "defs") {
					// Ignore everything in defs except CSS style definitions
					// and nested defs, because it is OK by the standard to have
					// <style/> there.
					continue;
				}
				parseNode(node, style);
			}

			if (transform != null) {
				transformStack.pop();
				if (transformStack.length > 0) {
					currentTransform.copy(transformStack[transformStack.length - 1]);
				} else {
					currentTransform.identity();
				}
			}
		}

		function parsePathNode(node:Dynamic):ShapePath {
			var path = new ShapePath();

			var point = new Vector2();
			var control = new Vector2();

			var firstPoint = new Vector2();
			var isFirstPoint = true;
			var doSetFirstPoint = false;

			var d = node.getAttribute("d");
			if (d == "" || d == "none") return null;

			// console.log(d);

			var commands = d.match(/[a-df-z][^a-df-z]*/ig);
			for (i in 0...commands.length) {
				var command = commands[i];

				var type = command.charAt(0);
				var data = command.slice(1).trim();

				if (isFirstPoint) {
					doSetFirstPoint = true;
					isFirstPoint = false;
				}

				var numbers:Array<Float>;

				switch (type) {
					case "M":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "H":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "V":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "L":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "C":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3],
									numbers[j + 4],
									numbers[j + 5]
								);
								control.x = numbers[j + 2];
								control.y = numbers[j + 3];
								point.x = numbers[j + 4];
								point.y = numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "S":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "Q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "T":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									numbers[j],
									numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = numbers[j];
								point.y = numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "A":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if start point == end point
								if (numbers[j + 5] == point.x && numbers[j + 6] == point.y) continue;
								var start = point.clone();
								point.x = numbers[j + 5];
								point.y = numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "m":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "h":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "v":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "l":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "c":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3],
									point.x + numbers[j + 4],
									point.y + numbers[j + 5]
								);
								control.x = point.x + numbers[j + 2];
								control.y = point.y + numbers[j + 3];
								point.x += numbers[j + 4];
								point.y += numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "s":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "t":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									point.x + numbers[j],
									point.y + numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = point.x + numbers[j];
								point.y = point.y + numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "a":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if no displacement
								if (numbers[j + 5] == 0 && numbers[j + 6] == 0) continue;
								var start = point.clone();
								point.x += numbers[j + 5];
								point.y += numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "Z":
					case "z":
						path.currentPath.autoClose = true;
						if (path.currentPath.curves.length > 0) {
							// Reset point to beginning of Path
							point.copy(firstPoint);
							path.currentPath.currentPoint.copy(point);
							isFirstPoint = true;
						}
						break;
					default:
						console.warn(command);
				}

				// console.log(type, parseFloats(data), parseFloats(data).length  )

				doSetFirstPoint = false;
			}

			return path;
		}

		function parseCSSStylesheet(node:Dynamic) {
			if (node.sheet == null || node.sheet.cssRules == null || node.sheet.cssRules.length == 0) return;
			for (i in 0...node.sheet.cssRules.length) {
				var stylesheet = node.sheet.cssRules[i];
				if (stylesheet.type != 1) continue;
				var selectorList = stylesheet.selectorText
					.split(/,/gm)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (j in 0...selectorList.length) {
					// Remove empty rules
					var definitions = new Map(Object.entries(stylesheet.style).filter(v -> v[1] != ""));
					stylesheets.set(selectorList[j], stylesheets.get(selectorList[j]) != null ? stylesheets.get(selectorList[j]).merge(definitions) : definitions);
				}
			}
		}

		/**
		 * https://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes
		 * https://mortoray.com/2017/02/16/rendering-an-svg-elliptical-arc-as-bezier-curves/ Appendix: Endpoint to center arc conversion
		 * From
		 * rx ry x-axis-rotation large-arc-flag sweep-flag x y
		 * To
		 * aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation
		 */

		function parseArcCommand(path:ShapePath, rx:Float, ry:Float, x_axis_rotation:Float, large_arc_flag:Float, sweep_flag:Float, start:Vector2, end:Vector2) {
			if (rx == 0 || ry == 0) {
				// draw a line if either of the radii == 0
				path.lineTo(end.x, end.y);
				return;
			}

			x_axis_rotation = x_axis_rotation * Math.PI / 180;

			// Ensure radii are positive
			rx = Math.abs(rx);
			ry = Math.abs(ry);

			// Compute (x1', y1')
			var dx2 = (start.x - end.x) / 2.0;
			var dy2 = (start.y - end.y) / 2.0;
			var x1p = Math.cos(x_axis_rotation) * dx2 + Math.sin(x_axis_rotation) * dy2;
			var y1p = - Math.sin(x_axis_rotation) * dx2 + Math.cos(x_axis_rotation) * dy2;

			// Compute (cx', cy')
			var rxs = rx * rx;
			var rys = ry * ry;
			var x1ps = x1p * x1p;
			var y1ps = y1p * y1p;

			// Ensure radii are large enough
			var cr = x1ps / rxs + y1ps / rys;

			if (cr > 1) {
				// scale up rx,ry equally so cr == 1
				var s = Math.sqrt(cr);
				rx = s * rx;
				ry = s * ry;
				rxs = rx * rx;
				rys = ry * ry;
			}

			var dq = (rxs * y1ps + rys * x1ps);
			var pq = (rxs * rys - dq) / dq;
			var q = Math.sqrt(Math.max(0, pq));
			if (large_arc_flag == sweep_flag) q = - q;
			var cxp = q * rx * y1p / ry;
			var cyp = - q * ry * x1p / rx;

			// Step 3: Compute (cx, cy) from (cx', cy')
			var cx = Math.cos(x_axis_rotation) * cxp - Math.sin(x_axis_rotation) * cyp + (start.x + end.x) / 2;
			var cy = Math.sin(x_axis_rotation) * cxp + Math.cos(x_axis_rotation) * cyp + (start.y + end.y) / 2;

			// Step 4: Compute θ1 and Δθ
			var theta = svgAngle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
			var delta = svgAngle((x1p - cxp) / rx, (y1p - cyp) / ry, (- x1p - cxp) / rx, (- y1p - cyp) / ry) % (Math.PI * 2);

			path.currentPath.absellipse(cx, cy, rx, ry, theta, theta + delta, sweep_flag == 0, x_axis_rotation);
		}

		function svgAngle(ux:Float, uy:Float, vx:Float, vy:Float):Float {
			var dot = ux * vx + uy * vy;
			var len = Math.sqrt(ux * ux + uy * uy) * Math.sqrt(vx * vx + vy * vy);
			var ang = Math.acos(Math.max(- 1, Math.min(1, dot / len))); // floating point precision, slightly over values appear
			if ((ux * vy - uy * vx) < 0) ang = - ang;
			return ang;
		}

		/*
		* According to https://www.w3.org/TR/SVG/shapes.html#RectElementRXAttribute
		* rounded corner should be rendered to elliptical arc, but bezier curve does the job well enough
		*/
		function parseRectNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("x") || "0");
			var y = parseFloatWithUnits(node.getAttribute("y") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || node.getAttribute("ry") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || node.getAttribute("rx") || "0");
			var w = parseFloatWithUnits(node.getAttribute("width"));
			var h = parseFloatWithUnits(node.getAttribute("height"));

			// Ellipse arc to Bezier approximation Coefficient (Inversed). See:
			// https://spencermortensen.com/articles/bezier-circle/
			var bci = 1 - 0.551915024494;

			var path = new ShapePath();

			// top left
			path.moveTo(x + rx, y);

			// top right
			path.lineTo(x + w - rx, y);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w - rx * bci,
					y,
					x + w,
					y + ry * bci,
					x + w,
					y + ry
				);
			}

			// bottom right
			path.lineTo(x + w, y + h - ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w,
					y + h - ry * bci,
					x + w - rx * bci,
					y + h,
					x + w - rx,
					y + h
				);
			}

			// bottom left
			path.lineTo(x + rx, y + h);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + rx * bci,
					y + h,
					x,
					y + h - ry * bci,
					x,
					y + h - ry
				);
			}

			// back to top left
			path.lineTo(x, y + ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(x, y + ry * bci, x + rx * bci, y, x + rx, y);
			}

			return path;
		}

		function parsePolygonNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = true;

			return path;
		}

		function parsePolylineNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = false;

			return path;
		}

		function parseCircleNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var r = parseFloatWithUnits(node.getAttribute("r") || "0");

			var subpath = new Path();
			subpath.absarc(x, y, r, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseEllipseNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || "0");

			var subpath = new Path();
			subpath.absellipse(x, y, rx, ry, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseLineNode(node:Dynamic):ShapePath {
			var x1 = parseFloatWithUnits(node.getAttribute("x1") || "0");
			var y1 = parseFloatWithUnits(node.getAttribute("y1") || "0");
			var x2 = parseFloatWithUnits(node.getAttribute("x2") || "0");
			var y2 = parseFloatWithUnits(node.getAttribute("y2") || "0");

			var path = new ShapePath();
			path.moveTo(x1, y1);
			path.lineTo(x2, y2);
			path.currentPath.autoClose = false;

			return path;
		}

		//

		function parseStyle(node:Dynamic, style:Map<String, String>):Map<String, String> {
			style = style.copy(); // clone style

			var stylesheetStyles:Map<String, String> = new Map();

			if (node.hasAttribute("class")) {
				var classSelectors = node.getAttribute("class")
					.split(/\s/)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (i in 0...classSelectors.length) {
					stylesheetStyles = stylesheets.get("." + classSelectors[i]) != null ? stylesheetStyles.merge(stylesheets.get("." + classSelectors[i])) : stylesheetStyles;
				}
			}

			if (node.hasAttribute("id")) {
				stylesheetStyles = stylesheets.get("#" + node.getAttribute("id")) != null ? stylesheetStyles.merge(stylesheets.get("#" + node.getAttribute("id"))) : stylesheetStyles;
			}

			function addStyle(svgName:String, jsName:String, adjustFunction:Dynamic->Dynamic = null) {
				if (adjustFunction == null) adjustFunction = function(v) {
					if (v.startsWith("url")) console.warn("SVGLoader: url access in attributes is not implemented.");
					return v;
				};
				if (node.hasAttribute(svgName)) style.set(jsName, adjustFunction(node.getAttribute(svgName)));
				if (stylesheetStyles.get(svgName) != null) style.set(jsName, adjustFunction(stylesheetStyles.get(svgName)));
				if (node.style != null && node.style[svgName] != "") style.set(jsName, adjustFunction(node.style[svgName]));
			}

			function clamp(v:String):Float {
				return Math.max(0, Math.min(1, parseFloatWithUnits(v)));
			}

			function positive(v:String):Float {
				return Math.max(0, parseFloatWithUnits(v));
			}

			addStyle("fill", "fill");
			addStyle("fill-opacity", "fillOpacity", clamp);
			addStyle("fill-rule", "fillRule");
			addStyle("opacity", "opacity", clamp);
			addStyle("stroke", "stroke");
			addStyle("stroke-opacity", "strokeOpacity", clamp);
			addStyle("stroke-width", "strokeWidth", positive);
			addStyle("stroke-linejoin", "strokeLineJoin");
			addStyle("stroke-linecap", "strokeLineCap");
			addStyle("stroke-miterlimit", "strokeMiterLimit", positive);
			addStyle("visibility", "visibility");

			return style;
		}

		// http://www.w3.org/TR/SVG11/implnote.html#PathElementImplementationNotes

		function getReflection(a:Float, b:Float):Float {
			return a - (b - a);
		}

		// from https://github.com/ppvg/svg-numbers (MIT License)

		function parseFloats(input:String, flags:Array<Int> = [], stride:Int = 1):Array<Float> {
			if (typeof input != "string") {
				throw new TypeError("Invalid input: " + typeof input);
			}

			// Character groups

import three.core.Box2;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Matrix3;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.core.ShapePath;
import three.extras.ShapeUtils;
import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;

class SVGLoader extends Loader {
	public var defaultDPI:Float = 90;
	public var defaultUnit:String = "px";

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String):Dynamic {
		var scope = this;

		var paths:Array<ShapePath> = [];
		var stylesheets:Map<String, Map<String, String>> = new Map();

		var transformStack:Array<Matrix3> = [];
		var tempTransform0 = new Matrix3();
		var tempTransform1 = new Matrix3();
		var tempTransform2 = new Matrix3();
		var tempTransform3 = new Matrix3();
		var tempV2 = new Vector2();
		var tempV3 = new Vector3();

		var currentTransform = new Matrix3();

		var xml = new DOMParser().parseFromString(text, "image/svg+xml");

		function parseNode(node:Dynamic, style:Map<String, String>) {
			if (node.nodeType != 1) return;

			var transform = getNodeTransform(node);
			var isDefsNode = false;

			var path:ShapePath = null;

			switch (node.nodeName) {
				case "svg":
					style = parseStyle(node, style);
					break;
				case "style":
					parseCSSStylesheet(node);
					break;
				case "g":
					style = parseStyle(node, style);
					break;
				case "path":
					style = parseStyle(node, style);
					if (node.hasAttribute("d")) path = parsePathNode(node);
					break;
				case "rect":
					style = parseStyle(node, style);
					path = parseRectNode(node);
					break;
				case "polygon":
					style = parseStyle(node, style);
					path = parsePolygonNode(node);
					break;
				case "polyline":
					style = parseStyle(node, style);
					path = parsePolylineNode(node);
					break;
				case "circle":
					style = parseStyle(node, style);
					path = parseCircleNode(node);
					break;
				case "ellipse":
					style = parseStyle(node, style);
					path = parseEllipseNode(node);
					break;
				case "line":
					style = parseStyle(node, style);
					path = parseLineNode(node);
					break;
				case "defs":
					isDefsNode = true;
					break;
				case "use":
					style = parseStyle(node, style);
					var href = node.getAttributeNS("http://www.w3.org/1999/xlink", "href") || "";
					var usedNodeId = href.substring(1);
					var usedNode = node.viewportElement.getElementById(usedNodeId);
					if (usedNode != null) {
						parseNode(usedNode, style);
					} else {
						console.warn("SVGLoader: 'use node' references non-existent node id: " + usedNodeId);
					}
					break;
				default:
					// console.log(node);
			}

			if (path != null) {
				if (style.get("fill") != null && style.get("fill") != "none") {
					path.color.setStyle(style.get("fill"), Color.SRGB);
				}
				transformPath(path, currentTransform);
				paths.push(path);
				path.userData = {node: node, style: style};
			}

			var childNodes = node.childNodes;
			for (i in 0...childNodes.length) {
				var node = childNodes[i];
				if (isDefsNode && node.nodeName != "style" && node.nodeName != "defs") {
					// Ignore everything in defs except CSS style definitions
					// and nested defs, because it is OK by the standard to have
					// <style/> there.
					continue;
				}
				parseNode(node, style);
			}

			if (transform != null) {
				transformStack.pop();
				if (transformStack.length > 0) {
					currentTransform.copy(transformStack[transformStack.length - 1]);
				} else {
					currentTransform.identity();
				}
			}
		}

		function parsePathNode(node:Dynamic):ShapePath {
			var path = new ShapePath();

			var point = new Vector2();
			var control = new Vector2();

			var firstPoint = new Vector2();
			var isFirstPoint = true;
			var doSetFirstPoint = false;

			var d = node.getAttribute("d");
			if (d == "" || d == "none") return null;

			// console.log(d);

			var commands = d.match(/[a-df-z][^a-df-z]*/ig);
			for (i in 0...commands.length) {
				var command = commands[i];

				var type = command.charAt(0);
				var data = command.slice(1).trim();

				if (isFirstPoint) {
					doSetFirstPoint = true;
					isFirstPoint = false;
				}

				var numbers:Array<Float>;

				switch (type) {
					case "M":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "H":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "V":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "L":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "C":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3],
									numbers[j + 4],
									numbers[j + 5]
								);
								control.x = numbers[j + 2];
								control.y = numbers[j + 3];
								point.x = numbers[j + 4];
								point.y = numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "S":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "Q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "T":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									numbers[j],
									numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = numbers[j];
								point.y = numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "A":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if start point == end point
								if (numbers[j + 5] == point.x && numbers[j + 6] == point.y) continue;
								var start = point.clone();
								point.x = numbers[j + 5];
								point.y = numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "m":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "h":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "v":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "l":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "c":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3],
									point.x + numbers[j + 4],
									point.y + numbers[j + 5]
								);
								control.x = point.x + numbers[j + 2];
								control.y = point.y + numbers[j + 3];
								point.x += numbers[j + 4];
								point.y += numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "s":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "t":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									point.x + numbers[j],
									point.y + numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = point.x + numbers[j];
								point.y = point.y + numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "a":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if no displacement
								if (numbers[j + 5] == 0 && numbers[j + 6] == 0) continue;
								var start = point.clone();
								point.x += numbers[j + 5];
								point.y += numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "Z":
					case "z":
						path.currentPath.autoClose = true;
						if (path.currentPath.curves.length > 0) {
							// Reset point to beginning of Path
							point.copy(firstPoint);
							path.currentPath.currentPoint.copy(point);
							isFirstPoint = true;
						}
						break;
					default:
						console.warn(command);
				}

				// console.log(type, parseFloats(data), parseFloats(data).length  )

				doSetFirstPoint = false;
			}

			return path;
		}

		function parseCSSStylesheet(node:Dynamic) {
			if (node.sheet == null || node.sheet.cssRules == null || node.sheet.cssRules.length == 0) return;
			for (i in 0...node.sheet.cssRules.length) {
				var stylesheet = node.sheet.cssRules[i];
				if (stylesheet.type != 1) continue;
				var selectorList = stylesheet.selectorText
					.split(/,/gm)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (j in 0...selectorList.length) {
					// Remove empty rules
					var definitions = new Map(Object.entries(stylesheet.style).filter(v -> v[1] != ""));
					stylesheets.set(selectorList[j], stylesheets.get(selectorList[j]) != null ? stylesheets.get(selectorList[j]).merge(definitions) : definitions);
				}
			}
		}

		/**
		 * https://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes
		 * https://mortoray.com/2017/02/16/rendering-an-svg-elliptical-arc-as-bezier-curves/ Appendix: Endpoint to center arc conversion
		 * From
		 * rx ry x-axis-rotation large-arc-flag sweep-flag x y
		 * To
		 * aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation
		 */

		function parseArcCommand(path:ShapePath, rx:Float, ry:Float, x_axis_rotation:Float, large_arc_flag:Float, sweep_flag:Float, start:Vector2, end:Vector2) {
			if (rx == 0 || ry == 0) {
				// draw a line if either of the radii == 0
				path.lineTo(end.x, end.y);
				return;
			}

			x_axis_rotation = x_axis_rotation * Math.PI / 180;

			// Ensure radii are positive
			rx = Math.abs(rx);
			ry = Math.abs(ry);

			// Compute (x1', y1')
			var dx2 = (start.x - end.x) / 2.0;
			var dy2 = (start.y - end.y) / 2.0;
			var x1p = Math.cos(x_axis_rotation) * dx2 + Math.sin(x_axis_rotation) * dy2;
			var y1p = - Math.sin(x_axis_rotation) * dx2 + Math.cos(x_axis_rotation) * dy2;

			// Compute (cx', cy')
			var rxs = rx * rx;
			var rys = ry * ry;
			var x1ps = x1p * x1p;
			var y1ps = y1p * y1p;

			// Ensure radii are large enough
			var cr = x1ps / rxs + y1ps / rys;

			if (cr > 1) {
				// scale up rx,ry equally so cr == 1
				var s = Math.sqrt(cr);
				rx = s * rx;
				ry = s * ry;
				rxs = rx * rx;
				rys = ry * ry;
			}

			var dq = (rxs * y1ps + rys * x1ps);
			var pq = (rxs * rys - dq) / dq;
			var q = Math.sqrt(Math.max(0, pq));
			if (large_arc_flag == sweep_flag) q = - q;
			var cxp = q * rx * y1p / ry;
			var cyp = - q * ry * x1p / rx;

			// Step 3: Compute (cx, cy) from (cx', cy')
			var cx = Math.cos(x_axis_rotation) * cxp - Math.sin(x_axis_rotation) * cyp + (start.x + end.x) / 2;
			var cy = Math.sin(x_axis_rotation) * cxp + Math.cos(x_axis_rotation) * cyp + (start.y + end.y) / 2;

			// Step 4: Compute θ1 and Δθ
			var theta = svgAngle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
			var delta = svgAngle((x1p - cxp) / rx, (y1p - cyp) / ry, (- x1p - cxp) / rx, (- y1p - cyp) / ry) % (Math.PI * 2);

			path.currentPath.absellipse(cx, cy, rx, ry, theta, theta + delta, sweep_flag == 0, x_axis_rotation);
		}

		function svgAngle(ux:Float, uy:Float, vx:Float, vy:Float):Float {
			var dot = ux * vx + uy * vy;
			var len = Math.sqrt(ux * ux + uy * uy) * Math.sqrt(vx * vx + vy * vy);
			var ang = Math.acos(Math.max(- 1, Math.min(1, dot / len))); // floating point precision, slightly over values appear
			if ((ux * vy - uy * vx) < 0) ang = - ang;
			return ang;
		}

		/*
		* According to https://www.w3.org/TR/SVG/shapes.html#RectElementRXAttribute
		* rounded corner should be rendered to elliptical arc, but bezier curve does the job well enough
		*/
		function parseRectNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("x") || "0");
			var y = parseFloatWithUnits(node.getAttribute("y") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || node.getAttribute("ry") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || node.getAttribute("rx") || "0");
			var w = parseFloatWithUnits(node.getAttribute("width"));
			var h = parseFloatWithUnits(node.getAttribute("height"));

			// Ellipse arc to Bezier approximation Coefficient (Inversed). See:
			// https://spencermortensen.com/articles/bezier-circle/
			var bci = 1 - 0.551915024494;

			var path = new ShapePath();

			// top left
			path.moveTo(x + rx, y);

			// top right
			path.lineTo(x + w - rx, y);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w - rx * bci,
					y,
					x + w,
					y + ry * bci,
					x + w,
					y + ry
				);
			}

			// bottom right
			path.lineTo(x + w, y + h - ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w,
					y + h - ry * bci,
					x + w - rx * bci,
					y + h,
					x + w - rx,
					y + h
				);
			}

			// bottom left
			path.lineTo(x + rx, y + h);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + rx * bci,
					y + h,
					x,
					y + h - ry * bci,
					x,
					y + h - ry
				);
			}

			// back to top left
			path.lineTo(x, y + ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(x, y + ry * bci, x + rx * bci, y, x + rx, y);
			}

			return path;
		}

		function parsePolygonNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = true;

			return path;
		}

		function parsePolylineNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = false;

			return path;
		}

		function parseCircleNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var r = parseFloatWithUnits(node.getAttribute("r") || "0");

			var subpath = new Path();
			subpath.absarc(x, y, r, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseEllipseNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || "0");

			var subpath = new Path();
			subpath.absellipse(x, y, rx, ry, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseLineNode(node:Dynamic):ShapePath {
			var x1 = parseFloatWithUnits(node.getAttribute("x1") || "0");
			var y1 = parseFloatWithUnits(node.getAttribute("y1") || "0");
			var x2 = parseFloatWithUnits(node.getAttribute("x2") || "0");
			var y2 = parseFloatWithUnits(node.getAttribute("y2") || "0");

			var path = new ShapePath();
			path.moveTo(x1, y1);
			path.lineTo(x2, y2);
			path.currentPath.autoClose = false;

			return path;
		}

		//

		function parseStyle(node:Dynamic, style:Map<String, String>):Map<String, String> {
			style = style.copy(); // clone style

			var stylesheetStyles:Map<String, String> = new Map();

			if (node.hasAttribute("class")) {
				var classSelectors = node.getAttribute("class")
					.split(/\s/)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (i in 0...classSelectors.length) {
					stylesheetStyles = stylesheets.get("." + classSelectors[i]) != null ? stylesheetStyles.merge(stylesheets.get("." + classSelectors[i])) : stylesheetStyles;
				}
			}

			if (node.hasAttribute("id")) {
				stylesheetStyles = stylesheets.get("#" + node.getAttribute("id")) != null ? stylesheetStyles.merge(stylesheets.get("#" + node.getAttribute("id"))) : stylesheetStyles;
			}

			function addStyle(svgName:String, jsName:String, adjustFunction:Dynamic->Dynamic = null) {
				if (adjustFunction == null) adjustFunction = function(v) {
					if (v.startsWith("url")) console.warn("SVGLoader: url access in attributes is not implemented.");
					return v;
				};
				if (node.hasAttribute(svgName)) style.set(jsName, adjustFunction(node.getAttribute(svgName)));
				if (stylesheetStyles.get(svgName) != null) style.set(jsName, adjustFunction(stylesheetStyles.get(svgName)));
				if (node.style != null && node.style[svgName] != "") style.set(jsName, adjustFunction(node.style[svgName]));
			}

			function clamp(v:String):Float {
				return Math.max(0, Math.min(1, parseFloatWithUnits(v)));
			}

			function positive(v:String):Float {
				return Math.max(0, parseFloatWithUnits(v));
			}

			addStyle("fill", "fill");
			addStyle("fill-opacity", "fillOpacity", clamp);
			addStyle("fill-rule", "fillRule");
			addStyle("opacity", "opacity", clamp);
			addStyle("stroke", "stroke");
			addStyle("stroke-opacity", "strokeOpacity", clamp);
			addStyle("stroke-width", "strokeWidth", positive);
			addStyle("stroke-linejoin", "strokeLineJoin");
			addStyle("stroke-linecap", "strokeLineCap");
			addStyle("stroke-miterlimit", "strokeMiterLimit", positive);
			addStyle("visibility", "visibility");

			return style;
		}

		// http://www.w3.org/TR/SVG11/implnote.html#PathElementImplementationNotes

		function getReflection(a:Float, b:Float):Float {
			return a - (b - a);
		}

		// from https://github.com/ppvg/svg-numbers (MIT License)

		function parseFloats(input:String, flags:Array<Int> = [], stride:Int = 1):Array<Float> {
			if (typeof input != "string") {
				throw new TypeError("Invalid input: " + typeof input);
			}

			// Character groups

import three.core.Box2;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Matrix3;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.core.ShapePath;
import three.extras.ShapeUtils;
import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;

class SVGLoader extends Loader {
	public var defaultDPI:Float = 90;
	public var defaultUnit:String = "px";

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String):Dynamic {
		var scope = this;

		var paths:Array<ShapePath> = [];
		var stylesheets:Map<String, Map<String, String>> = new Map();

		var transformStack:Array<Matrix3> = [];
		var tempTransform0 = new Matrix3();
		var tempTransform1 = new Matrix3();
		var tempTransform2 = new Matrix3();
		var tempTransform3 = new Matrix3();
		var tempV2 = new Vector2();
		var tempV3 = new Vector3();

		var currentTransform = new Matrix3();

		var xml = new DOMParser().parseFromString(text, "image/svg+xml");

		function parseNode(node:Dynamic, style:Map<String, String>) {
			if (node.nodeType != 1) return;

			var transform = getNodeTransform(node);
			var isDefsNode = false;

			var path:ShapePath = null;

			switch (node.nodeName) {
				case "svg":
					style = parseStyle(node, style);
					break;
				case "style":
					parseCSSStylesheet(node);
					break;
				case "g":
					style = parseStyle(node, style);
					break;
				case "path":
					style = parseStyle(node, style);
					if (node.hasAttribute("d")) path = parsePathNode(node);
					break;
				case "rect":
					style = parseStyle(node, style);
					path = parseRectNode(node);
					break;
				case "polygon":
					style = parseStyle(node, style);
					path = parsePolygonNode(node);
					break;
				case "polyline":
					style = parseStyle(node, style);
					path = parsePolylineNode(node);
					break;
				case "circle":
					style = parseStyle(node, style);
					path = parseCircleNode(node);
					break;
				case "ellipse":
					style = parseStyle(node, style);
					path = parseEllipseNode(node);
					break;
				case "line":
					style = parseStyle(node, style);
					path = parseLineNode(node);
					break;
				case "defs":
					isDefsNode = true;
					break;
				case "use":
					style = parseStyle(node, style);
					var href = node.getAttributeNS("http://www.w3.org/1999/xlink", "href") || "";
					var usedNodeId = href.substring(1);
					var usedNode = node.viewportElement.getElementById(usedNodeId);
					if (usedNode != null) {
						parseNode(usedNode, style);
					} else {
						console.warn("SVGLoader: 'use node' references non-existent node id: " + usedNodeId);
					}
					break;
				default:
					// console.log(node);
			}

			if (path != null) {
				if (style.get("fill") != null && style.get("fill") != "none") {
					path.color.setStyle(style.get("fill"), Color.SRGB);
				}
				transformPath(path, currentTransform);
				paths.push(path);
				path.userData = {node: node, style: style};
			}

			var childNodes = node.childNodes;
			for (i in 0...childNodes.length) {
				var node = childNodes[i];
				if (isDefsNode && node.nodeName != "style" && node.nodeName != "defs") {
					// Ignore everything in defs except CSS style definitions
					// and nested defs, because it is OK by the standard to have
					// <style/> there.
					continue;
				}
				parseNode(node, style);
			}

			if (transform != null) {
				transformStack.pop();
				if (transformStack.length > 0) {
					currentTransform.copy(transformStack[transformStack.length - 1]);
				} else {
					currentTransform.identity();
				}
			}
		}

		function parsePathNode(node:Dynamic):ShapePath {
			var path = new ShapePath();

			var point = new Vector2();
			var control = new Vector2();

			var firstPoint = new Vector2();
			var isFirstPoint = true;
			var doSetFirstPoint = false;

			var d = node.getAttribute("d");
			if (d == "" || d == "none") return null;

			// console.log(d);

			var commands = d.match(/[a-df-z][^a-df-z]*/ig);
			for (i in 0...commands.length) {
				var command = commands[i];

				var type = command.charAt(0);
				var data = command.slice(1).trim();

				if (isFirstPoint) {
					doSetFirstPoint = true;
					isFirstPoint = false;
				}

				var numbers:Array<Float>;

				switch (type) {
					case "M":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "H":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "V":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "L":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "C":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3],
									numbers[j + 4],
									numbers[j + 5]
								);
								control.x = numbers[j + 2];
								control.y = numbers[j + 3];
								point.x = numbers[j + 4];
								point.y = numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "S":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "Q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "T":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									numbers[j],
									numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = numbers[j];
								point.y = numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "A":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if start point == end point
								if (numbers[j + 5] == point.x && numbers[j + 6] == point.y) continue;
								var start = point.clone();
								point.x = numbers[j + 5];
								point.y = numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "m":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "h":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "v":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "l":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "c":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3],
									point.x + numbers[j + 4],
									point.y + numbers[j + 5]
								);
								control.x = point.x + numbers[j + 2];
								control.y = point.y + numbers[j + 3];
								point.x += numbers[j + 4];
								point.y += numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "s":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "t":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									point.x + numbers[j],
									point.y + numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = point.x + numbers[j];
								point.y = point.y + numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "a":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if no displacement
								if (numbers[j + 5] == 0 && numbers[j + 6] == 0) continue;
								var start = point.clone();
								point.x += numbers[j + 5];
								point.y += numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "Z":
					case "z":
						path.currentPath.autoClose = true;
						if (path.currentPath.curves.length > 0) {
							// Reset point to beginning of Path
							point.copy(firstPoint);
							path.currentPath.currentPoint.copy(point);
							isFirstPoint = true;
						}
						break;
					default:
						console.warn(command);
				}

				// console.log(type, parseFloats(data), parseFloats(data).length  )

				doSetFirstPoint = false;
			}

			return path;
		}

		function parseCSSStylesheet(node:Dynamic) {
			if (node.sheet == null || node.sheet.cssRules == null || node.sheet.cssRules.length == 0) return;
			for (i in 0...node.sheet.cssRules.length) {
				var stylesheet = node.sheet.cssRules[i];
				if (stylesheet.type != 1) continue;
				var selectorList = stylesheet.selectorText
					.split(/,/gm)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (j in 0...selectorList.length) {
					// Remove empty rules
					var definitions = new Map(Object.entries(stylesheet.style).filter(v -> v[1] != ""));
					stylesheets.set(selectorList[j], stylesheets.get(selectorList[j]) != null ? stylesheets.get(selectorList[j]).merge(definitions) : definitions);
				}
			}
		}

		/**
		 * https://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes
		 * https://mortoray.com/2017/02/16/rendering-an-svg-elliptical-arc-as-bezier-curves/ Appendix: Endpoint to center arc conversion
		 * From
		 * rx ry x-axis-rotation large-arc-flag sweep-flag x y
		 * To
		 * aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation
		 */

		function parseArcCommand(path:ShapePath, rx:Float, ry:Float, x_axis_rotation:Float, large_arc_flag:Float, sweep_flag:Float, start:Vector2, end:Vector2) {
			if (rx == 0 || ry == 0) {
				// draw a line if either of the radii == 0
				path.lineTo(end.x, end.y);
				return;
			}

			x_axis_rotation = x_axis_rotation * Math.PI / 180;

			// Ensure radii are positive
			rx = Math.abs(rx);
			ry = Math.abs(ry);

			// Compute (x1', y1')
			var dx2 = (start.x - end.x) / 2.0;
			var dy2 = (start.y - end.y) / 2.0;
			var x1p = Math.cos(x_axis_rotation) * dx2 + Math.sin(x_axis_rotation) * dy2;
			var y1p = - Math.sin(x_axis_rotation) * dx2 + Math.cos(x_axis_rotation) * dy2;

			// Compute (cx', cy')
			var rxs = rx * rx;
			var rys = ry * ry;
			var x1ps = x1p * x1p;
			var y1ps = y1p * y1p;

			// Ensure radii are large enough
			var cr = x1ps / rxs + y1ps / rys;

			if (cr > 1) {
				// scale up rx,ry equally so cr == 1
				var s = Math.sqrt(cr);
				rx = s * rx;
				ry = s * ry;
				rxs = rx * rx;
				rys = ry * ry;
			}

			var dq = (rxs * y1ps + rys * x1ps);
			var pq = (rxs * rys - dq) / dq;
			var q = Math.sqrt(Math.max(0, pq));
			if (large_arc_flag == sweep_flag) q = - q;
			var cxp = q * rx * y1p / ry;
			var cyp = - q * ry * x1p / rx;

			// Step 3: Compute (cx, cy) from (cx', cy')
			var cx = Math.cos(x_axis_rotation) * cxp - Math.sin(x_axis_rotation) * cyp + (start.x + end.x) / 2;
			var cy = Math.sin(x_axis_rotation) * cxp + Math.cos(x_axis_rotation) * cyp + (start.y + end.y) / 2;

			// Step 4: Compute θ1 and Δθ
			var theta = svgAngle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
			var delta = svgAngle((x1p - cxp) / rx, (y1p - cyp) / ry, (- x1p - cxp) / rx, (- y1p - cyp) / ry) % (Math.PI * 2);

			path.currentPath.absellipse(cx, cy, rx, ry, theta, theta + delta, sweep_flag == 0, x_axis_rotation);
		}

		function svgAngle(ux:Float, uy:Float, vx:Float, vy:Float):Float {
			var dot = ux * vx + uy * vy;
			var len = Math.sqrt(ux * ux + uy * uy) * Math.sqrt(vx * vx + vy * vy);
			var ang = Math.acos(Math.max(- 1, Math.min(1, dot / len))); // floating point precision, slightly over values appear
			if ((ux * vy - uy * vx) < 0) ang = - ang;
			return ang;
		}

		/*
		* According to https://www.w3.org/TR/SVG/shapes.html#RectElementRXAttribute
		* rounded corner should be rendered to elliptical arc, but bezier curve does the job well enough
		*/
		function parseRectNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("x") || "0");
			var y = parseFloatWithUnits(node.getAttribute("y") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || node.getAttribute("ry") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || node.getAttribute("rx") || "0");
			var w = parseFloatWithUnits(node.getAttribute("width"));
			var h = parseFloatWithUnits(node.getAttribute("height"));

			// Ellipse arc to Bezier approximation Coefficient (Inversed). See:
			// https://spencermortensen.com/articles/bezier-circle/
			var bci = 1 - 0.551915024494;

			var path = new ShapePath();

			// top left
			path.moveTo(x + rx, y);

			// top right
			path.lineTo(x + w - rx, y);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w - rx * bci,
					y,
					x + w,
					y + ry * bci,
					x + w,
					y + ry
				);
			}

			// bottom right
			path.lineTo(x + w, y + h - ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w,
					y + h - ry * bci,
					x + w - rx * bci,
					y + h,
					x + w - rx,
					y + h
				);
			}

			// bottom left
			path.lineTo(x + rx, y + h);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + rx * bci,
					y + h,
					x,
					y + h - ry * bci,
					x,
					y + h - ry
				);
			}

			// back to top left
			path.lineTo(x, y + ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(x, y + ry * bci, x + rx * bci, y, x + rx, y);
			}

			return path;
		}

		function parsePolygonNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = true;

			return path;
		}

		function parsePolylineNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = false;

			return path;
		}

		function parseCircleNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var r = parseFloatWithUnits(node.getAttribute("r") || "0");

			var subpath = new Path();
			subpath.absarc(x, y, r, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseEllipseNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || "0");

			var subpath = new Path();
			subpath.absellipse(x, y, rx, ry, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseLineNode(node:Dynamic):ShapePath {
			var x1 = parseFloatWithUnits(node.getAttribute("x1") || "0");
			var y1 = parseFloatWithUnits(node.getAttribute("y1") || "0");
			var x2 = parseFloatWithUnits(node.getAttribute("x2") || "0");
			var y2 = parseFloatWithUnits(node.getAttribute("y2") || "0");

			var path = new ShapePath();
			path.moveTo(x1, y1);
			path.lineTo(x2, y2);
			path.currentPath.autoClose = false;

			return path;
		}

		//

		function parseStyle(node:Dynamic, style:Map<String, String>):Map<String, String> {
			style = style.copy(); // clone style

			var stylesheetStyles:Map<String, String> = new Map();

			if (node.hasAttribute("class")) {
				var classSelectors = node.getAttribute("class")
					.split(/\s/)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (i in 0...classSelectors.length) {
					stylesheetStyles = stylesheets.get("." + classSelectors[i]) != null ? stylesheetStyles.merge(stylesheets.get("." + classSelectors[i])) : stylesheetStyles;
				}
			}

			if (node.hasAttribute("id")) {
				stylesheetStyles = stylesheets.get("#" + node.getAttribute("id")) != null ? stylesheetStyles.merge(stylesheets.get("#" + node.getAttribute("id"))) : stylesheetStyles;
			}

			function addStyle(svgName:String, jsName:String, adjustFunction:Dynamic->Dynamic = null) {
				if (adjustFunction == null) adjustFunction = function(v) {
					if (v.startsWith("url")) console.warn("SVGLoader: url access in attributes is not implemented.");
					return v;
				};
				if (node.hasAttribute(svgName)) style.set(jsName, adjustFunction(node.getAttribute(svgName)));
				if (stylesheetStyles.get(svgName) != null) style.set(jsName, adjustFunction(stylesheetStyles.get(svgName)));
				if (node.style != null && node.style[svgName] != "") style.set(jsName, adjustFunction(node.style[svgName]));
			}

			function clamp(v:String):Float {
				return Math.max(0, Math.min(1, parseFloatWithUnits(v)));
			}

			function positive(v:String):Float {
				return Math.max(0, parseFloatWithUnits(v));
			}

			addStyle("fill", "fill");
			addStyle("fill-opacity", "fillOpacity", clamp);
			addStyle("fill-rule", "fillRule");
			addStyle("opacity", "opacity", clamp);
			addStyle("stroke", "stroke");
			addStyle("stroke-opacity", "strokeOpacity", clamp);
			addStyle("stroke-width", "strokeWidth", positive);
			addStyle("stroke-linejoin", "strokeLineJoin");
			addStyle("stroke-linecap", "strokeLineCap");
			addStyle("stroke-miterlimit", "strokeMiterLimit", positive);
			addStyle("visibility", "visibility");

			return style;
		}

		// http://www.w3.org/TR/SVG11/implnote.html#PathElementImplementationNotes

		function getReflection(a:Float, b:Float):Float {
			return a - (b - a);
		}

		// from https://github.com/ppvg/svg-numbers (MIT License)

		function parseFloats(input:String, flags:Array<Int> = [], stride:Int = 1):Array<Float> {
			if (typeof input != "string") {
				throw new TypeError("Invalid input: " + typeof input);
			}

			// Character groups

import three.core.Box2;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Matrix3;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.core.ShapePath;
import three.extras.ShapeUtils;
import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;

class SVGLoader extends Loader {
	public var defaultDPI:Float = 90;
	public var defaultUnit:String = "px";

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String):Dynamic {
		var scope = this;

		var paths:Array<ShapePath> = [];
		var stylesheets:Map<String, Map<String, String>> = new Map();

		var transformStack:Array<Matrix3> = [];
		var tempTransform0 = new Matrix3();
		var tempTransform1 = new Matrix3();
		var tempTransform2 = new Matrix3();
		var tempTransform3 = new Matrix3();
		var tempV2 = new Vector2();
		var tempV3 = new Vector3();

		var currentTransform = new Matrix3();

		var xml = new DOMParser().parseFromString(text, "image/svg+xml");

		function parseNode(node:Dynamic, style:Map<String, String>) {
			if (node.nodeType != 1) return;

			var transform = getNodeTransform(node);
			var isDefsNode = false;

			var path:ShapePath = null;

			switch (node.nodeName) {
				case "svg":
					style = parseStyle(node, style);
					break;
				case "style":
					parseCSSStylesheet(node);
					break;
				case "g":
					style = parseStyle(node, style);
					break;
				case "path":
					style = parseStyle(node, style);
					if (node.hasAttribute("d")) path = parsePathNode(node);
					break;
				case "rect":
					style = parseStyle(node, style);
					path = parseRectNode(node);
					break;
				case "polygon":
					style = parseStyle(node, style);
					path = parsePolygonNode(node);
					break;
				case "polyline":
					style = parseStyle(node, style);
					path = parsePolylineNode(node);
					break;
				case "circle":
					style = parseStyle(node, style);
					path = parseCircleNode(node);
					break;
				case "ellipse":
					style = parseStyle(node, style);
					path = parseEllipseNode(node);
					break;
				case "line":
					style = parseStyle(node, style);
					path = parseLineNode(node);
					break;
				case "defs":
					isDefsNode = true;
					break;
				case "use":
					style = parseStyle(node, style);
					var href = node.getAttributeNS("http://www.w3.org/1999/xlink", "href") || "";
					var usedNodeId = href.substring(1);
					var usedNode = node.viewportElement.getElementById(usedNodeId);
					if (usedNode != null) {
						parseNode(usedNode, style);
					} else {
						console.warn("SVGLoader: 'use node' references non-existent node id: " + usedNodeId);
					}
					break;
				default:
					// console.log(node);
			}

			if (path != null) {
				if (style.get("fill") != null && style.get("fill") != "none") {
					path.color.setStyle(style.get("fill"), Color.SRGB);
				}
				transformPath(path, currentTransform);
				paths.push(path);
				path.userData = {node: node, style: style};
			}

			var childNodes = node.childNodes;
			for (i in 0...childNodes.length) {
				var node = childNodes[i];
				if (isDefsNode && node.nodeName != "style" && node.nodeName != "defs") {
					// Ignore everything in defs except CSS style definitions
					// and nested defs, because it is OK by the standard to have
					// <style/> there.
					continue;
				}
				parseNode(node, style);
			}

			if (transform != null) {
				transformStack.pop();
				if (transformStack.length > 0) {
					currentTransform.copy(transformStack[transformStack.length - 1]);
				} else {
					currentTransform.identity();
				}
			}
		}

		function parsePathNode(node:Dynamic):ShapePath {
			var path = new ShapePath();

			var point = new Vector2();
			var control = new Vector2();

			var firstPoint = new Vector2();
			var isFirstPoint = true;
			var doSetFirstPoint = false;

			var d = node.getAttribute("d");
			if (d == "" || d == "none") return null;

			// console.log(d);

			var commands = d.match(/[a-df-z][^a-df-z]*/ig);
			for (i in 0...commands.length) {
				var command = commands[i];

				var type = command.charAt(0);
				var data = command.slice(1).trim();

				if (isFirstPoint) {
					doSetFirstPoint = true;
					isFirstPoint = false;
				}

				var numbers:Array<Float>;

				switch (type) {
					case "M":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "H":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "V":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "L":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "C":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3],
									numbers[j + 4],
									numbers[j + 5]
								);
								control.x = numbers[j + 2];
								control.y = numbers[j + 3];
								point.x = numbers[j + 4];
								point.y = numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "S":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "Q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "T":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									numbers[j],
									numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = numbers[j];
								point.y = numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "A":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if start point == end point
								if (numbers[j + 5] == point.x && numbers[j + 6] == point.y) continue;
								var start = point.clone();
								point.x = numbers[j + 5];
								point.y = numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "m":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "h":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "v":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "l":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "c":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3],
									point.x + numbers[j + 4],
									point.y + numbers[j + 5]
								);
								control.x = point.x + numbers[j + 2];
								control.y = point.y + numbers[j + 3];
								point.x += numbers[j + 4];
								point.y += numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "s":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "t":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									point.x + numbers[j],
									point.y + numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = point.x + numbers[j];
								point.y = point.y + numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "a":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if no displacement
								if (numbers[j + 5] == 0 && numbers[j + 6] == 0) continue;
								var start = point.clone();
								point.x += numbers[j + 5];
								point.y += numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "Z":
					case "z":
						path.currentPath.autoClose = true;
						if (path.currentPath.curves.length > 0) {
							// Reset point to beginning of Path
							point.copy(firstPoint);
							path.currentPath.currentPoint.copy(point);
							isFirstPoint = true;
						}
						break;
					default:
						console.warn(command);
				}

				// console.log(type, parseFloats(data), parseFloats(data).length  )

				doSetFirstPoint = false;
			}

			return path;
		}

		function parseCSSStylesheet(node:Dynamic) {
			if (node.sheet == null || node.sheet.cssRules == null || node.sheet.cssRules.length == 0) return;
			for (i in 0...node.sheet.cssRules.length) {
				var stylesheet = node.sheet.cssRules[i];
				if (stylesheet.type != 1) continue;
				var selectorList = stylesheet.selectorText
					.split(/,/gm)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (j in 0...selectorList.length) {
					// Remove empty rules
					var definitions = new Map(Object.entries(stylesheet.style).filter(v -> v[1] != ""));
					stylesheets.set(selectorList[j], stylesheets.get(selectorList[j]) != null ? stylesheets.get(selectorList[j]).merge(definitions) : definitions);
				}
			}
		}

		/**
		 * https://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes
		 * https://mortoray.com/2017/02/16/rendering-an-svg-elliptical-arc-as-bezier-curves/ Appendix: Endpoint to center arc conversion
		 * From
		 * rx ry x-axis-rotation large-arc-flag sweep-flag x y
		 * To
		 * aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation
		 */

		function parseArcCommand(path:ShapePath, rx:Float, ry:Float, x_axis_rotation:Float, large_arc_flag:Float, sweep_flag:Float, start:Vector2, end:Vector2) {
			if (rx == 0 || ry == 0) {
				// draw a line if either of the radii == 0
				path.lineTo(end.x, end.y);
				return;
			}

			x_axis_rotation = x_axis_rotation * Math.PI / 180;

			// Ensure radii are positive
			rx = Math.abs(rx);
			ry = Math.abs(ry);

			// Compute (x1', y1')
			var dx2 = (start.x - end.x) / 2.0;
			var dy2 = (start.y - end.y) / 2.0;
			var x1p = Math.cos(x_axis_rotation) * dx2 + Math.sin(x_axis_rotation) * dy2;
			var y1p = - Math.sin(x_axis_rotation) * dx2 + Math.cos(x_axis_rotation) * dy2;

			// Compute (cx', cy')
			var rxs = rx * rx;
			var rys = ry * ry;
			var x1ps = x1p * x1p;
			var y1ps = y1p * y1p;

			// Ensure radii are large enough
			var cr = x1ps / rxs + y1ps / rys;

			if (cr > 1) {
				// scale up rx,ry equally so cr == 1
				var s = Math.sqrt(cr);
				rx = s * rx;
				ry = s * ry;
				rxs = rx * rx;
				rys = ry * ry;
			}

			var dq = (rxs * y1ps + rys * x1ps);
			var pq = (rxs * rys - dq) / dq;
			var q = Math.sqrt(Math.max(0, pq));
			if (large_arc_flag == sweep_flag) q = - q;
			var cxp = q * rx * y1p / ry;
			var cyp = - q * ry * x1p / rx;

			// Step 3: Compute (cx, cy) from (cx', cy')
			var cx = Math.cos(x_axis_rotation) * cxp - Math.sin(x_axis_rotation) * cyp + (start.x + end.x) / 2;
			var cy = Math.sin(x_axis_rotation) * cxp + Math.cos(x_axis_rotation) * cyp + (start.y + end.y) / 2;

			// Step 4: Compute θ1 and Δθ
			var theta = svgAngle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
			var delta = svgAngle((x1p - cxp) / rx, (y1p - cyp) / ry, (- x1p - cxp) / rx, (- y1p - cyp) / ry) % (Math.PI * 2);

			path.currentPath.absellipse(cx, cy, rx, ry, theta, theta + delta, sweep_flag == 0, x_axis_rotation);
		}

		function svgAngle(ux:Float, uy:Float, vx:Float, vy:Float):Float {
			var dot = ux * vx + uy * vy;
			var len = Math.sqrt(ux * ux + uy * uy) * Math.sqrt(vx * vx + vy * vy);
			var ang = Math.acos(Math.max(- 1, Math.min(1, dot / len))); // floating point precision, slightly over values appear
			if ((ux * vy - uy * vx) < 0) ang = - ang;
			return ang;
		}

		/*
		* According to https://www.w3.org/TR/SVG/shapes.html#RectElementRXAttribute
		* rounded corner should be rendered to elliptical arc, but bezier curve does the job well enough
		*/
		function parseRectNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("x") || "0");
			var y = parseFloatWithUnits(node.getAttribute("y") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || node.getAttribute("ry") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || node.getAttribute("rx") || "0");
			var w = parseFloatWithUnits(node.getAttribute("width"));
			var h = parseFloatWithUnits(node.getAttribute("height"));

			// Ellipse arc to Bezier approximation Coefficient (Inversed). See:
			// https://spencermortensen.com/articles/bezier-circle/
			var bci = 1 - 0.551915024494;

			var path = new ShapePath();

			// top left
			path.moveTo(x + rx, y);

			// top right
			path.lineTo(x + w - rx, y);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w - rx * bci,
					y,
					x + w,
					y + ry * bci,
					x + w,
					y + ry
				);
			}

			// bottom right
			path.lineTo(x + w, y + h - ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w,
					y + h - ry * bci,
					x + w - rx * bci,
					y + h,
					x + w - rx,
					y + h
				);
			}

			// bottom left
			path.lineTo(x + rx, y + h);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + rx * bci,
					y + h,
					x,
					y + h - ry * bci,
					x,
					y + h - ry
				);
			}

			// back to top left
			path.lineTo(x, y + ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(x, y + ry * bci, x + rx * bci, y, x + rx, y);
			}

			return path;
		}

		function parsePolygonNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = true;

			return path;
		}

		function parsePolylineNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = false;

			return path;
		}

		function parseCircleNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var r = parseFloatWithUnits(node.getAttribute("r") || "0");

			var subpath = new Path();
			subpath.absarc(x, y, r, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseEllipseNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || "0");

			var subpath = new Path();
			subpath.absellipse(x, y, rx, ry, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseLineNode(node:Dynamic):ShapePath {
			var x1 = parseFloatWithUnits(node.getAttribute("x1") || "0");
			var y1 = parseFloatWithUnits(node.getAttribute("y1") || "0");
			var x2 = parseFloatWithUnits(node.getAttribute("x2") || "0");
			var y2 = parseFloatWithUnits(node.getAttribute("y2") || "0");

			var path = new ShapePath();
			path.moveTo(x1, y1);
			path.lineTo(x2, y2);
			path.currentPath.autoClose = false;

			return path;
		}

		//

		function parseStyle(node:Dynamic, style:Map<String, String>):Map<String, String> {
			style = style.copy(); // clone style

			var stylesheetStyles:Map<String, String> = new Map();

			if (node.hasAttribute("class")) {
				var classSelectors = node.getAttribute("class")
					.split(/\s/)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (i in 0...classSelectors.length) {
					stylesheetStyles = stylesheets.get("." + classSelectors[i]) != null ? stylesheetStyles.merge(stylesheets.get("." + classSelectors[i])) : stylesheetStyles;
				}
			}

			if (node.hasAttribute("id")) {
				stylesheetStyles = stylesheets.get("#" + node.getAttribute("id")) != null ? stylesheetStyles.merge(stylesheets.get("#" + node.getAttribute("id"))) : stylesheetStyles;
			}

			function addStyle(svgName:String, jsName:String, adjustFunction:Dynamic->Dynamic = null) {
				if (adjustFunction == null) adjustFunction = function(v) {
					if (v.startsWith("url")) console.warn("SVGLoader: url access in attributes is not implemented.");
					return v;
				};
				if (node.hasAttribute(svgName)) style.set(jsName, adjustFunction(node.getAttribute(svgName)));
				if (stylesheetStyles.get(svgName) != null) style.set(jsName, adjustFunction(stylesheetStyles.get(svgName)));
				if (node.style != null && node.style[svgName] != "") style.set(jsName, adjustFunction(node.style[svgName]));
			}

			function clamp(v:String):Float {
				return Math.max(0, Math.min(1, parseFloatWithUnits(v)));
			}

			function positive(v:String):Float {
				return Math.max(0, parseFloatWithUnits(v));
			}

			addStyle("fill", "fill");
			addStyle("fill-opacity", "fillOpacity", clamp);
			addStyle("fill-rule", "fillRule");
			addStyle("opacity", "opacity", clamp);
			addStyle("stroke", "stroke");
			addStyle("stroke-opacity", "strokeOpacity", clamp);
			addStyle("stroke-width", "strokeWidth", positive);
			addStyle("stroke-linejoin", "strokeLineJoin");
			addStyle("stroke-linecap", "strokeLineCap");
			addStyle("stroke-miterlimit", "strokeMiterLimit", positive);
			addStyle("visibility", "visibility");

			return style;
		}

		// http://www.w3.org/TR/SVG11/implnote.html#PathElementImplementationNotes

		function getReflection(a:Float, b:Float):Float {
			return a - (b - a);
		}

		// from https://github.com/ppvg/svg-numbers (MIT License)

		function parseFloats(input:String, flags:Array<Int> = [], stride:Int = 1):Array<Float> {
			if (typeof input != "string") {
				throw new TypeError("Invalid input: " + typeof input);
			}

			// Character groups

import three.core.Box2;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.loaders.Loader;
import three.math.Matrix3;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.core.ShapePath;
import three.extras.ShapeUtils;
import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;

class SVGLoader extends Loader {
	public var defaultDPI:Float = 90;
	public var defaultUnit:String = "px";

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String):Dynamic {
		var scope = this;

		var paths:Array<ShapePath> = [];
		var stylesheets:Map<String, Map<String, String>> = new Map();

		var transformStack:Array<Matrix3> = [];
		var tempTransform0 = new Matrix3();
		var tempTransform1 = new Matrix3();
		var tempTransform2 = new Matrix3();
		var tempTransform3 = new Matrix3();
		var tempV2 = new Vector2();
		var tempV3 = new Vector3();

		var currentTransform = new Matrix3();

		var xml = new DOMParser().parseFromString(text, "image/svg+xml");

		function parseNode(node:Dynamic, style:Map<String, String>) {
			if (node.nodeType != 1) return;

			var transform = getNodeTransform(node);
			var isDefsNode = false;

			var path:ShapePath = null;

			switch (node.nodeName) {
				case "svg":
					style = parseStyle(node, style);
					break;
				case "style":
					parseCSSStylesheet(node);
					break;
				case "g":
					style = parseStyle(node, style);
					break;
				case "path":
					style = parseStyle(node, style);
					if (node.hasAttribute("d")) path = parsePathNode(node);
					break;
				case "rect":
					style = parseStyle(node, style);
					path = parseRectNode(node);
					break;
				case "polygon":
					style = parseStyle(node, style);
					path = parsePolygonNode(node);
					break;
				case "polyline":
					style = parseStyle(node, style);
					path = parsePolylineNode(node);
					break;
				case "circle":
					style = parseStyle(node, style);
					path = parseCircleNode(node);
					break;
				case "ellipse":
					style = parseStyle(node, style);
					path = parseEllipseNode(node);
					break;
				case "line":
					style = parseStyle(node, style);
					path = parseLineNode(node);
					break;
				case "defs":
					isDefsNode = true;
					break;
				case "use":
					style = parseStyle(node, style);
					var href = node.getAttributeNS("http://www.w3.org/1999/xlink", "href") || "";
					var usedNodeId = href.substring(1);
					var usedNode = node.viewportElement.getElementById(usedNodeId);
					if (usedNode != null) {
						parseNode(usedNode, style);
					} else {
						console.warn("SVGLoader: 'use node' references non-existent node id: " + usedNodeId);
					}
					break;
				default:
					// console.log(node);
			}

			if (path != null) {
				if (style.get("fill") != null && style.get("fill") != "none") {
					path.color.setStyle(style.get("fill"), Color.SRGB);
				}
				transformPath(path, currentTransform);
				paths.push(path);
				path.userData = {node: node, style: style};
			}

			var childNodes = node.childNodes;
			for (i in 0...childNodes.length) {
				var node = childNodes[i];
				if (isDefsNode && node.nodeName != "style" && node.nodeName != "defs") {
					// Ignore everything in defs except CSS style definitions
					// and nested defs, because it is OK by the standard to have
					// <style/> there.
					continue;
				}
				parseNode(node, style);
			}

			if (transform != null) {
				transformStack.pop();
				if (transformStack.length > 0) {
					currentTransform.copy(transformStack[transformStack.length - 1]);
				} else {
					currentTransform.identity();
				}
			}
		}

		function parsePathNode(node:Dynamic):ShapePath {
			var path = new ShapePath();

			var point = new Vector2();
			var control = new Vector2();

			var firstPoint = new Vector2();
			var isFirstPoint = true;
			var doSetFirstPoint = false;

			var d = node.getAttribute("d");
			if (d == "" || d == "none") return null;

			// console.log(d);

			var commands = d.match(/[a-df-z][^a-df-z]*/ig);
			for (i in 0...commands.length) {
				var command = commands[i];

				var type = command.charAt(0);
				var data = command.slice(1).trim();

				if (isFirstPoint) {
					doSetFirstPoint = true;
					isFirstPoint = false;
				}

				var numbers:Array<Float>;

				switch (type) {
					case "M":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "H":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "V":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y = numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "L":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x = numbers[j];
								control.x = point.x;
							} else {
								point.y = numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "C":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3],
									numbers[j + 4],
									numbers[j + 5]
								);
								control.x = numbers[j + 2];
								control.y = numbers[j + 3];
								point.x = numbers[j + 4];
								point.y = numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "S":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "Q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									numbers[j],
									numbers[j + 1],
									numbers[j + 2],
									numbers[j + 3]
								);
								control.x = numbers[j];
								control.y = numbers[j + 1];
								point.x = numbers[j + 2];
								point.y = numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "T":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									numbers[j],
									numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = numbers[j];
								point.y = numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "A":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if start point == end point
								if (numbers[j + 5] == point.x && numbers[j + 6] == point.y) continue;
								var start = point.clone();
								point.x = numbers[j + 5];
								point.y = numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "m":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							if (j == 0) {
								path.moveTo(point.x, point.y);
							} else {
								path.lineTo(point.x, point.y);
							}
							if (j == 0) firstPoint.copy(point);
						}
						break;
					case "h":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.x += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "v":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							point.y += numbers[j];
							control.x = point.x;
							control.y = point.y;
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "l":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								point.x += numbers[j];
								control.x = point.x;
							} else {
								point.y += numbers[j];
								control.y = point.y;
							}
							path.lineTo(point.x, point.y);
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "c":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 6 == 0) {
								path.bezierCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3],
									point.x + numbers[j + 4],
									point.y + numbers[j + 5]
								);
								control.x = point.x + numbers[j + 2];
								control.y = point.y + numbers[j + 3];
								point.x += numbers[j + 4];
								point.y += numbers[j + 5];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "s":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.bezierCurveTo(
									getReflection(point.x, control.x),
									getReflection(point.y, control.y),
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "q":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 4 == 0) {
								path.quadraticCurveTo(
									point.x + numbers[j],
									point.y + numbers[j + 1],
									point.x + numbers[j + 2],
									point.y + numbers[j + 3]
								);
								control.x = point.x + numbers[j];
								control.y = point.y + numbers[j + 1];
								point.x += numbers[j + 2];
								point.y += numbers[j + 3];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "t":
						numbers = parseFloats(data);
						for (j in 0...numbers.length) {
							if (j % 2 == 0) {
								var rx = getReflection(point.x, control.x);
								var ry = getReflection(point.y, control.y);
								path.quadraticCurveTo(
									rx,
									ry,
									point.x + numbers[j],
									point.y + numbers[j + 1]
								);
								control.x = rx;
								control.y = ry;
								point.x = point.x + numbers[j];
								point.y = point.y + numbers[j + 1];
							}
							if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
						}
						break;
					case "a":
						numbers = parseFloats(data, [3, 4], 7);
						for (j in 0...numbers.length) {
							if (j % 7 == 0) {
								// skip command if no displacement
								if (numbers[j + 5] == 0 && numbers[j + 6] == 0) continue;
								var start = point.clone();
								point.x += numbers[j + 5];
								point.y += numbers[j + 6];
								control.x = point.x;
								control.y = point.y;
								parseArcCommand(
									path, numbers[j], numbers[j + 1], numbers[j + 2], numbers[j + 3], numbers[j + 4], start, point
								);
								if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
							}
						}
						break;
					case "Z":
					case "z":
						path.currentPath.autoClose = true;
						if (path.currentPath.curves.length > 0) {
							// Reset point to beginning of Path
							point.copy(firstPoint);
							path.currentPath.currentPoint.copy(point);
							isFirstPoint = true;
						}
						break;
					default:
						console.warn(command);
				}

				// console.log(type, parseFloats(data), parseFloats(data).length  )

				doSetFirstPoint = false;
			}

			return path;
		}

		function parseCSSStylesheet(node:Dynamic) {
			if (node.sheet == null || node.sheet.cssRules == null || node.sheet.cssRules.length == 0) return;
			for (i in 0...node.sheet.cssRules.length) {
				var stylesheet = node.sheet.cssRules[i];
				if (stylesheet.type != 1) continue;
				var selectorList = stylesheet.selectorText
					.split(/,/gm)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (j in 0...selectorList.length) {
					// Remove empty rules
					var definitions = new Map(Object.entries(stylesheet.style).filter(v -> v[1] != ""));
					stylesheets.set(selectorList[j], stylesheets.get(selectorList[j]) != null ? stylesheets.get(selectorList[j]).merge(definitions) : definitions);
				}
			}
		}

		/**
		 * https://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes
		 * https://mortoray.com/2017/02/16/rendering-an-svg-elliptical-arc-as-bezier-curves/ Appendix: Endpoint to center arc conversion
		 * From
		 * rx ry x-axis-rotation large-arc-flag sweep-flag x y
		 * To
		 * aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation
		 */

		function parseArcCommand(path:ShapePath, rx:Float, ry:Float, x_axis_rotation:Float, large_arc_flag:Float, sweep_flag:Float, start:Vector2, end:Vector2) {
			if (rx == 0 || ry == 0) {
				// draw a line if either of the radii == 0
				path.lineTo(end.x, end.y);
				return;
			}

			x_axis_rotation = x_axis_rotation * Math.PI / 180;

			// Ensure radii are positive
			rx = Math.abs(rx);
			ry = Math.abs(ry);

			// Compute (x1', y1')
			var dx2 = (start.x - end.x) / 2.0;
			var dy2 = (start.y - end.y) / 2.0;
			var x1p = Math.cos(x_axis_rotation) * dx2 + Math.sin(x_axis_rotation) * dy2;
			var y1p = - Math.sin(x_axis_rotation) * dx2 + Math.cos(x_axis_rotation) * dy2;

			// Compute (cx', cy')
			var rxs = rx * rx;
			var rys = ry * ry;
			var x1ps = x1p * x1p;
			var y1ps = y1p * y1p;

			// Ensure radii are large enough
			var cr = x1ps / rxs + y1ps / rys;

			if (cr > 1) {
				// scale up rx,ry equally so cr == 1
				var s = Math.sqrt(cr);
				rx = s * rx;
				ry = s * ry;
				rxs = rx * rx;
				rys = ry * ry;
			}

			var dq = (rxs * y1ps + rys * x1ps);
			var pq = (rxs * rys - dq) / dq;
			var q = Math.sqrt(Math.max(0, pq));
			if (large_arc_flag == sweep_flag) q = - q;
			var cxp = q * rx * y1p / ry;
			var cyp = - q * ry * x1p / rx;

			// Step 3: Compute (cx, cy) from (cx', cy')
			var cx = Math.cos(x_axis_rotation) * cxp - Math.sin(x_axis_rotation) * cyp + (start.x + end.x) / 2;
			var cy = Math.sin(x_axis_rotation) * cxp + Math.cos(x_axis_rotation) * cyp + (start.y + end.y) / 2;

			// Step 4: Compute θ1 and Δθ
			var theta = svgAngle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
			var delta = svgAngle((x1p - cxp) / rx, (y1p - cyp) / ry, (- x1p - cxp) / rx, (- y1p - cyp) / ry) % (Math.PI * 2);

			path.currentPath.absellipse(cx, cy, rx, ry, theta, theta + delta, sweep_flag == 0, x_axis_rotation);
		}

		function svgAngle(ux:Float, uy:Float, vx:Float, vy:Float):Float {
			var dot = ux * vx + uy * vy;
			var len = Math.sqrt(ux * ux + uy * uy) * Math.sqrt(vx * vx + vy * vy);
			var ang = Math.acos(Math.max(- 1, Math.min(1, dot / len))); // floating point precision, slightly over values appear
			if ((ux * vy - uy * vx) < 0) ang = - ang;
			return ang;
		}

		/*
		* According to https://www.w3.org/TR/SVG/shapes.html#RectElementRXAttribute
		* rounded corner should be rendered to elliptical arc, but bezier curve does the job well enough
		*/
		function parseRectNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("x") || "0");
			var y = parseFloatWithUnits(node.getAttribute("y") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || node.getAttribute("ry") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || node.getAttribute("rx") || "0");
			var w = parseFloatWithUnits(node.getAttribute("width"));
			var h = parseFloatWithUnits(node.getAttribute("height"));

			// Ellipse arc to Bezier approximation Coefficient (Inversed). See:
			// https://spencermortensen.com/articles/bezier-circle/
			var bci = 1 - 0.551915024494;

			var path = new ShapePath();

			// top left
			path.moveTo(x + rx, y);

			// top right
			path.lineTo(x + w - rx, y);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w - rx * bci,
					y,
					x + w,
					y + ry * bci,
					x + w,
					y + ry
				);
			}

			// bottom right
			path.lineTo(x + w, y + h - ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + w,
					y + h - ry * bci,
					x + w - rx * bci,
					y + h,
					x + w - rx,
					y + h
				);
			}

			// bottom left
			path.lineTo(x + rx, y + h);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(
					x + rx * bci,
					y + h,
					x,
					y + h - ry * bci,
					x,
					y + h - ry
				);
			}

			// back to top left
			path.lineTo(x, y + ry);
			if (rx != 0 || ry != 0) {
				path.bezierCurveTo(x, y + ry * bci, x + rx * bci, y, x + rx, y);
			}

			return path;
		}

		function parsePolygonNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = true;

			return path;
		}

		function parsePolylineNode(node:Dynamic):ShapePath {
			function iterator(match:String, a:String, b:String) {
				var x = parseFloatWithUnits(a);
				var y = parseFloatWithUnits(b);
				if (index == 0) {
					path.moveTo(x, y);
				} else {
					path.lineTo(x, y);
				}
				index++;
			}

			var regex = /([+-]?\d*\.?\d+(?:e[+-]?\d+)?)(?:,|\s)([+-]?\d*\.?\d+(?:e[+-]?\d+)?)/g;

			var path = new ShapePath();
			var index = 0;
			node.getAttribute("points").replace(regex, iterator);
			path.currentPath.autoClose = false;

			return path;
		}

		function parseCircleNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var r = parseFloatWithUnits(node.getAttribute("r") || "0");

			var subpath = new Path();
			subpath.absarc(x, y, r, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseEllipseNode(node:Dynamic):ShapePath {
			var x = parseFloatWithUnits(node.getAttribute("cx") || "0");
			var y = parseFloatWithUnits(node.getAttribute("cy") || "0");
			var rx = parseFloatWithUnits(node.getAttribute("rx") || "0");
			var ry = parseFloatWithUnits(node.getAttribute("ry") || "0");

			var subpath = new Path();
			subpath.absellipse(x, y, rx, ry, 0, Math.PI * 2);

			var path = new ShapePath();
			path.subPaths.push(subpath);

			return path;
		}

		function parseLineNode(node:Dynamic):ShapePath {
			var x1 = parseFloatWithUnits(node.getAttribute("x1") || "0");
			var y1 = parseFloatWithUnits(node.getAttribute("y1") || "0");
			var x2 = parseFloatWithUnits(node.getAttribute("x2") || "0");
			var y2 = parseFloatWithUnits(node.getAttribute("y2") || "0");

			var path = new ShapePath();
			path.moveTo(x1, y1);
			path.lineTo(x2, y2);
			path.currentPath.autoClose = false;

			return path;
		}

		//

		function parseStyle(node:Dynamic, style:Map<String, String>):Map<String, String> {
			style = style.copy(); // clone style

			var stylesheetStyles:Map<String, String> = new Map();

			if (node.hasAttribute("class")) {
				var classSelectors = node.getAttribute("class")
					.split(/\s/)
					.filter(v -> v != "")
					.map(v -> v.trim());
				for (i in 0...classSelectors.length) {
					stylesheetStyles = stylesheets.get("." + classSelectors[i]) != null ? stylesheetStyles.merge(stylesheets.get("." + classSelectors[i])) : stylesheetStyles;
				}
			}

			if (node.hasAttribute("id")) {
				stylesheetStyles = stylesheets.get("#" + node.getAttribute("id")) != null ? stylesheetStyles.merge(stylesheets.get("#" + node.getAttribute("id"))) : stylesheetStyles;
			}

			function addStyle(svgName:String, jsName:String, adjustFunction:Dynamic->Dynamic = null) {
				if (adjustFunction == null) adjustFunction = function(v) {
					if (v.startsWith("url")) console.warn("SVGLoader: url access in attributes is not implemented.");
					return v;
				};
				if (node.hasAttribute(svgName)) style.set(jsName, adjustFunction(node.getAttribute(svgName)));
				if (stylesheetStyles.get(svgName) != null) style.set(jsName, adjustFunction(stylesheetStyles.get(svgName)));
				if (node.style != null && node.style[svgName] != "") style.set(jsName, adjustFunction(node.style[svgName]));
			}

			function clamp(v:String):Float {
				return Math.max(0, Math.min(1, parseFloatWithUnits(v)));
			}

			function positive(v:String):Float {
				return Math.max(0, parseFloatWithUnits(v));
			}

			addStyle("fill", "fill");
			addStyle("fill-opacity", "fillOpacity", clamp);
			addStyle("fill-rule", "fillRule");
			addStyle("opacity", "opacity", clamp);
			addStyle("stroke", "stroke");
			addStyle("stroke-opacity", "strokeOpacity", clamp);
			addStyle("stroke-width", "strokeWidth", positive);
			addStyle("stroke-linejoin", "strokeLineJoin");
			addStyle("stroke-linecap", "strokeLineCap");
			addStyle("stroke-miterlimit", "strokeMiterLimit", positive);
			addStyle("visibility", "visibility");

			return style;
		}

		// http://www.w3.org/TR/SVG11/implnote.html#PathElementImplementationNotes

		function getReflection(a:Float, b:Float):Float {
			return a - (b - a);
		}

		// from https://github.com/ppvg/svg-numbers (MIT License)

		function parseFloats(input:String, flags:Array<Int> = [], stride:Int = 1):Array<Float> {
			if (typeof input != "string") {
				throw new TypeError("Invalid input: " + typeof input);
			}

			// Character groups