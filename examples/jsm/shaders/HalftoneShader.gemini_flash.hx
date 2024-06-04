import three.extras.ShaderMaterial;
import three.math.Vector2;
import three.math.Vector3;
import three.textures.Texture;

class HalftoneShader extends ShaderMaterial {

	public static get name():String {
		return "HalftoneShader";
	}

	public static get uniforms():Dynamic {
		return {
			"tDiffuse": { value: null },
			"shape": { value: 1 },
			"radius": { value: 4 },
			"rotateR": { value: Math.PI / 12 * 1 },
			"rotateG": { value: Math.PI / 12 * 2 },
			"rotateB": { value: Math.PI / 12 * 3 },
			"scatter": { value: 0 },
			"width": { value: 1 },
			"height": { value: 1 },
			"blending": { value: 1 },
			"blendingMode": { value: 1 },
			"greyscale": { value: false },
			"disable": { value: false }
		};
	}

	public static get vertexShader():String {
		return
			"varying vec2 vUV;\n" +
			"\n" +
			"void main() {\n" +
			"\n" +
			"	vUV = uv;\n" +
			"	gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);\n" +
			"\n" +
			"}";
	}

	public static get fragmentShader():String {
		return
			"#define SQRT2_MINUS_ONE 0.41421356\n" +
			"#define SQRT2_HALF_MINUS_ONE 0.20710678\n" +
			"#define PI2 6.28318531\n" +
			"#define SHAPE_DOT 1\n" +
			"#define SHAPE_ELLIPSE 2\n" +
			"#define SHAPE_LINE 3\n" +
			"#define SHAPE_SQUARE 4\n" +
			"#define BLENDING_LINEAR 1\n" +
			"#define BLENDING_MULTIPLY 2\n" +
			"#define BLENDING_ADD 3\n" +
			"#define BLENDING_LIGHTER 4\n" +
			"#define BLENDING_DARKER 5\n" +
			"uniform sampler2D tDiffuse;\n" +
			"uniform float radius;\n" +
			"uniform float rotateR;\n" +
			"uniform float rotateG;\n" +
			"uniform float rotateB;\n" +
			"uniform float scatter;\n" +
			"uniform float width;\n" +
			"uniform float height;\n" +
			"uniform int shape;\n" +
			"uniform bool disable;\n" +
			"uniform float blending;\n" +
			"uniform int blendingMode;\n" +
			"varying vec2 vUV;\n" +
			"uniform bool greyscale;\n" +
			"const int samples = 8;\n" +
			"\n" +
			"float blend( float a, float b, float t ) {\n" +
			"\n" +
			"// linear blend\n" +
			"	return a * ( 1.0 - t ) + b * t;\n" +
			"\n" +
			"}\n" +
			"\n" +
			"float hypot( float x, float y ) {\n" +
			"\n" +
			"// vector magnitude\n" +
			"	return sqrt( x * x + y * y );\n" +
			"\n" +
			"}\n" +
			"\n" +
			"float rand( vec2 seed ){\n" +
			"\n" +
			"// get pseudo-random number\n" +
			"	return fract( sin( dot( seed.xy, vec2( 12.9898, 78.233 ) ) ) * 43758.5453 );\n" +
			"\n" +
			"}\n" +
			"\n" +
			"float distanceToDotRadius( float channel, vec2 coord, vec2 normal, vec2 p, float angle, float rad_max ) {\n" +
			"\n" +
			"// apply shape-specific transforms\n" +
			"	float dist = hypot( coord.x - p.x, coord.y - p.y );\n" +
			"	float rad = channel;\n" +
			"\n" +
			"	if ( shape == SHAPE_DOT ) {\n" +
			"\n" +
			"		rad = pow( abs( rad ), 1.125 ) * rad_max;\n" +
			"\n" +
			"	} else if ( shape == SHAPE_ELLIPSE ) {\n" +
			"\n" +
			"		rad = pow( abs( rad ), 1.125 ) * rad_max;\n" +
			"\n" +
			"		if ( dist != 0.0 ) {\n" +
			"			float dot_p = abs( ( p.x - coord.x ) / dist * normal.x + ( p.y - coord.y ) / dist * normal.y );\n" +
			"			dist = ( dist * ( 1.0 - SQRT2_HALF_MINUS_ONE ) ) + dot_p * dist * SQRT2_MINUS_ONE;\n" +
			"		}\n" +
			"\n" +
			"	} else if ( shape == SHAPE_LINE ) {\n" +
			"\n" +
			"		rad = pow( abs( rad ), 1.5) * rad_max;\n" +
			"		float dot_p = ( p.x - coord.x ) * normal.x + ( p.y - coord.y ) * normal.y;\n" +
			"		dist = hypot( normal.x * dot_p, normal.y * dot_p );\n" +
			"\n" +
			"	} else if ( shape == SHAPE_SQUARE ) {\n" +
			"\n" +
			"		float theta = atan( p.y - coord.y, p.x - coord.x ) - angle;\n" +
			"		float sin_t = abs( sin( theta ) );\n" +
			"		float cos_t = abs( cos( theta ) );\n" +
			"		rad = pow( abs( rad ), 1.4 );\n" +
			"		rad = rad_max * ( rad + ( ( sin_t > cos_t ) ? rad - sin_t * rad : rad - cos_t * rad ) );\n" +
			"\n" +
			"	}\n" +
			"\n" +
			"	return rad - dist;\n" +
			"\n" +
			"}\n" +
			"\n" +
			"struct Cell {\n" +
			"\n" +
			"// grid sample positions\n" +
			"	vec2 normal;\n" +
			"	vec2 p1;\n" +
			"	vec2 p2;\n" +
			"	vec2 p3;\n" +
			"	vec2 p4;\n" +
			"	float samp2;\n" +
			"	float samp1;\n" +
			"	float samp3;\n" +
			"	float samp4;\n" +
			"\n" +
			"};\n" +
			"\n" +
			"vec4 getSample( vec2 point ) {\n" +
			"\n" +
			"// multi-sampled point\n" +
			"	vec4 tex = texture2D( tDiffuse, vec2( point.x / width, point.y / height ) );\n" +
			"	float base = rand( vec2( floor( point.x ), floor( point.y ) ) ) * PI2;\n" +
			"	float step = PI2 / float( samples );\n" +
			"	float dist = radius * 0.66;\n" +
			"\n" +
			"	for ( int i = 0; i < samples; ++i ) {\n" +
			"\n" +
			"		float r = base + step * float( i );\n" +
			"		vec2 coord = point + vec2( cos( r ) * dist, sin( r ) * dist );\n" +
			"		tex += texture2D( tDiffuse, vec2( coord.x / width, coord.y / height ) );\n" +
			"\n" +
			"	}\n" +
			"\n" +
			"	tex /= float( samples ) + 1.0;\n" +
			"	return tex;\n" +
			"\n" +
			"}\n" +
			"\n" +
			"float getDotColour( Cell c, vec2 p, int channel, float angle, float aa ) {\n" +
			"\n" +
			"// get colour for given point\n" +
			"	float dist_c_1, dist_c_2, dist_c_3, dist_c_4, res;\n" +
			"\n" +
			"	if ( channel == 0 ) {\n" +
			"\n" +
			"		c.samp1 = getSample( c.p1 ).r;\n" +
			"		c.samp2 = getSample( c.p2 ).r;\n" +
			"		c.samp3 = getSample( c.p3 ).r;\n" +
			"		c.samp4 = getSample( c.p4 ).r;\n" +
			"\n" +
			"	} else if (channel == 1) {\n" +
			"\n" +
			"		c.samp1 = getSample( c.p1 ).g;\n" +
			"		c.samp2 = getSample( c.p2 ).g;\n" +
			"		c.samp3 = getSample( c.p3 ).g;\n" +
			"		c.samp4 = getSample( c.p4 ).g;\n" +
			"\n" +
			"	} else {\n" +
			"\n" +
			"		c.samp1 = getSample( c.p1 ).b;\n" +
			"		c.samp3 = getSample( c.p3 ).b;\n" +
			"		c.samp2 = getSample( c.p2 ).b;\n" +
			"		c.samp4 = getSample( c.p4 ).b;\n" +
			"\n" +
			"	}\n" +
			"\n" +
			"	dist_c_1 = distanceToDotRadius( c.samp1, c.p1, c.normal, p, angle, radius );\n" +
			"	dist_c_2 = distanceToDotRadius( c.samp2, c.p2, c.normal, p, angle, radius );\n" +
			"	dist_c_3 = distanceToDotRadius( c.samp3, c.p3, c.normal, p, angle, radius );\n" +
			"	dist_c_4 = distanceToDotRadius( c.samp4, c.p4, c.normal, p, angle, radius );\n" +
			"	res = ( dist_c_1 > 0.0 ) ? clamp( dist_c_1 / aa, 0.0, 1.0 ) : 0.0;\n" +
			"	res += ( dist_c_2 > 0.0 ) ? clamp( dist_c_2 / aa, 0.0, 1.0 ) : 0.0;\n" +
			"	res += ( dist_c_3 > 0.0 ) ? clamp( dist_c_3 / aa, 0.0, 1.0 ) : 0.0;\n" +
			"	res += ( dist_c_4 > 0.0 ) ? clamp( dist_c_4 / aa, 0.0, 1.0 ) : 0.0;\n" +
			"	res = clamp( res, 0.0, 1.0 );\n" +
			"\n" +
			"	return res;\n" +
			"\n" +
			"}\n" +
			"\n" +
			"Cell getReferenceCell( vec2 p, vec2 origin, float grid_angle, float step ) {\n" +
			"\n" +
			"// get containing cell\n" +
			"	Cell c;\n" +
			"\n" +
			"// calc grid\n" +
			"	vec2 n = vec2( cos( grid_angle ), sin( grid_angle ) );\n" +
			"	float threshold = step * 0.5;\n" +
			"	float dot_normal = n.x * ( p.x - origin.x ) + n.y * ( p.y - origin.y );\n" +
			"	float dot_line = -n.y * ( p.x - origin.x ) + n.x * ( p.y - origin.y );\n" +
			"	vec2 offset = vec2( n.x * dot_normal, n.y * dot_normal );\n" +
			"	float offset_normal = mod( hypot( offset.x, offset.y ), step );\n" +
			"	float normal_dir = ( dot_normal < 0.0 ) ? 1.0 : -1.0;\n" +
			"	float normal_scale = ( ( offset_normal < threshold ) ? -offset_normal : step - offset_normal ) * normal_dir;\n" +
			"	float offset_line = mod( hypot( ( p.x - offset.x ) - origin.x, ( p.y - offset.y ) - origin.y ), step );\n" +
			"	float line_dir = ( dot_line < 0.0 ) ? 1.0 : -1.0;\n" +
			"	float line_scale = ( ( offset_line < threshold ) ? -offset_line : step - offset_line ) * line_dir;\n" +
			"\n" +
			"// get closest corner\n" +
			"	c.normal = n;\n" +
			"	c.p1.x = p.x - n.x * normal_scale + n.y * line_scale;\n" +
			"	c.p1.y = p.y - n.y * normal_scale - n.x * line_scale;\n" +
			"\n" +
			"// scatter\n" +
			"	if ( scatter != 0.0 ) {\n" +
			"\n" +
			"		float off_mag = scatter * threshold * 0.5;\n" +
			"		float off_angle = rand( vec2( floor( c.p1.x ), floor( c.p1.y ) ) ) * PI2;\n" +
			"		c.p1.x += cos( off_angle ) * off_mag;\n" +
			"		c.p1.y += sin( off_angle ) * off_mag;\n" +
			"\n" +
			"	}\n" +
			"\n" +
			"// find corners\n" +
			"	float normal_step = normal_dir * ( ( offset_normal < threshold ) ? step : -step );\n" +
			"	float line_step = line_dir * ( ( offset_line < threshold ) ? step : -step );\n" +
			"	c.p2.x = c.p1.x - n.x * normal_step;\n" +
			"	c.p2.y = c.p1.y - n.y * normal_step;\n" +
			"	c.p3.x = c.p1.x + n.y * line_step;\n" +
			"	c.p3.y = c.p1.y - n.x * line_step;\n" +
			"	c.p4.x = c.p1.x - n.x * normal_step + n.y * line_step;\n" +
			"	c.p4.y = c.p1.y - n.y * normal_step - n.x * line_step;\n" +
			"\n" +
			"	return c;\n" +
			"\n" +
			"}\n" +
			"\n" +
			"float blendColour( float a, float b, float t ) {\n" +
			"\n" +
			"// blend colours\n" +
			"	if ( blendingMode == BLENDING_LINEAR ) {\n" +
			"		return blend( a, b, 1.0 - t );\n" +
			"	} else if ( blendingMode == BLENDING_ADD ) {\n" +
			"		return blend( a, min( 1.0, a + b ), t );\n" +
			"	} else if ( blendingMode == BLENDING_MULTIPLY ) {\n" +
			"		return blend( a, max( 0.0, a * b ), t );\n" +
			"	} else if ( blendingMode == BLENDING_LIGHTER ) {\n" +
			"		return blend( a, max( a, b ), t );\n" +
			"	} else if ( blendingMode == BLENDING_DARKER ) {\n" +
			"		return blend( a, min( a, b ), t );\n" +
			"	} else {\n" +
			"		return blend( a, b, 1.0 - t );\n" +
			"	}\n" +
			"\n" +
			"}\n" +
			"\n" +
			"void main() {\n" +
			"\n" +
			"	if ( ! disable ) {\n" +
			"\n" +
			"// setup\n" +
			"		vec2 p = vec2( vUV.x * width, vUV.y * height );\n" +
			"		vec2 origin = vec2( 0, 0 );\n" +
			"		float aa = ( radius < 2.5 ) ? radius * 0.5 : 1.25;\n" +
			"\n" +
			"// get channel samples\n" +
			"		Cell cell_r = getReferenceCell( p, origin, rotateR, radius );\n" +
			"		Cell cell_g = getReferenceCell( p, origin, rotateG, radius );\n" +
			"		Cell cell_b = getReferenceCell( p, origin, rotateB, radius );\n" +
			"		float r = getDotColour( cell_r, p, 0, rotateR, aa );\n" +
			"		float g = getDotColour( cell_g, p, 1, rotateG, aa );\n" +
			"		float b = getDotColour( cell_b, p, 2, rotateB, aa );\n" +
			"\n" +
			"// blend with original\n" +
			"		vec4 colour = texture2D( tDiffuse, vUV );\n" +
			"		r = blendColour( r, colour.r, blending );\n" +
			"		g = blendColour( g, colour.g, blending );\n" +
			"		b = blendColour( b, colour.b, blending );\n" +
			"\n" +
			"		if ( greyscale ) {\n" +
			"			r = g = b = (r + b + g) / 3.0;\n" +
			"		}\n" +
			"\n" +
			"		gl_FragColor = vec4( r, g, b, 1.0 );\n" +
			"\n" +
			"	} else {\n" +
			"\n" +
			"		gl_FragColor = texture2D( tDiffuse, vUV );\n" +
			"\n" +
			"	}\n" +
			"\n" +
			"}";
	}

