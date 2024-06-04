import three.MathUtils;

class ColorConverter {

	static function setHSV(color:three.Color, h:Float, s:Float, v:Float):three.Color {

		// https://gist.github.com/xpansive/1337890#file-index-js

		h = MathUtils.euclideanModulo(h, 1);
		s = MathUtils.clamp(s, 0, 1);
		v = MathUtils.clamp(v, 0, 1);

		return color.setHSL(h, (s * v) / ((h = (2 - s) * v) < 1 ? h : (2 - h)), h * 0.5);

	}

	static function getHSV(color:three.Color, target:{h:Float, s:Float, v:Float}): {h:Float, s:Float, v:Float} {

		color.getHSL(target);

		// based on https://gist.github.com/xpansive/1337890#file-index-js
		target.s *= (target.l < 0.5) ? target.l : (1 - target.l);

		target.h = target.h;
		target.s = 2 * target.s / (target.l + target.s);
		target.v = target.l + target.s;

		return target;

	}

}