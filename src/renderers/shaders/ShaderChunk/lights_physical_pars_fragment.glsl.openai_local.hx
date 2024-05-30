package three.renderers.shaders.ShaderChunk;

import haxe.io.Bytes;

class LightsPhysicalParsFragment {
    public static inline var lightsPhysicalParsFragment:String = /* glsl */'''

struct PhysicalMaterial {
	vec3 diffuseColor;
	float roughness;
	vec3 specularColor;
	float specularF90;
	float dispersion;

	#if defined(USE_CLEARCOAT)
		float clearcoat;
		float clearcoatRoughness;
		vec3 clearcoatF0;
		float clearcoatF90;
	#end

	#if defined(USE_IRIDESCENCE)
		float iridescence;
		float iridescenceIOR;
		float iridescenceThickness;
		vec3 iridescenceFresnel;
		vec3 iridescenceF0;
	#end

	#if defined(USE_SHEEN)
		vec3 sheenColor;
		float sheenRoughness;
	#end

	#if defined(IOR)
		float ior;
	#end

	#if defined(USE_TRANSMISSION)
		float transmission;
		float transmissionAlpha;
		float thickness;
		float attenuationDistance;
		vec3 attenuationColor;
	#end

	#if defined(USE_ANISOTROPY)
		float anisotropy;
		float alphaT;
		vec3 anisotropyT;
		vec3 anisotropyB;
	#end
};

// temporary
vec3 clearcoatSpecularDirect = vec3( 0.0 );
vec3 clearcoatSpecularIndirect = vec3( 0.0 );
vec3 sheenSpecularDirect = vec3( 0.0 );
vec3 sheenSpecularIndirect = vec3( 0.0 );

vec3 Schlick_to_F0( const in vec3 f, const in float f90, const in float dotVH ) {
	float x = clamp( 1.0 - dotVH, 0.0, 1.0 );
	float x2 = x * x;
	float x5 = clamp( x * x2 * x2, 0.0, 0.9999 );

	return ( f - vec3( f90 ) * x5 ) / ( 1.0 - x5 );
}

// Moving Frostbite to Physically Based Rendering 3.0 - page 12, listing 2
// https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
float V_GGX_SmithCorrelated( const in float alpha, const in float dotNL, const in float dotNV ) {
	float a2 = pow2( alpha );

	float gv = dotNL * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNV ) );
	float gl = dotNV * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNL ) );

	return 0.5 / max( gv + gl, EPSILON );
}

// Microfacet Models for Refraction through Rough Surfaces - equation (33)
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
// alpha is "roughness squared" in Disney’s reparameterization
float D_GGX( const in float alpha, const in float dotNH ) {
	float a2 = pow2( alpha );

	float denom = pow2( dotNH ) * ( a2 - 1.0 ) + 1.0; // avoid alpha = 0 with dotNH = 1

	return RECIPROCAL_PI * a2 / pow2( denom );
}

// https://google.github.io/filament/Filament.md.html#materialsystem/anisotropicmodel/anisotropicspecularbrdf
#if defined(USE_ANISOTROPY)
	float V_GGX_SmithCorrelated_Anisotropic( const in float alphaT, const in float alphaB, const in float dotTV, const in float dotBV, const in float dotTL, const in float dotBL, const in float dotNV, const in float dotNL ) {
		float gv = dotNL * length( vec3( alphaT * dotTV, alphaB * dotBV, dotNV ) );
		float gl = dotNV * length( vec3( alphaT * dotTL, alphaB * dotBL, dotNL ) );
		float v = 0.5 / ( gv + gl );

		return saturate(v);
	}

	float D_GGX_Anisotropic( const in float alphaT, const in float alphaB, const in float dotNH, const in float dotTH, const in float dotBH ) {
		float a2 = alphaT * alphaB;
		highp vec3 v = vec3( alphaB * dotTH, alphaT * dotBH, a2 * dotNH );
		highp float v2 = dot( v, v );
		float w2 = a2 / v2;

		return RECIPROCAL_PI * a2 * pow2 ( w2 );
	}
#end

#if defined(USE_CLEARCOAT)
	// GGX Distribution, Schlick Fresnel, GGX_SmithCorrelated Visibility
	vec3 BRDF_GGX_Clearcoat( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material) {
		vec3 f0 = material.clearcoatF0;
		float f90 = material.clearcoatF90;
		float roughness = material.clearcoatRoughness;

		float alpha = pow2( roughness ); // UE4's roughness

		vec3 halfDir = normalize( lightDir + viewDir );

		float dotNL = saturate( dot( normal, lightDir ) );
		float dotNV = saturate( dot( normal, viewDir ) );
		float dotNH = saturate( dot( normal, halfDir ) );
		float dotVH = saturate( dot( viewDir, halfDir ) );

		vec3 F = F_Schlick( f0, f90, dotVH );

		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );

		float D = D_GGX( alpha, dotNH );

		return F * ( V * D );
	}
#end

vec3 BRDF_GGX( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material ) {
	vec3 f0 = material.specularColor;
	float f90 = material.specularF90;
	float roughness = material.roughness;

	float alpha = pow2( roughness ); // UE4's roughness

	vec3 halfDir = normalize( lightDir + viewDir );

	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );

	vec3 F = F_Schlick( f0, f90, dotVH );

	#if defined(USE_IRIDESCENCE)
		F = mix( F, material.iridescenceFresnel, material.iridescence );
	#end

	#if defined(USE_ANISOTROPY)
		float dotTL = dot( material.anisotropyT, lightDir );
		float dotTV = dot( material.anisotropyT, viewDir );
		float dotTH = dot( material.anisotropyT, halfDir );
		float dotBL = dot( material.anisotropyB, lightDir );
		float dotBV = dot( material.anisotropyB, viewDir );
		float dotBH = dot( material.anisotropyB, halfDir );

		float V = V_GGX_SmithCorrelated_Anisotropic( material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL );

		float D = D_GGX_Anisotropic( material.alphaT, alpha, dotNH, dotTH, dotBH );
	#else
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
	#end

	return F * ( V * D );
}

// Rect Area Light

// Real-Time Polygonal-Light Shading with Linearly Transformed Cosines
// by Eric Heitz, Jonathan Dupuy, Stephen Hill and David Neubelt
// code: https://github.com/selfshadow/ltc_code/

vec2 LTC_Uv( const in vec3 N, const in vec3 V, const in float roughness ) {
	const float LUT_SIZE = 64.0;
	const float LUT_SCALE = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	const float LUT_BIAS = 0.5 / LUT_SIZE;

	float dotNV = saturate( dot( N, V ) );

	// texture parameterized by sqrt( GGX alpha ) and sqrt( 1 - cos( theta ) )
	vec2 uv = vec2( roughness, sqrt( 1.0 - dotNV ) );

	uv = uv * LUT_SCALE + LUT_BIAS;

	return uv;
}

float LTC_ClippedSphereFormFactor( const in vec3 f ) {
	// Real-Time Area Lighting: a Journey from Research to Production (p.102)
	// An approximation of the form factor of a horizon-clipped rectangle.

	float l = length( f );

	return max( ( l * l + f.z ) / ( l + 1.0 ), 0.0 );
}

vec3 LTC_EdgeVectorFormFactor( const in vec3 v1, const in vec3 v2 ) {
	float x = dot( v1, v2 );

	float y = abs( x );

	float a = 1.0 / ( y + 1.0 );

	float b = a * ( 1.0 - y );

	vec3 result = ( sign( x ) * a * ( v1 + v2 ) - v1 - v2 ) * b;

	return result;
}

float LTC_Eval( const in vec3 N, const in vec3 V, const in vec3 P, const in vec3 pos, const in vec3 halfWidth, const in vec3 halfHeight, const in mat3 mInv, const in float specularF90, const in vec3 specularColor, const in float roughness ) {
	vec3 T1, T2;
	T1 = normalize( V - N * dot( V, N ) );
	T2 = cross( N, T1 );

	// convert to local rectangle vertex positions
	vec3 v1 = pos - P - halfWidth - halfHeight;
	vec3 v2 = pos - P + halfWidth - halfHeight;
	vec3 v3 = pos - P + halfWidth + halfHeight;
	vec3 v4 = pos - P - halfWidth + halfHeight;

	// texture coordinates
	vec2 uv = LTC_Uv( N, V, roughness );

	// interpolate LTC matrix
	mat3 minv = mInv;

	// rotate to align with N
	minv = minv * mat3( T1, T2, N );

	// transform vertices to local space
	v1 = minv * v1;
	v2 = minv * v2;
	v3 = minv * v3;
	v4 = minv * v4;

	// edge vectors
	vec3 v1v2 = v2 - v1;
	vec3 v2v3 = v3 - v2;
	vec3 v3v4 = v4 - v3;
	vec3 v4v1 = v1 - v4;

	// form factors
	vec3 ff1 = LTC_EdgeVectorFormFactor( v1, v2 );
	vec3 ff2 = LTC_EdgeVectorFormFactor( v2, v3 );
	vec3 ff3 = LTC_EdgeVectorFormFactor( v3, v4 );
	vec3 ff4 = LTC_EdgeVectorFormFactor( v4, v1 );

	// incoming radiance
	vec3 Li = vec3( 1.0, 1.0, 1.0 );

	// accumulate
	float len_v1v2 = length( v1v2 );
	float len_v2v3 = length( v2v3 );
	float len_v3v4 = length( v3v4 );
	float len_v4v1 = length( v4v1 );

	float maxEdge = max( max( len_v1v2, len_v2v3 ), max( len_v3v4, len_v4v1 ) );

	vec3 sum = vec3( 0.0 );

	if ( maxEdge < 1.0 ) {
		sum += Li * ( dot( v1v2, ff1 ) + dot( v2v3, ff2 ) + dot( v3v4, ff3 ) + dot( v4v1, ff4 ) );
	} else {
		// max subdivision count
		int subdiv = int( ceil( log2( maxEdge ) ) );

		// clamp
		subdiv = min( subdiv, 32 );

		for ( int i = 0; i < subdiv; i ++ ) {
			// midpoints
			vec3 v12 = ( v1 + v2 ) * 0.5;
			vec3 v23 = ( v2 + v3 ) * 0.5;
			vec3 v34 = ( v3 + v4 ) * 0.5;
			vec3 v41 = ( v4 + v1 ) * 0.5;

			// quad areas
			float area1 = LTC_ClippedSphereFormFactor( v1 ) * LTC_ClippedSphereFormFactor( v12 ) * LTC_ClippedSphereFormFactor( v2 );
			float area2 = LTC_ClippedSphereFormFactor( v2 ) * LTC_ClippedSphereFormFactor( v23 ) * LTC_ClippedSphereFormFactor( v3 );
			float area3 = LTC_ClippedSphereFormFactor( v3 ) * LTC_ClippedSphereFormFactor( v34 ) * LTC_ClippedSphereFormFactor( v4 );
			float area4 = LTC_ClippedSphereFormFactor( v4 ) * LTC_ClippedSphereFormFactor( v41 ) * LTC_ClippedSphereFormFactor( v1 );

			// subdivide
			sum += Li * ( area1 + area2 + area3 + area4 ) / float( subdiv );
		}
	}

	// weighting factor
	float ltc = 4.0 / max( 1.0 + maxEdge, 2.0 );

	return ltc * sum.x;
}

'''';
}