typedef PhysicalMaterial {
	var diffuseColor:Vec3<Float>;
	var roughness:Float;
	var specularColor:Vec3<Float>;
	var specularF90:Float;
	var dispersion:Float;
	#if defined( USE_CLEARCOAT )
		var clearcoat:Float;
		var clearcoatRoughness:Float;
		var clearcoatF0:Vec3<Float>;
		var clearcoatF90:Float;
	#end
	#if defined( USE_IRIDESCENCE )
		var iridescence:Float;
		var iridescenceIOR:Float;
		var iridescenceThickness:Float;
		var iridescenceFresnel:Vec3<Float>;
		var iridescenceF0:Vec3<Float>;
	#end
	#if defined( USE_SHEEN )
		var sheenColor:Vec3<Float>;
		var sheenRoughness:Float;
	#end
	#if defined( IOR )
		var ior:Float;
	#end
	#if defined( USE_TRANSMISSION )
		var transmission:Float;
		var transmissionAlpha:Float;
		var thickness:Float;
		var attenuationDistance:Float;
		var attenuationColor:Vec3<Float>;
	#end
	#if defined( USE_ANISOTROPY )
		var anisotropy:Float;
		var alphaT:Float;
		var anisotropyT:Vec3<Float>;
		var anisotropyB:Vec3<Float>;
	#end
}

// temporary
var clearcoatSpecularDirect:Vec3<Float> = Vec3<Float>( 0.0 );
var clearcoatSpecularIndirect:Vec3<Float> = Vec3<Float>( 0.0 );
var sheenSpecularDirect:Vec3<Float> = Vec3<Float>( 0.0 );
var sheenSpecularIndirect:Vec3<Float> = Vec3<Float>( 0.0 );

function Schlick_to_F0( f:Vec3<Float>, f90:Float, dotVH:Float ):Vec3<Float> {
	var x:Float = saturate( 1.0 - dotVH );
	var x2:Float = x * x;
	var x5:Float = saturate( x * x2 * x2 );

	return ( f - Vec3<Float>( f90 ) * x5 ) / ( 1.0 - x5 );
}

// Moving Frostbite to Physically Based Rendering 3.0 - page 12, listing 2
// https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
function V_GGX_SmithCorrelated( alpha:Float, dotNL:Float, dotNV:Float ):Float {
	var a2:Float = alpha * alpha;

	var gv:Float = dotNL * sqrt( a2 + ( 1.0 - a2 ) * ( dotNV * dotNV ) );
	var gl:Float = dotNV * sqrt( a2 + ( 1.0 - a2 ) * ( dotNL * dotNL ) );

	return 0.5 / max( gv + gl, EPSILON );
}

// Microfacet Models for Refraction through Rough Surfaces - equation (33)
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
// alpha is "roughness squared" in Disney’s reparameterization
function D_GGX( alpha:Float, dotNH:Float ):Float {
	var a2:Float = alpha * alpha;

	var denom:Float = ( dotNH * dotNH ) * ( a2 - 1.0 ) + 1.0; // avoid alpha = 0 with dotNH = 1

	return RECIPROCAL_PI * a2 / ( denom * denom );
}

// https://google.github.io/filament/Filament.md.html#materialsystem/anisotropicmodel/anisotropicspecularbrdf
#if defined( USE_ANISOTROPY )

	function V_GGX_SmithCorrelated_Anisotropic( alphaT:Float, alphaB:Float, dotTV:Float, dotBV:Float, dotTL:Float, dotBL:Float, dotNV:Float, dotNL:Float ):Float {
		var gv:Float = dotNL * length( Vec3<Float>( alphaT * dotTV, alphaB * dotBV, dotNV ) );
		var gl:Float = dotNV * length( Vec3<Float>( alphaT * dotTL, alphaB * dotBL, dotNL ) );
		var v:Float = 0.5 / ( gv + gl );

		return saturate(v);
	}

	function D_GGX_Anisotropic( alphaT:Float, alphaB:Float, dotNH:Float, dotTH:Float, dotBH:Float ):Float {
		var a2:Float = alphaT * alphaB;
		var v:Vec3<Float> = Vec3<Float>( alphaB * dotTH, alphaT * dotBH, a2 * dotNH );
		var v2:Float = lengthSquared( v );
		var w2:Float = a2 / v2;

		return RECIPROCAL_PI * a2 * ( w2 * w2 );
	}

