import Material from './Material.hx';
import {cloneUniforms, cloneUniformsGroups} from '../renderers/shaders/UniformsUtils.hx';

import default_vertex from '../renderers/shaders/ShaderChunk/default_vertex.glsl.hx';
import default_fragment from '../renderers/shaders/ShaderChunk/default_fragment.glsl.hx';

class ShaderMaterial extends Material {

	public function new(parameters:Dynamic) {

		super();

		this.isShaderMaterial = true;

		this.type = 'ShaderMaterial';

		this.defines = {};
		this.uniforms = {};
		this.uniformsGroups = [];

		this.vertexShader = default_vertex;
		this.fragmentShader = default_fragment;

		this.linewidth = 1;

		this.wireframe = false;
		this.wireframeLinewidth = 1;

		this.fog = false; // set to use scene fog
		this.lights = false; // set to use scene lights
		this.clipping = false; // set to use user-defined clipping planes

		this.forceSinglePass = true;

		this.extensions = {
			clipCullDistance: false, // set to use vertex shader clipping
			multiDraw: false // set to use vertex shader multi_draw / enable gl_DrawID
		};

		// When rendered geometry doesn't include these attributes but the material does,
		// use these default values in WebGL. This avoids errors when buffer data is missing.
		this.defaultAttributeValues = {
			'color': [ 1, 1, 1 ],
			'uv': [ 0, 0 ],
			'uv1': [ 0, 0 ]
		};

		this.index0AttributeName = null;
		this.uniformsNeedUpdate = false;

		this.glslVersion = null;

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

		this.defines = Std.clone(source.defines);

		this.wireframe = source.wireframe;
		this.wireframeLinewidth = source.wireframeLinewidth;

		this.fog = source.fog;
		this.lights = source.lights;
		this.clipping = source.clipping;

		this.extensions = Std.clone(source.extensions);

		this.glslVersion = source.glslVersion;

		return this;

	}

	public function toJSON(meta:Dynamic):Dynamic {

		var data = super.toJSON(meta);

		data.glslVersion = this.glslVersion;
		data.uniforms = {};

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

		if (Std.count(this.defines) > 0) data.defines = this.defines;

		data.vertexShader = this.vertexShader;
		data.fragmentShader = this.fragmentShader;

		data.lights = this.lights;
		data.clipping = this.clipping;

		var extensions = {};

		for (key in this.extensions) {

			if (this.extensions[key] == true) extensions[key] = true;

		}

		if (Std.count(extensions) > 0) data.extensions = extensions;

		return data;

	}

}