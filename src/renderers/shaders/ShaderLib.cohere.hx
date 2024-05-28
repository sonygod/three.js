import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class ShaderLib {
	public static function get basic():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.specularmap, UniformsLib.envmap, UniformsLib.aomap, UniformsLib.lightmap, UniformsLib.fog]), ShaderChunk.meshbasic_vert, ShaderChunk.meshbasic_frag);
	}

	public static function get lambert():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.specularmap, UniformsLib.envmap, UniformsLib.aomap, UniformsLib.lightmap, UniformsLib.emissivemap, UniformsLib.bumpmap, UniformsLib.normalmap, UniformsLib.displacementmap, UniformsLib.fog, UniformsLib.lights, { emissive: new ShaderInput(new openfl.display.Color(0x000000)) }]), ShaderChunk.meshlambert_vert, ShaderChunk.meshlambert_frag);
	}

	public static function get phong():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.specularmap, UniformsLib.envmap, UniformsLib.aomap, UniformsLib.lightmap, UniformsLib.emissivemap, UniformsLib.bumpmap, UniformsLib.normalmap, UniformsLib.displacementmap, UniformsLib.fog, UniformsLib.lights, { emissive: new ShaderInput(new openfl.display.Color(0x000000)), specular: new ShaderInput(new openfl.display.Color(0x111111)), shininess: new ShaderInput(30) }]), ShaderChunk.meshphong_vert, ShaderChunk.meshphong_frag);
	}

	public static function get standard():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.envmap, UniformsLib.aomap, UniformsLib.lightmap, UniformsLib.emissivemap, UniformsLib.bumpmap, UniformsLib.normalmap, UniformsLib.displacementmap, UniformsLib.roughnessmap, UniformsLib.metalnessmap, UniformsLib.fog, UniformsLib.lights, { emissive: new ShaderInput(new openfl.display.Color(0x000000)), roughness: new ShaderInput(1.0), metalness: new ShaderInput(0.0), envMapIntensity: new ShaderInput(1) }]), ShaderChunk.meshphysical_vert, ShaderChunk.meshphysical_frag);
	}

	public static function get toon():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.aomap, UniformsLib.lightmap, UniformsLib.emissivemap, UniformsLib.bumpmap, UniformsLib.normalmap, UniformsLib.displacementmap, UniformsLib.gradientmap, UniformsLib.fog, UniformsLib.lights, { emissive: new ShaderInput(new openfl.display.Color(0x000000)) }]), ShaderChunk.meshtoon_vert, ShaderChunk.meshtoon_frag);
	}

	public static function get matcap():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.bumpmap, UniformsLib.normalmap, UniformsLib.displacementmap, UniformsLib.fog, { matcap: new ShaderInput(null) }]), ShaderChunk.meshmatcap_vert, ShaderChunk.meshmatcap_frag);
	}

	public static function get points():Shader {
		return new Shader(mergeUniforms([UniformsLib.points, UniformsLib.fog]), ShaderChunk.points_vert, ShaderChunk.points_frag);
	}

	public static function get dashed():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.fog, { scale: new ShaderInput(1), dashSize: new ShaderInput(1), totalSize: new ShaderInput(2) }]), ShaderChunk.linedashed_vert, ShaderChunk.linedashed_frag);
	}

	public static function get depth():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.displacementmap]), ShaderChunk.depth_vert, ShaderChunk.depth_frag);
	}

	public static function get normal():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.bumpmap, UniformsLib.normalmap, UniformsLib.displacementmap, { opacity: new ShaderInput(1.0) }]), ShaderChunk.meshnormal_vert, ShaderChunk.meshnormal_frag);
	}

	public static function get sprite():Shader {
		return new Shader(mergeUniforms([UniformsLib.sprite, UniformsLib.fog]), ShaderChunk.sprite_vert, ShaderChunk.sprite_frag);
	}

	public static function get background():Shader {
		return new Shader({ uvTransform: new ShaderInput(new Matrix3D()), t2D: new ShaderInput(null), backgroundIntensity: new ShaderInput(1) }, ShaderChunk.background_vert, ShaderChunk.background_frag);
	}

	public static function get backgroundCube():Shader {
		return new Shader({ envMap: new ShaderInput(null), flipEnvMap: new ShaderInput(-1), backgroundBlurriness: new ShaderInput(0), backgroundIntensity: new ShaderInput(1), backgroundRotation: new ShaderInput(new Matrix3D()) }, ShaderChunk.backgroundCube_vert, ShaderChunk.backgroundCube_frag);
	}

	public static function get cube():Shader {
		return new Shader({ tCube: new ShaderInput(null), tFlip: new ShaderInput(-1), opacity: new ShaderInput(1.0) }, ShaderChunk.cube_vert, ShaderChunk.cube_frag);
	}

	public static function get equirect():Shader {
		return new Shader({ tEquirect: new ShaderInput(null) }, ShaderChunk.equirect_vert, ShaderChunk.equirect_frag);
	}

	public static function get distanceRGBA():Shader {
		return new Shader(mergeUniforms([UniformsLib.common, UniformsLib.displacementmap, { referencePosition: new ShaderInput(new Vector3D()), nearDistance: new ShaderInput(1), farDistance: new ShaderInput(1000) }]), ShaderChunk.distanceRGBA_vert, ShaderChunk.distanceRGBA_frag);
	}

	public static function get shadow():Shader {
		return new Shader(mergeUniforms([UniformsLib.lights, UniformsLib.fog, { color: new ShaderInput(new openfl.display.Color(0x000000)), opacity: new ShaderInput(1.0) }]), ShaderChunk.shadow_vert, ShaderChunk.shadow_frag);
	}

	public static function get physical():Shader {
		return new Shader(mergeUniforms([ShaderLib.standard.uniforms, { clearcoat: new ShaderInput(0), clearcoatMap: new ShaderInput(null), clearcoatMapTransform: new ShaderInput(new Matrix3D()), clearcoatNormalMap: new ShaderInput(null), clearcoatNormalMapTransform: new ShaderInput(new Matrix3D()), clearcoatNormalScale: new ShaderInput(new Vector3D(1, 1, 1)), clearcoatRoughness: new ShaderInput(0), clearcoatRoughnessMap: new ShaderInput(null), clearcoatRoughnessMapTransform: new ShaderInput(new Matrix3D()), dispersion: new ShaderInput(0), iridescence: new ShaderInput(0), iridescenceMap: new ShaderInput(null), iridescenceMapTransform: new ShaderInput(new Matrix3D()), iridescenceIOR: new ShaderInput(1.3), iridescenceThicknessMinimum: new ShaderInput(100), iridescenceThicknessMaximum: new ShaderInput(400), iridescenceThicknessMap: new ShaderInput(null), iridescenceThicknessMapTransform: new ShaderInput(new Matrix3D()), sheen: new ShaderInput(0), sheenColor: new ShaderInput(new openfl.display.Color(0x000000)), sheenColorMap: new ShaderInput(null), sheenColorMapTransform: new ShaderInput(new Matrix3D()), sheenRoughness: new ShaderInput(1), sheenRoughnessMap: new ShaderInput(null), sheenRoughnessMapTransform: new ShaderInput(new Matrix3D()), transmission: new ShaderInput(0), transmissionMap: new ShaderInput(null), transmissionMapTransform: new ShaderInput(new Matrix3D()), transmissionSamplerSize: new ShaderInput(new Vector3D()), transmissionSamplerMap: new ShaderInput(null), thickness: new ShaderInput(0), thicknessMap: new ShaderInput(null), thicknessMapTransform: new ShaderInput(new Matrix3D()), attenuationDistance: new ShaderInput(0), attenuationColor: new ShaderInput(new openfl.display.Color(0x000000)), specularColor: new ShaderInput(new openfl.display.Color(1, 1, 1)), specularColorMap: new ShaderInput(null), specularColorMapTransform: new ShaderInput(new Matrix3D()), specularIntensity: new ShaderInput(1), specularIntensityMap: new ShaderInput(null), specularIntensityMapTransform: new ShaderInput(new Matrix3D()), anisotropyVector: new ShaderInput(new Vector3D()), anisotropyMap: new ShaderInput(null), anisotropyMapTransform: new ShaderInput(new Matrix3D()) }]), ShaderChunk.meshphysical_vert, ShaderChunk.meshphysical_frag);
	}
}