#end

#if defined( USE_CLEARCOAT )

	// GGX Distribution, Schlick Fresnel, GGX_SmithCorrelated Visibility
	function BRDF_GGX_Clearcoat( lightDir:Vec3<Float>, viewDir:Vec3<Float>, normal:Vec3<Float>, material:PhysicalMaterial ):Vec3<Float> {
		var f0:Vec3<Float> = material.clearcoatF0;
		var f90:Float = material.clearcoatF90;
		var roughness:Float = material.clearcoatRoughness;

		var alpha:Float = roughness * roughness; // UE4's roughness

		var halfDir:Vec3<Float> = normalize( lightDir + viewDir );

		var dotNL:Float = saturate( dot( normal, lightDir ) );
		var dotNV:Float = saturate( dot( normal, viewDir ) );
		var dotNH:Float = saturate( dot( normal, halfDir ) );
		var dotVH:Float = saturate( dot( viewDir, halfDir ) );

		var F:Vec3<Float> = F_Schlick( f0, f90, dotVH );

		var V:Float = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );

		var D:Float = D_GGX( alpha, dotNH );

		return F * ( V * D );
	}

#end

function BRDF_GGX( lightDir:Vec3<Float>, viewDir:Vec3<Float>, normal:Vec3<Float>, material:PhysicalMaterial ):Vec3<Float> {
	var f0:Vec3<Float> = material.specularColor;
	var f90:Float = material.specularF90;
	var roughness:Float = material.roughness;

	var alpha:Float = roughness * roughness; // UE4's roughness

	var halfDir:Vec3<Float> = normalize( lightDir + viewDir );

	var dotNL:Float = saturate( dot( normal, lightDir ) );
	var dotNV:Float = saturate( dot( normal, viewDir ) );
	var dotNH:Float = saturate( dot( normal, halfDir ) );
	var dotVH:Float = saturate( dot( viewDir, halfDir ) );

	var F:Vec3<Float> = F_Schlick( f0, f90, dotVH );

	#if defined( USE_IRIDESCENCE )

		F = mix( F, material.iridescenceFresnel, material.iridescence );

	#end

	#if defined( USE_ANISOTROPY )

		var dotTL:Float = dot( material.anisotropyT, lightDir );
		var dotTV:Float = dot( material.anisotropyT, viewDir );
		var dotTH:Float = dot( material.anisotropyT, halfDir );
		var dotBL:Float = dot( material.anisotropyB, lightDir );
		var dotBV:Float = dot( material.anisotropyB, viewDir );
		var dotBH:Float = dot( material.anisotropyB, halfDir );

		var V:Float = V_GGX_SmithCorrelated_Anisotropic( material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL );

		var D:Float = D_GGX_Anisotropic( material.alphaT, alpha, dotNH, dotTH, dotBH );

	#else

		var V:Float = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );

		var D:Float = D_GGX( alpha, dotNH );

	#end

	return F * ( V * D );
}

// Rect Area Light

// Real-Time Polygonal-Light Shading with Linearly Transformed Cosines
// by Eric Heitz, Jonathan Dupuy, Stephen Hill and David Neubelt
// code: https://github.com/selfshadow/ltc_code/

function LTC_Uv( N:Vec3<Float>, V:Vec3<Float>, roughness:Float ):Vec2<Float> {
	var LUT_SIZE:Float = 64.0;
	var LUT_SCALE:Float = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	var LUT_BIAS:Float = 0.5 / LUT_SIZE;

	var dotNV:Float = saturate( dot( N, V ) );

	// texture parameterized by sqrt( GGX alpha ) and sqrt( 1 - cos( theta ) )
	var uv:Vec2<Float> = Vec2<Float>( roughness, sqrt( 1.0 - dotNV ) );

	uv = uv * LUT_SCALE + LUT_BIAS;

	return uv;
}

