import MathUtils from three.MathUtils;

class ColorConverter {

	static function setHSV( color : Color, h : Float, s : Float, v : Float ) : Void {

		h = MathUtils.euclideanModulo( h, 1.0 );
		s = MathUtils.clamp( s, 0.0, 1.0 );
		v = MathUtils.clamp( v, 0.0, 1.0 );

		return color.setHSL( h, ( s * v ) / ( ( h = ( 2.0 - s ) * v ) < 1.0 ? h : ( 2.0 - h ) ), h * 0.5 );

	}

	static function getHSV( color : Color, target : Color ) : Color {

		color.getHSL( _hsl );

		_hsl.s *= ( _hsl.l < 0.5 ) ? _hsl.l : ( 1.0 - _hsl.l );

		target.h = _hsl.h;
		target.s = 2.0 * _hsl.s / ( _hsl.l + _hsl.s );
		target.v = _hsl.l + _hsl.s;

		return target;

	}

}

var _hsl : HSL = { h: 0.0, s: 0.0, l: 0.0 };