function mergeUniforms(uniforms:Array<Dynamic>):Dynamic {
	var result:Dynamic = {};
	for (u in uniforms) {
		var u1:Dynamic = uniforms[u];
		for (var name:String in u1) {
			result[name] = u1[name];
		}
	}
	return result;
}

class ShaderChunk {
	public static var meshbasic_vert:String = "...";
	public static var meshbasic_frag:String = "...";
	public static var meshlambert_vert:String = "...";
	public static var meshlambert_frag:String = "...";
	public static var meshphong_vert:String = "...";
	public static var meshphong_frag:String = "...";
	public static var meshphysical_vert:String = "...";
	public static var meshphysical_frag:String = "...";
	public static var meshtoon_vert:String = "...";
	public static var meshtoon_frag:String = "...";
	public static var meshmatcap_vert:String = "...";
	public static var meshmatcap_frag:String = "...";
	public static var points_vert:String = "...";
	public static var points_frag:String = "...";
	public static var linedashed_vert:String = "...";
	public static var linedashed_frag:String = "...";
	public static var depth_vert:String = "...";
	public static var depth_frag:String = "...";
	public static var meshnormal_vert:String = "...";
	public static var meshnormal_frag:String = "...";
	public static var sprite_vert:String = "...";
	public static var sprite_frag:String = "...";
	public static var background_vert:String = "...";
	public static var background_frag:String = "...";
	public static var backgroundCube_vert:String = "...";
	public static var backgroundCube_frag:String = "...";
	public static var cube_vert:String = "...";
	public static var cube_frag:String = "...";
	public static var equirect_vert:String = "...";
	public static var equirect_frag:String = "...";
	public static var distanceRGBA_vert:String = "...";
	public static var distanceRGBA_frag:String = "...";
	public static var shadow_vert:String = "...";
	public static var shadow_frag:String = "...";
}

