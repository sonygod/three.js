import Material.Material;
import UniformsUtils.cloneUniforms;
import UniformsUtils.cloneUniformsGroups;

import default_vertex from '../renderers/shaders/ShaderChunk/default_vertex.glsl.js';
import default_fragment from '../renderers/shaders/ShaderChunk/default_fragment.glsl.js';

class ShaderMaterial extends Material {

	public var isShaderMaterial:Bool = true;
	public var type:String = 'ShaderMaterial';

	public var defines:Dynamic = new Dynamic();
	public var uniforms:Dynamic = new Dynamic();
	public var uniformsGroups:Array<Dynamic> = new Array<Dynamic>();

	public var vertexShader:String = default_vertex;
	public var fragmentShader:String = default_fragment;

	public var linewidth:Float = 1;

	public var wireframe:Bool = false;
	public var wireframeLinewidth:Float = 1;

	public var fog:Bool = false;
	public var lights:Bool = false;
	public var clipping:Bool = false;

	public var forceSinglePass:Bool = true;

	public var extensions:Dynamic = new Dynamic();

	public var defaultAttributeValues:Dynamic = new Dynamic();

	public var index0AttributeName:String = undefined;
	public var uniformsNeedUpdate:Bool = false;

	public var glslVersion:String = null;

	public function new(parameters:Dynamic) {

		super();

		if (parameters != null) {

			this.setValues(parameters);

		}

	}

	public function copy(source:ShaderMaterial):ShaderMaterial {

		super.copy(source);

		this.fragmentShader = source.fragmentShader;
		this.vertexShader = source.vertexShader;

		this.uniforms = cloneUniforms(source.uniforms);
		this.uniformsGroups = cloneUniformsGroups(source.uniformsGroups);

		this.defines = source.defines.copy();

		this.wireframe = source.wireframe;
		this.wireframeLinewidth = source.wireframeLinewidth;

		this.fog = source.fog;
		this.lights = source.lights;
		this.clipping = source.clipping;

		this.extensions = source.extensions.copy();

		this.glslVersion = source.glslVersion;

		return this;

	}

	public function toJSON(meta:Dynamic):Dynamic {

		var data = super.toJSON(meta);

		data.glslVersion = this.glslVersion;
		data.uniforms = new Dynamic();

		for (name in this.uniforms) {

			var uniform = this.uniforms[name];
			var value = uniform.value;

			if (value != null && value.isTexture) {

				data.uniforms[name] = {
					type: 't',
					value: value.toJSON(meta).uuid
				};

			} else if (value != null && value.isColor) {

				data.uniforms[name] = {
					type: 'c',
					value: value.getHex()
				};

			} else if (value != null && value.isVector2) {

				data.uniforms[name] = {
					type: 'v2',
					value: value.toArray()
				};

			} else if (value != null && value.isVector3) {

				data.uniforms[name] = {
					type: 'v3',
					value: value.toArray()
				};

			} else if (value != null && value.isVector4) {

				data.uniforms[name] = {
					type: 'v4',
					value: value.toArray()
				};

			} else if (value != null && value.isMatrix3) {

				data.uniforms[name] = {
					type: 'm3',
					value: value.toArray()
				};

			} else if (value != null && value.isMatrix4) {

				data.uniforms[name] = {
					type: 'm4',
					value: value.toArray()
				};

			} else {

				data.uniforms[name] = {
					value: value
				};

				// note: the array variants v2v, v3v, v4v, m4v and tv are not supported so far

			}

		}

		if (Reflect.fields(this.defines).length > 0) data.defines = this.defines;

		data.vertexShader = this.vertexShader;
		data.fragmentShader = this.fragmentShader;

		data.lights = this.lights;
		data.clipping = this.clipping;

		var extensions = new Dynamic();

		for (key in this.extensions) {

			if (this.extensions[key] == true) extensions[key] = true;

		}

		if (Reflect.fields(extensions).length > 0) data.extensions = extensions;

		return data;

	}

}

export ShaderMaterial;