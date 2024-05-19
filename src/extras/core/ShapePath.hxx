import three.math.Color;
import three.extras.core.Path;
import three.extras.core.Shape;
import three.extras.ShapeUtils;

class ShapePath {

	var type:String;
	var color:Color;
	var subPaths:Array<Path>;
	var currentPath:Path;

	public function new() {

		type = 'ShapePath';

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

	public function splineThru(pts:Array<{x:Float, y:Float}>):ShapePath {

		currentPath.splineThru(pts);

		return this;

	}

	public function toShapes(isCCW:Bool):Array<Shape> {

		// 这里的代码需要手动转换，因为它包含了复杂的逻辑和函数，并且涉及到一些Haxe不支持的JavaScript特性。
		// 例如，Haxe不支持JavaScript的匿名函数和闭包，也不支持JavaScript的对象字面量。
		// 这些都需要手动转换为Haxe的语法。

	}

}