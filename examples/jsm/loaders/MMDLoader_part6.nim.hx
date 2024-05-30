class CubicBezierInterpolation extends Interpolant {

	public var interpolationParams:Array<Float>;

	public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>, params:Array<Float>) {

		super(parameterPositions, sampleValues, sampleSize, resultBuffer);

		this.interpolationParams = params;

	}

	public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {

		var result = this.resultBuffer;
		var values = this.sampleValues;
		var stride = this.valueSize;
		var params = this.interpolationParams;

		var offset1 = i1 * stride;
		var offset0 = offset1 - stride;

		// No interpolation if next key frame is in one frame in 30fps.
		// This is from MMD animation spec.
		// '1.5' is for precision loss. times are Float32 in Three.js Animation system.
		var weight1 = ( ( t1 - t0 ) < 1 / 30 * 1.5 ) ? 0.0 : ( t - t0 ) / ( t1 - t0 );

		if ( stride == 4 ) { // Quaternion

			var x1 = params[ i1 * 4 + 0 ];
			var x2 = params[ i1 * 4 + 1 ];
			var y1 = params[ i1 * 4 + 2 ];
			var y2 = params[ i1 * 4 + 3 ];

			var ratio = this._calculate( x1, x2, y1, y2, weight1 );

			Quaternion.slerpFlat( result, 0, values, offset0, values, offset1, ratio );

		} else if ( stride == 3 ) { // Vector3

			for ( i in 0...stride ) {

				var x1 = params[ i1 * 12 + i * 4 + 0 ];
				var x2 = params[ i1 * 12 + i * 4 + 1 ];
				var y1 = params[ i1 * 12 + i * 4 + 2 ];
				var y2 = params[ i1 * 12 + i * 4 + 3 ];

				var ratio = this._calculate( x1, x2, y1, y2, weight1 );

				result[ i ] = values[ offset0 + i ] * ( 1 - ratio ) + values[ offset1 + i ] * ratio;

			}

		} else { // Number

			var x1 = params[ i1 * 4 + 0 ];
			var x2 = params[ i1 * 4 + 1 ];
			var y1 = params[ i1 * 4 + 2 ];
			var y2 = params[ i1 * 4 + 3 ];

			var ratio = this._calculate( x1, x2, y1, y2, weight1 );

			result[ 0 ] = values[ offset0 ] * ( 1 - ratio ) + values[ offset1 ] * ratio;

		}

		return result;

	}

	private function _calculate(x1:Float, x2:Float, y1:Float, y2:Float, x:Float):Float {

		/*
			 * Cubic Bezier curves
			 *   https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Cubic_B.C3.A9zier_curves
			 *
			 * B(t) = ( 1 - t ) ^ 3 * P0
			 *      + 3 * ( 1 - t ) ^ 2 * t * P1
			 *      + 3 * ( 1 - t ) * t^2 * P2
			 *      + t ^ 3 * P3
			 *      ( 0 <= t <= 1 )
			 *
			 * MMD uses Cubic Bezier curves for bone and camera animation interpolation.
			 *   http://d.hatena.ne.jp/edvakf/20111016/1318716097
			 *
			 *    x = ( 1 - t ) ^ 3 * x0
			 *      + 3 * ( 1 - t ) ^ 2 * t * x1
			 *      + 3 * ( 1 - t ) * t^2 * x2
			 *      + t ^ 3 * x3
			 *    y = ( 1 - t ) ^ 3 * y0
			 *      + 3 * ( 1 - t ) ^ 2 * t * y1
			 *      + 3 * ( 1 - t ) * t^2 * y2
			 *      + t ^ 3 * y3
			 *      ( x0 = 0, y0 = 0 )
			 *      ( x3 = 1, y3 = 1 )
			 *      ( 0 <= t, x1, x2, y1, y2 <= 1 )
			 *
			 * Here solves this equation with Bisection method,
			 *   https://en.wikipedia.org/wiki/Bisection_method
			 * gets t, and then calculate y.
			 *
			 * f(t) = 3 * ( 1 - t ) ^ 2 * t * x1
			 *      + 3 * ( 1 - t ) * t^2 * x2
			 *      + t ^ 3 - x = 0
			 *
			 * (Another option: Newton's method
			 *    https://en.wikipedia.org/wiki/Newton%27s_method)
			 */

		var c = 0.5;
		var t = c;
		var s = 1.0 - t;
		var loop = 15;
		var eps = 1e-5;
		var math = Math;

		var sst3, stt3, ttt;

		for ( i in 0...loop ) {

			sst3 = 3.0 * s * s * t;
			stt3 = 3.0 * s * t * t;
			ttt = t * t * t;

			var ft = ( sst3 * x1 ) + ( stt3 * x2 ) + ( ttt ) - x;

			if ( math.abs( ft ) < eps ) break;

			c /= 2.0;

			t += ( ft < 0 ) ? c : - c;
			s = 1.0 - t;

		}

		return ( sst3 * y1 ) + ( stt3 * y2 ) + ttt;

	}

}