function LTC_ClippedSphereFormFactor( f:Vec3<Float> ):Float {
	// Real-Time Area Lighting: a Journey from Research to Production (p.102)
	// An approximation of the form factor of a horizon-clipped rectangle.

	var l:Float = length( f );

	return max( ( l * l + f.z ) / ( l + 1.0 ), 0.0 );
}

function LTC_EdgeVectorFormFactor( v1:Vec3<Float>, v2:Vec3<Float> ):Vec3<Float> {
	var x:Float = dot( v1, v2 );

	var y:Float = abs( x );

	// rational polynomial approximation to theta / sin( theta ) / 2PI
	var a:Float = 0.8543985 + ( 0.4965155 + 0.0145206 * y ) * y;
	var b:Float = 3.4175940 + ( 4.1616724 + y ) * y;
	var v:Float = a / b;

	var theta_sintheta:Float = ( x > 0.0 ) ? v : 0.5 * inversesqrt( max( 1.0 - x * x, 1e-7 ) ) - v;

	return cross( v1, v2 ) * theta_sintheta;
}

function LTC_Evaluate( N:Vec3<Float>, V:Vec3<Float>, P:Vec3<Float>, mInv:Mat3<Float>, rectCoords:Array<Vec3<Float>> ):Vec3<Float> {
	// bail if point is on back side of plane of light
	// assumes ccw winding order of light vertices
	var v1:Vec3<Float> = rectCoords[ 1 ] - rectCoords[ 0 ];
	var v2:Vec3<Float> = rectCoords[ 3 ] - rectCoords[ 0 ];
	var lightNormal:Vec3<Float> = cross( v1, v2 );

	if( dot( lightNormal, P - rectCoords[ 0 ] ) < 0.0 ) return Vec3<Float>( 0.0 );

	// construct orthonormal basis around N
	var T1:Vec3<Float>, T2:Vec3<Float>;
	T1 = normalize( V - N * dot( V, N ) );
	T2 = - cross( N, T1 ); // negated from paper; possibly due to a different handedness of world coordinate system

	// compute transform
	var mat:Mat3<Float> = mInv * transpose( Mat3<Float>( T1, T2, N ) );

	// transform rect
	var coords:Array<Vec3<Float>> = [
		mat * ( rectCoords[ 0 ] - P ),
		mat * ( rectCoords[ 1 ] - P ),
		mat * ( rectCoords[ 2 ] - P ),
		mat * ( rectCoords[ 3 ] - P )
	];

	// project rect onto sphere
	coords[ 0 ] = normalize( coords[ 0 ] );
	coords[ 1 ] = normalize( coords[ 1 ] );
	coords[ 2 ] = normalize( coords[ 2 ] );
	coords[ 3 ] = normalize( coords[ 3 ] );

	// calculate vector form factor
	var vectorFormFactor:Vec3<Float> = Vec3<Float>( 0.0 );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 0 ], coords[ 1 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 1 ], coords[ 2 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 2 ], coords[ 3 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 3 ], coords[ 0 ] );

	// adjust for horizon clipping
	var result:Float = LTC_ClippedSphereFormFactor( vectorFormFactor );

/*
	// alternate method of adjusting for horizon clipping (see referece)
	// refactoring required
	var len:Float = length( vectorFormFactor );
	var z:Float = vectorFormFactor.z / len;

	const float LUT_SIZE = 64.0;
	const float LUT_SCALE = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	const float LUT_BIAS = 0.5 / LUT_SIZE;

	// tabulated horizon-clipped sphere, apparently...
	var uv:Vec2<Float> = Vec2<Float>( z * 0.5 + 0.5, len );
	uv = uv * LUT_SCALE + LUT_BIAS;

	var scale:Float = texture2D( ltc_2, uv ).w;

	var result:Float = len * scale;
*/

	return Vec3<Float>( result );
}

// End Rect Area Light

#if defined( USE_SHEEN )

