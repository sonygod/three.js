import LightingModel from '../core/LightingModel.js';
import BRDF_Lambert from './BSDF/BRDF_Lambert.js';
import { diffuseColor } from '../core/PropertyNode.js';
import { normalGeometry } from '../accessors/NormalNode.js';
import { tslFn, float, vec2, vec3 } from '../shadernode/ShaderNode.js';
import { mix, smoothstep } from '../math/MathNode.js';
import { materialReference } from '../accessors/MaterialReferenceNode.js';

static function getGradientIrradiance(normal:Vec3, lightDirection:Vec3, builder:Builder):Vec3 {

	// dotNL will be from -1.0 to 1.0
	var dotNL:Float = normal.dot(lightDirection);
	var coord:Vec2 = vec2(dotNL.mul(0.5).add(0.5), 0.0);

	if (builder.material.gradientMap != null) {

		var gradientMap = materialReference('gradientMap', 'texture').context({getUV: () -> coord});

		return vec3(gradientMap.r);

	} else {

		var fw:Vec2 = coord.fwidth().mul(0.5);

		return mix(vec3(0.7), vec3(1.0), smoothstep(float(0.7).sub(fw.x), float(0.7).add(fw.x), coord.x));

	}

}

class ToonLightingModel extends LightingModel {

	public function new() {
		super();
	}

	public function direct(lightDirection:Vec3, lightColor:Vec3, reflectedLight:ReflectedLight, stack:Stack, builder:Builder):Void {

		var irradiance:Vec3 = getGradientIrradiance(normalGeometry, lightDirection, builder).mul(lightColor);

		reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert({diffuseColor: diffuseColor.rgb})));

	}

	public function indirectDiffuse(irradiance:Vec3, reflectedLight:ReflectedLight):Void {

		reflectedLight.indirectDiffuse.addAssign(irradiance.mul(BRDF_Lambert({diffuseColor: diffuseColor})));

	}

}

typedef Builder = {
	var material:Material;
}

typedef Material = {
	var gradientMap:Texture;
}

typedef Texture = {
	var r:Float;
}

typedef Vec2 = {
	var x:Float;
	var y:Float;
}

typedef Vec3 = {
	var x:Float;
	var y:Float;
	var z:Float;
}

typedef Float = Float;

typedef ReflectedLight = {
	var directDiffuse:Vec3;
	var indirectDiffuse:Vec3;
}

typedef Stack = {
	// Stack type definition
}