class UniformsLib {
	public static var common:Dynamic = {
		diffuse: new ShaderInput(new openfl.display.Color(0xeeeeee)),
		map: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		lightMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		specularMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		envMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		flipEnvMap: new ShaderInput(-1),
		useRefract: new ShaderInput(0),
		reflectivity: new ShaderInput(1),
		refractionRatio: new ShaderInput(0.98),
		combine: new ShaderInput(1),
		morphTargetInfluences: new ShaderInput([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
		morphTargetBaseInfluence: new ShaderInput(0)
	};

	public static var specularmap:Dynamic = {
		specular: new ShaderInput(new openfl.display.Color(0x111111)),
		shininess: new ShaderInput(30)
	};

	public static var envmap:Dynamic = {
		envMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		flipEnvMap: new ShaderInput(-1),
		useRefract: new ShaderInput(0),
		reflectivity: new ShaderInput(1),
		refractionRatio: new ShaderInput(0.98),
		combine: new ShaderInput(1)
	};

	public static var aomap:Dynamic = {
		aoMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		aoMapIntensity: new ShaderInput(1)
	};

	public static var lightmap:Dynamic = {
		lightMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		lightMapIntensity: new ShaderInput(1)
	};

	public static var emissivemap:Dynamic = {
		emissive: new ShaderInput(new openfl.display.Color(0x000000)),
		emissiveIntensity: new ShaderInput(1),
		emissiveMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true)
	};

	public static var bumpmap:Dynamic = {
		bumpMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		bumpScale: new ShaderInput(1)
	};

	public static var normalmap:Dynamic = {
		normalMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		normalScale: new ShaderInput(new Vector3D(1, 1, 1)),
		normalMapType: new ShaderInput(2)
	};

	public static var displacementmap:Dynamic = {
		displacementMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		displacementScale: new ShaderInput(1),
		displacementBias: new ShaderInput(0)
	};

	public static var gradientmap:Dynamic = {
		gradientMap: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true)
	};