// https://github.com/google/filament/blob/master/shaders/src/brdf.fs
function D_Charlie( roughness:Float, dotNH:Float ):Float {
	var alpha:Float = roughness * roughness;

	// Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
	var invAlpha:Float = 1.0 / alpha;
	var cos2h:Float = dotNH * dotNH;
	var sin2h:Float = max( 1.0 - cos2h, 0.0078125 ); // 2^(-14/2), so sin2h^2 > 0 in fp16

	return ( 2.0 + invAlpha ) * pow( sin2h, invAlpha * 0.5 ) / ( 2.0 * PI );
}

// https://github.com/google/filament/blob/master/shaders/src/brdf.fs
function V_Neubelt( dotNV:Float, dotNL:Float ):Float {
	// Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
	return saturate( 1.0 / ( 4.0 * ( dotNL + dotNV - dotNL * dotNV ) ) );
}

function BRDF_Sheen( lightDir:Vec3<Float>, viewDir:Vec3<Float>, normal:Vec3<Float>, sheenColor:Vec3<Float>, sheenRoughness:Float ):Vec3<Float> {
	var halfDir:Vec3<Float> = normalize( lightDir + viewDir );

	var dotNL:Float = saturate( dot( normal, lightDir ) );
	var dotNV:Float = saturate( dot( normal, viewDir ) );
	var dotNH:Float = saturate( dot(
var dotNH:Float = saturate( dot( normal, halfDir ) );

	var D:Float = D_Charlie( sheenRoughness, dotNH );
	var V:Float = V_Neubelt( dotNV, dotNL );

	return sheenColor * ( D * V );
}

#end

// This is a curve-fit approxmation to the "Charlie sheen" BRDF integrated over the hemisphere from 
// Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF". The analysis can be found
// in the Sheen section of https://drive.google.com/file/d/1T0D1VSyR4AllqIJTQAraEIzjlb5h4FKH/view?usp=sharing
function IBLSheenBRDF( normal:Vec3<Float>, viewDir:Vec3<Float>, roughness:Float ):Float {
	var dotNV:Float = saturate( dot( normal, viewDir ) );

	var r2:Float = roughness * roughness;

	var a:Float = ( roughness < 0.25 ) ? -339.2 * r2 + 161.4 * roughness - 25.9 : -8.48 * r2 + 14.3 * roughness - 9.95;

	var b:Float = ( roughness < 0.25 ) ? 44.0 * r2 - 23.7 * roughness + 3.26 : 1.97 * r2 - 3.27 * roughness + 0.72;

	var DG:Float = exp( a * dotNV + b ) + ( ( roughness < 0.25 ) ? 0.0 : 0.1 * ( roughness - 0.25 ) );

	return saturate( DG * RECIPROCAL_PI );
}

// Analytical approximation of the DFG LUT, one half of the
// split-sum approximation used in indirect specular lighting.
// via 'environmentBRDF' from "Physically Based Shading on Mobile"
// https://www.unrealengine.com/blog/physically-based-shading-on-mobile
function DFGApprox( normal:Vec3<Float>, viewDir:Vec3<Float>, roughness:Float ):Vec2<Float> {
	var dotNV:Float = saturate( dot( normal, viewDir ) );

	var c0:Vec4<Float> = Vec4<Float>( - 1.0, - 0.0275, - 0.572, 0.022 );

	var c1:Vec4<Float> = Vec4<Float>( 1.0, 0.0425, 1.04, - 0.04 );

	var r:Vec4<Float> = Vec4<Float>( roughness, 0.0, 0.0, 0.0 );
	r = r * c0 + c1;

	var a004:Float = min( r.x * r.x, exp2( - 9.28 * dotNV ) ) * r.x + r.y;

	var fab:Vec2<Float> = Vec2<Float>( - 1.04, 1.04 ) * a004 + Vec2<Float>( r.z, r.w );

	return fab;
}

function EnvironmentBRDF( normal:Vec3<Float>, viewDir:Vec3<Float>, specularColor:Vec3<Float>, specularF90:Float, roughness:Float ):Vec3<Float> {
	var fab:Vec2<Float> = DFGApprox( normal, viewDir, roughness );

	return specularColor * fab.x + Vec3<Float>( specularF90 ) * fab.y;
}

// Fdez-Agüera's "Multiple-Scattering Microfacet Model for Real-Time Image Based Lighting"
// Approximates multiscattering in order to preserve energy.
// http://www.jcgt.org/published/0008/01/03/
#if defined( USE_IRIDESCENCE )
function computeMultiscatteringIridescence( normal:Vec3<Float>, viewDir:Vec3<Float>, specularColor:Vec3<Float>, specularF90:Float, iridescence:Float, iridescenceF0:Vec3<Float>, roughness:Float, singleScatter:Float, multiScatter:Float ) {
#else
function computeMultiscattering( normal:Vec3<Float>, viewDir:Vec3<Float>, specularColor:Vec3<Float>, specularF90:Float, roughness:Float, singleScatter:Float, multiScatter:Float ) {
#end
	var fab:Vec2<Float> = DFGApprox( normal, viewDir, roughness );

	#if defined( USE_IRIDESCENCE )

		var Fr:Vec3<Float> = mix( specularColor, iridescenceF0, iridescence );

	#else

		var Fr:Vec3<Float> = specularColor;

	#end

	var FssEss:Vec3<Float> = Fr * fab.x + Vec3<Float>( specularF90 ) * fab.y;

	var Ess:Float = fab.x + fab.y;
	var Ems:Float = 1.0 - Ess;

	var Favg:Vec3<Float> = Fr + ( 1.0 - Fr ) * 0.047619; // 1/21
	var Fms:Vec3<Float> = FssEss * Favg / ( 1.0 - Ems * Favg );

	singleScatter += FssEss;
	multiScatter += Fms * Ems;
}

#if NUM_RECT_AREA_LIGHTS > 0

	function RE_Direct_RectArea_Physical( rectAreaLight:RectAreaLight, geometryPosition:Vec3<Float>, geometryNormal:Vec3<Float>, geometryViewDir:Vec3<Float>, geometryClearcoatNormal:Vec3<Float>, material:PhysicalMaterial, reflectedLight:ReflectedLight ) {
		var normal:Vec3<Float> = geometryNormal;
		var viewDir:Vec3<Float> = geometryViewDir;
		var position:Vec3<Float> = geometryPosition;
		var lightPos:Vec3<Float> = rectAreaLight.position;
		var halfWidth:Vec3<Float> = rectAreaLight.halfWidth;
		var halfHeight:Vec3<Float> = rectAreaLight.halfHeight;
		var lightColor:Vec3<Float> = rectAreaLight.color;
		var roughness:Float = material.roughness;

		var rectCoords:Array<Vec3<Float>> = [
			lightPos + halfWidth - halfHeight, // counterclockwise; light shines in local neg z direction
			lightPos - halfWidth - halfHeight,
			lightPos - halfWidth + halfHeight,
			lightPos + halfWidth + halfHeight
		];

		var uv:Vec2<Float> = LTC_Uv( normal, viewDir, roughness );

		var t1:Vec4<Float> = texture2D( ltc_1, uv );
		var t2:Vec4<Float> = texture2D( ltc_2, uv );

		var mInv:Mat3<Float> = Mat3<Float>(
			Vec3<Float>( t1.x, 0.0, t1.y ),
			Vec3<Float>( 0.0, 1.0, 0.0 ),
			Vec3<Float>( t1.z, 0.0, t1.w )
		);

		// LTC Fresnel Approximation by Stephen Hill
		// http://blog.selfshadow.com/publications/s2016-advances/s2016_ltc_fresnel.pdf
		var fresnel:Vec3<Float> = ( material.specularColor * t2.x + ( Vec3<Float>( 1.0 ) - material.specularColor ) * t2.y );

		reflectedLight.directSpecular += lightColor * fresnel * LTC_Evaluate( normal, viewDir, position, mInv, rectCoords );

		reflectedLight.directDiffuse += lightColor * material.diffuseColor * LTC_Evaluate( normal, viewDir, position, Mat3<Float>( 1.0 ), rectCoords );

	}

#end

function RE_Direct_Physical( directLight:IncidentLight, geometryPosition:Vec3<Float>, geometryNormal:Vec3<Float>, geometryViewDir:Vec3<Float>, geometryClearcoatNormal:Vec3<Float>, material:PhysicalMaterial, reflectedLight:ReflectedLight ) {
	var dotNL:Float = saturate( dot( geometryNormal, directLight.direction ) );

	var irradiance:Vec3<Float> = directLight.color * dotNL;

	#if defined( USE_CLEARCOAT )

		var dotNLcc:Float = saturate( dot( geometryClearcoatNormal, directLight.direction ) );

		var ccIrradiance:Vec3<Float> = directLight.color * dotNLcc;

		clearcoatSpecularDirect += ccIrradiance * BRDF_GGX_Clearcoat( directLight.direction, geometryViewDir, geometryClearcoatNormal, material );

	#end

	#if defined( USE_SHEEN )

		sheenSpecularDirect += irradiance * BRDF_Sheen( directLight.direction, geometryViewDir, geometryNormal, material.sheenColor, material.sheenRoughness );

	#end

	reflectedLight.directSpecular += irradiance * BRDF_GGX( directLight.direction, geometryViewDir, geometryNormal, material );

	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}

function RE_IndirectDiffuse_Physical( irradiance:Vec3<Float>, geometryPosition:Vec3<Float>, geometryNormal:Vec3<Float>, geometryViewDir:Vec3<Float>, geometryClearcoatNormal:Vec3<Float>, material:PhysicalMaterial, reflectedLight:ReflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}

function RE_IndirectSpecular_Physical( radiance:Vec3<Float>, irradiance:Vec3<Float>, clearcoatRadiance:Vec3<Float>, geometryPosition:Vec3<Float>, geometryNormal:Vec3<Float>, geometryViewDir:Vec3<Float>, geometryClearcoatNormal:Vec3<Float>, material:PhysicalMaterial, reflectedLight:ReflectedLight ) {
	#if defined( USE_CLEARCOAT )

		clearcoatSpecularIndirect += clearcoatRadiance * EnvironmentBRDF( geometryClearcoatNormal, geometryViewDir, material.clearcoatF0, material.clearcoatF90, material.clearcoatRoughness );

	#end

	#if defined( USE_SHEEN )

		sheenSpecularIndirect += irradiance * material.sheenColor * IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness );

	#end

	// Both indirect specular and indirect diffuse light accumulate here

	var singleScattering:Vec3<Float> = Vec3<Float>( 0.0 );
	var multiScattering:Vec3<Float> = Vec3<Float>( 0.0 );
	var cosineWeightedIrradiance:Vec3<Float> = irradiance * RECIPROCAL_PI;

	#if defined( USE_IRIDESCENCE )

		computeMultiscatteringIridescence( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.iridescence, material.iridescenceFresnel, material.roughness, singleScattering, multiScattering );

	#else

		computeMultiscattering( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.roughness, singleScattering, multiScattering );

	#end

	var totalScattering:Vec3<Float> = singleScattering + multiScattering;
	var diffuse:Vec3<Float> = material.diffuseColor * ( 1.0 - max( max( totalScattering.r, totalScattering.g ), totalScattering.b ) );

	reflectedLight.indirectSpecular += radiance * singleScattering;
	reflectedLight.indirectSpecular += multiScattering * cosineWeightedIrradiance;

	reflectedLight.indirectDiffuse += diffuse * cosineWeightedIrradiance;
}

#define RE_Direct RE_Direct_Physical
#define RE_Direct_RectArea RE_Direct_RectArea_Physical
#define RE_IndirectDiffuse RE_IndirectDiffuse_Physical
#define RE_IndirectSpecular RE_IndirectSpecular_Physical

// ref: https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
function computeSpecularOcclusion( dotNV:Float, ambientOcclusion:Float, roughness:Float ):Float {
	return saturate( pow( dotNV + ambientOcclusion, exp2( - 16.0 * roughness - 1.0 ) ) - 1.0 + ambientOcclusion );
}