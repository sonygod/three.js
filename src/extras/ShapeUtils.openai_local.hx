将以下 JavaScript 代码转换为 Haxe代码，主要包括导入 `Earcut` 类，定义 `ShapeUtils` 类，以及相关的静态方法和辅助函数。

JavaScript 代码:
```javascript
import { Earcut } from './Earcut.js';

class ShapeUtils {

	// calculate area of the contour polygon

	static area( contour ) {

		const n = contour.length;
		let a = 0.0;

		for ( let p = n - 1, q = 0; q < n; p = q ++ ) {

			a += contour[ p ].x * contour[ q ].y - contour[ q ].x * contour[ p ].y;

		}

		return a * 0.5;

	}

	static isClockWise( pts ) {

		return ShapeUtils.area( pts ) < 0;

	}

	static triangulateShape( contour, holes ) {

		const vertices = []; // flat array of vertices like [ x0,y0, x1,y1, x2,y2, ... ]
		const holeIndices = []; // array of hole indices
		const faces = []; // final array of vertex indices like [ [ a,b,d ], [ b,c,d ] ]

		removeDupEndPts( contour );
		addContour( vertices, contour );

		//

		let holeIndex = contour.length;

		holes.forEach( removeDupEndPts );

		for ( let i = 0; i < holes.length; i ++ ) {

			holeIndices.push( holeIndex );
			holeIndex += holes[ i ].length;
			addContour( vertices, holes[ i ] );

		}

		//

		const triangles = Earcut.triangulate( vertices, holeIndices );

		//

		for ( let i = 0; i < triangles.length; i += 3 ) {

			faces.push( triangles.slice( i, i + 3 ) );

		}

		return faces;

	}

}

function removeDupEndPts( points ) {

	const l = points.length;

	if ( l > 2 && points[ l - 1 ].equals( points[ 0 ] ) ) {

		points.pop();

	}

}

function addContour( vertices, contour ) {

	for ( let i = 0; i < contour.length; i ++ ) {

		vertices.push( contour[ i ].x );
		vertices.push( contour[ i ].y );

	}

}

export { ShapeUtils };

```

Haxe 代码:
```haxe
import Earcut;

class ShapeUtils {

    // calculate area of the contour polygon
    public static function area(contour:Array<{x:Float, y:Float}>):Float {
        var n = contour.length;
        var a = 0.0;

        for (p in n - 1...0) {
            var q = (p + 1) % n;
            a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
        }

        return a * 0.5;
    }

    public static function isClockWise(pts:Array<{x:Float, y:Float}>):Bool {
        return ShapeUtils.area(pts) < 0;
    }

    public static function triangulateShape(contour:Array<{x:Float, y:Float}>, holes:Array<Array<{x:Float, y:Float}>>):Array<Array<Int>> {
        var vertices = []; // flat array of vertices like [ x0,y0, x1,y1, x2,y2, ... ]
        var holeIndices = []; // array of hole indices
        var faces = []; // final array of vertex indices like [ [ a,b,d ], [ b,c,d ] ]

        removeDupEndPts(contour);
        addContour(vertices, contour);

        //

        var holeIndex = contour.length;

        for (hole in holes) {
            removeDupEndPts(hole);
            holeIndices.push(holeIndex);
            holeIndex += hole.length;
            addContour(vertices, hole);
        }

        //

        var triangles = Earcut.triangulate(vertices, holeIndices);

        //

        for (i in 0...triangles.length / 3) {
            faces.push(triangles.slice(i * 3, i * 3 + 3));
        }

        return faces;
    }

}

function removeDupEndPts(points:Array<{x:Float, y:Float}>):Void {
    var l = points.length;

    if (l > 2 && points[l - 1].equals(points[0])) {
        points.pop();
    }
}

function addContour(vertices:Array<Float>, contour:Array<{x:Float, y:Float}>):Void {
    for (pt in contour) {
        vertices.push(pt.x);
        vertices.push(pt.y);
    }
}
```

此转换包含：
- 将 JavaScript 数组替换为 Haxe 数组。
- 将 JavaScript 函数替换为 Haxe 静态方法。
- 将 JavaScript 箭头函数替换为 Haxe 循环结构。
- 将 JavaScript 方法 `Array.prototype.forEach` 替换为 Haxe 的 for 循环。

注意事项：
- 你可能需要根据具体使用场景调整导入的 `Earcut` 类。
- 你需要确保 `{x:Float, y:Float}` 类型与实际使用的点结构匹配。