	public new():Void {
		super(HalftoneShader.uniforms, HalftoneShader.vertexShader, HalftoneShader.fragmentShader);
	}

	public setDiffuse(texture:Texture):Void {
		this.uniforms.tDiffuse.value = texture;
	}

	public setShape(value:Int):Void {
		this.uniforms.shape.value = value;
	}

	public setRadius(value:Float):Void {
		this.uniforms.radius.value = value;
	}

	public setRotateR(value:Float):Void {
		this.uniforms.rotateR.value = value;
	}

	public setRotateG(value:Float):Void {
		this.uniforms.rotateG.value = value;
	}

	public setRotateB(value:Float):Void {
		this.uniforms.rotateB.value = value;
	}

	public setScatter(value:Float):Void {
		this.uniforms.scatter.value = value;
	}

	public setWidth(value:Float):Void {
		this.uniforms.width.value = value;
	}

	public setHeight(value:Float):Void {
		this.uniforms.height.value = value;
	}

	public setBlending(value:Float):Void {
		this.uniforms.blending.value = value;
	}

	public setBlendingMode(value:Int):Void {
		this.uniforms.blendingMode.value = value;
	}

	public setGreyscale(value:Bool):Void {
		this.uniforms.greyscale.value = value;
	}

	public setDisable(value:Bool):Void {
		this.uniforms.disable.value = value;
	}

}