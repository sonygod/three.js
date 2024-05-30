import js.three.*;

class SVGLoader extends Loader {
    public var defaultDPI:Float = 90;
    public var defaultUnit:String = 'px';

    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(text:String):Dynamic {
        var scope = this;
        function parseNode(node:Dynamic, style:Dynamic):Void {
            if (node.nodeType != 1) return;
            var transform = getNodeTransform(node);
            var isDefsNode = false;
            var path:Dynamic = null;
            switch (node.nodeName) {
                case 'svg':
                    style = parseStyle(node, style);
                    break;
                case 'style':
                    parseCSSStylesheet(node);
                    break;
                case 'g':
                    style = parseStyle(node, style);
                    break;
                case 'path':
                    style = parseStyle(node, style);
                    if (node.hasAttribute('d')) path = parsePathNode(node);
                    break;
                case 'rect':
                    style = parseStyle(node, style);
                    path = parseRectNode(node);
                    break;
                case 'polygon':
                    style = parseStyle(node, style);
                    path = parsePolygonNode(node);
                    break;
                case 'polyline':
                    style = parseStyle(node, style);
                    path = parsePolylineNode(node);
                    break;
                case 'circle':
                    style = parseStyle(node, style);
                    path = parseCircleNode(node);
                    break;
                case 'ellipse':
                    style = parseStyle(node, style);
                    path = parseEllipseNode(node);
                    break;
                case 'line':
                    style = parseStyle(node, style);
                    path = parseLineNode(node);
                    break;
                case 'defs':
                    isDefsNode = true;
                    break;
                case 'use':
                    style = parseStyle(node, style);
                    var href = node.getAttributeNS('http://www.w3.org/1999/xlink', 'href') || '';
                    var usedNodeId = href.substring(1);
                    var usedNode = node.viewportElement.getElementById(usedNodeId);
                    if (usedNode != null) {
                        parseNode(usedNode, style);
                    } else {
                        trace('SVGLoader: \'use node\' references non-existent node id: ' + usedNodeId);
                    }
                    break;
                default:
                    // trace(node);
            }
            if (path != null) {
                if (style.fill != null && style.fill != 'none') {
                    path.color.setStyle(style.fill, COLOR_SPACE_SVG);
                }
                transformPath(path, currentTransform);
                paths.push(path);
                path.userData = {node: node, style: style};
            }
            var childNodes = node.childNodes;
            for (i in 0...childNodes.length) {
                var node = childNodes[$i];
                if (isDefsNode && node.nodeName != 'style' && node.nodeName != 'defs') {
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
        function parsePathNode(node:Dynamic):Dynamic {
            var path = new ShapePath();
            var point = new Vector2();
            var control = new Vector2();
            var firstPoint = new Vector2();
            var isFirstPoint = true;
            var doSetFirstPoint = false;
            var d = node.getAttribute('d');
            if (d == '' || d == 'none') return null;
            // trace(d);
            var commands = d.match(/[a-df-z][^a-df-z]*/ig);
            for (i in 0...commands.length) {
                var command = commands[$i];
                var type = StringTools.charAt(command, 0);
                var data = StringTools.substr(command, 1, null).trim();
                if (isFirstPoint) {
                    doSetFirstPoint = true;
                    isFirstPoint = false;
                }
                var numbers:Array<Float> = parseFloats(data);
                for (j in 0...numbers.length) {
                    var j = $j;
                    switch (type) {
                        case 'M':
                            point.x = numbers[j + 0];
                            point.y = numbers[j + 1];
                            control.x = point.x;
                            control.y = point.y;
                            if (j == 0) {
                                path.moveTo(point.x, point.y);
                            } else {
                                path.lineTo(point.x, point.y);
                            }
                            if (j == 0) firstPoint.copy(point);
                            break;
                        case 'H':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                point.x = numbers[j];
                                control.x = point.x;
                                control.y = point.y;
                                path.lineTo(point.x, point.y);
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'V':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                point.y = numbers[j];
                                control.x = point.x;
                                control.y = point.y;
                                path.lineTo(point.x, point.y);
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'L':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                point.x = numbers[j + 0];
                                point.y = numbers[j + 1];
                                control.x = point.x;
                                control.y = point.y;
                                path.lineTo(point.x, point.y);
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'C':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                path.bezierCurveTo(
                                    numbers[j + 0],
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
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'S':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                path.bezierCurveTo(
                                    getReflection(point.x, control.x),
                                    getReflection(point.y, control.y),
                                    numbers[j + 0],
                                    numbers[j + 1],
                                    numbers[j + 2],
                                    numbers[j + 3]
                                );
                                control.x = numbers[j + 0];
                                control.y = numbers[j + 1];
                                point.x = numbers[j + 2];
                                point.y = numbers[j + 3];
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'Q':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                path.quadraticCurveTo(
                                    numbers[j + 0],
                                    numbers[j + 1],
                                    numbers[j + 2],
                                    numbers[j + 3]
                                );
                                control.x = numbers[j + 0];
                                control.y = numbers[j + 1];
                                point.x = numbers[j + 2];
                                point.y = numbers[j + 3];
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'T':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                var rx = getReflection(point.x, control.x);
                                var ry = getReflection(point.y, control.y);
                                path.quadraticCurveTo(
                                    rx,
                                    ry,
                                    numbers[j + 0],
                                    numbers[j + 1]
                                );
                                control.x = rx;
                                control.y = ry;
                                point.x = numbers[j + 0];
                                point.y = numbers[j + 1];
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'A':
                            var numbers = parseFloats(data, [3, 4], 7);
                            for (j in 0...numbers.length) {
                                var j = $j;
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
                            break;
                        case 'm':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                point.x += numbers[j + 0];
                                point.y += numbers[j + 1];
                                control.x = point.x;
                                control.y = point.y;
                                if (j == 0) {
                                    path.moveTo(point.x, point.y);
                                } else {
                                    path.lineTo(point.x, point.y);
                                }
                                if (j == 0) firstPoint.copy(point);
                            }
                            break;
                        case 'h':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                point.x += numbers[j];
                                control.x = point.x;
                                control.y = point.y;
                                path.lineTo(point.x, point.y);
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'v':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                point.y += numbers[j];
                                control.x = point.x;
                                control.y = point.y;
                                path.lineTo(point.x, point.y);
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'l':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                point.x += numbers[j + 0];
                                point.y += numbers[j + 1];
                                control.x = point.x;
                                control.y = point.y;
                                path.lineTo(point.x, point.y);
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'c':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                path.bezierCurveTo(
                                    point.x + numbers[j + 0],
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
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 's':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                path.bezierCurveTo(
                                    getReflection(point.x, control.x),
                                    getReflection(point.y, control.y),
                                    point.x + numbers[j + 0],
                                    point.y + numbers[j + 1],
                                    point.x + numbers[j + 2],
                                    point.y + numbers[j + 3]
                                );
                                control.x = point.x + numbers[j + 0];
                                control.y = point.y + numbers[j + 1];
                                point.x += numbers[j + 2];
                                point.y += numbers[j + 3];
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'q':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                path.quadraticCurveTo(
                                    point.x + numbers[j + 0],
                                    point.y + numbers[j + 1],
                                    point.x + numbers[j + 2],
                                    point.y + numbers[j + 3]
                                );
                                control.x = point.x + numbers[j + 0];
                                control.y = point.y + numbers[j + 1];
                                point.x += numbers[j + 2];
                                point.y += numbers[j + 3];
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 't':
                            for (j in 0...numbers.length) {
                                var j = $j;
                                var rx = getReflection(point.x, control.x);
                                var ry = getReflection(point.y, control.y);
                                path.quadraticCurveTo(
                                    rx,
                                    ry,
                                    point.x + numbers[j + 0],
                                    point.y + numbers[j + 1]
                                );
                                control.x = rx;
                                control.y = ry;
                                point.x = point.x + numbers[j + 0];
                                point.y = point.y + numbers[j + 1];
                                if (j == 0 && doSetFirstPoint) firstPoint.copy(point);
                            }
                            break;
                        case 'a':
                            var numbers = parseFloats(data, [3, 4], 7);
                            for (j in 0...numbers.length) {
                                var j = $j;
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
                            break;
                        case 'Z':
                        case 'z':
                            path.currentPath.autoClose = true;
                            if (path.currentPath.curves.length > 0) {
                                // Reset point to beginning of Path
                                point.copy(firstPoint);
                                path.currentPath.currentPoint.copy(point);
                                isFirstPoint = true;
                            }
                            break;
                        default:
                            trace(command);
                    }
                    // trace(type, parseFloats(data), parseFloats(data).length);
                    doSetFirstPoint = false;
                }
            }
            return path;
        }
        function parseCSSStylesheet(node:Dynamic):Void {
            if (!node.sheet || !node.sheet.cssRules || !node.sheet.cssRules.length) return;
            for (i in 0...node.sheet.cssRules.length) {
                var stylesheet = node.sheet.cssRules[$i];
                if (stylesheet.type != 1) continue;
                var selectorList = stylesheet.selectorText
                    .split(/,/)
                    .filter(function(i) {
                        return i.trim() != '';
                    })
                    .map(function(i) {
                        return i.trim();
                    });
                for (j in 0...selectorList.length) {
                    // Remove empty rules
                    var definitions = Object.fromMap(
                        stylesheet.style
                            .getFields()
                            .filter(function(i) {
                                return $i[1