	public static var fog:Dynamic = {
		fogDensity: new ShaderInput(0.00025),
		fogNear: new ShaderInput(1),
		fogFar: new ShaderInput(2000),
		fogColor: new ShaderInput(new openfl.display.Color(0x000000)),
		fogType: new ShaderInput(0)
	};

	public static var points:Dynamic = {
		diffuse: new ShaderInput(new openfl.display.Color(0xeeeeee)),
		size: new ShaderInput(1),
		scale: new ShaderInput(1),
		map: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true)
	};

	public static var sprite:Dynamic = {
		color: new ShaderInput(new openfl.display.Color(0xffffff)),
		map: new ShaderInput(null, Context3DTextureFormat.BGRA, true, true),
		uvTransform: new ShaderInput(new Matrix3D())
	};

	public static var lights:Dynamic = {
		ambientLightColor: new ShaderInput(new openfl.display.Color(0x222222)),
		directionalLightDirection: new ShaderInput(new Vector3D(0, 0, 1)),
		directionalLightColor: new ShaderInput
		(new openfl.display.Color(0xffffff)),
		directionalLightShadow: new ShaderInput(null),
		directionalLightShadowDarkness: new ShaderInput(0.5),
		pointLightColor: new ShaderInput([new openfl.display.Color(0xffffff), new openfl.display.Color(0xffffff), new openfl.display.Color(0xffffff), new openfl.display.Color(0xffffff)]),
		pointLightPosition: new ShaderInput([new Vector3D(0, 0, 0), new Vector3D(0, 0, 0), new Vector3D(0, 0, 0), new Vector3D(0, 0, 0)]),
		pointLightDistance: new ShaderInput([1, 1, 1, 1]),
		pointLightDecay: new ShaderInput([0, 0, 0, 0]),
		pointLightShadow: new ShaderInput([null, null, null, null]),
		pointLightShadowDarkness: new ShaderInput([0, 0, 0, 0]),
		spotLightColor: new ShaderInput([new openfl.display.Color(0xffffff), new openfl.display.Color(0xffffff), new openfl.display.Color(0xffffff), new openfl.display.Color(0xffffff)]),
		spotLightPosition: new ShaderInput([new Vector3D(0, 0, 0), new Vector3D(0, 0, 0), new Vector3D(0, 0, 0), new Vector3D(0, 0, 0)]),
		spotLightDirection: new ShaderInput([new Vector3D(0, 0, 1), new Vector3D(0, 0, 1), new Vector3D(0, 0, 1), new Vector3D(0, 0, 1)]),
		spotLightDistance: new ShaderInput([1, 1, 1, 1]),
		spotLightAngle: new ShaderInput([0.1, 0.1, 0.1, 0.1]),
		spotLightExponent: new ShaderInput([10, 10, 10, 10]),
		spotLightShadow: new ShaderInput([null, null, null, null]),
		spotLightShadowDarkness: new ShaderInput([0.5, 0.5, 0.5, 0.5]),
		hemisphereLightSkyColor: new ShaderInput(new openfl.display.Color(0x00aadd)),
		hemisphereLightGroundColor: new ShaderInput(new openfl.display.Color(0xff7f00)),
		hemisphereLightDirection: new ShaderInput(new Vector3D(0, 1, 0)),
		rectAreaLightColor: new ShaderInput(new openfl.display.Color(0xffffff)),
		rectAreaLightPosition: new ShaderInput(new Vector3D(0, 0, 0)),
		rectAreaLightHalfWidth: new ShaderInput(new Vector3D(0, 0, 0)),
		rectAreaLightHalfHeight: new ShaderInput(new Vector3D(0, 0, 0)),
		rectAreaLightShadow: new ShaderInput(null),
		rectAreaLightShadowDarkness: new ShaderInput(0.5)
	};
}