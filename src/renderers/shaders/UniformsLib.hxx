import three.math.Color;
import three.math.Vector2;
import three.math.Matrix3;

class UniformsLib {

	static var common(default, null):{
		diffuse:Color,
		opacity:Float,
		map:Dynamic,
		mapTransform:Matrix3,
		alphaMap:Dynamic,
		alphaMapTransform:Matrix3,
		alphaTest:Float
	} = {
		diffuse: new Color(0xffffff),
		opacity: 1.0,
		map: null,
		mapTransform: new Matrix3(),
		alphaMap: null,
		alphaMapTransform: new Matrix3(),
		alphaTest: 0
	};

	// ... 其他变量和类定义 ...

}