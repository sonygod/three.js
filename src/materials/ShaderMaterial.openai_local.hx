import three.Material;
import three.renderers.shaders.UniformsUtils;

class ShaderMaterial extends Material {

	public var isShaderMaterial:Bool;
	public var defines:Dynamic;
	public var uniforms:Dynamic;
	public var uniformsGroups:Array<Dynamic>;
	public var vertexShader:String;
	public var fragmentShader:String;
	public var linewidth:Float;
	public var wireframe:Bool;
	public var wireframeLinewidth:Float;
	public var fog:Bool;
	public var lights:Bool;
	public var clipping:Bool;
	public var forceSinglePass:Bool;
	public var extensions:Dynamic;
	public var defaultAttributeValues:Dynamic;
	public var index0AttributeName:String;
	public var uniformsNeedUpdate:Bool;
	public var glslVersion:String;

	public function new(parameters:Dynamic = null) {
		super();
		this.isShaderMaterial = true;
		this.type = "ShaderMaterial";
		this.defines = {};
		this.uniforms = {};
		this.uniformsGroups = [];
		this.vertexShader = default_vertex;
		this.fragmentShader = default_fragment;
		this.linewidth = 1;
		this.wireframe = false;
		this.wireframeLinewidth = 1;
		this.fog = false;
		this.lights = false;
		this.clipping = false;
		this.forceSinglePass = true;
		this.extensions = {
			clipCullDistance: false,
			multiDraw: false
		};
		this.defaultAttributeValues = {
			color: [1, 1, 1],
			uv: [0, 0],
			uv1: [0, 0]
		};
		this.index0AttributeName = null;
		this.uniformsNeedUpdate = false;
		this.glslVersion = null;

		if (parameters != null) {
			this.setValues(parameters);
		}
	}

	override public function copy(source:ShaderMaterial):ShaderMaterial {
		super.copy(source);
		this.fragmentShader = source.fragmentShader;
		this.vertexShader = source.vertexShader;
		this.uniforms = UniformsUtils.cloneUniforms(source.uniforms);
		this.uniformsGroups = UniformsUtils.cloneUniformsGroups(source.uniformsGroups);
		this.defines = Reflect.copy(source.defines);
		this.wireframe = source.wireframe;
		this.wireframeLinewidth = source.wireframeLinewidth;
		this.fog = source.fog;
		this.lights = source.lights;
		this.clipping = source.clipping;
		this.extensions = Reflect.copy(source.extensions);
		this.glslVersion = source.glslVersion;

		return this;
	}

	override public function toJSON(meta:Dynamic):Dynamic {
		var data = super.toJSON(meta);
		data.glslVersion = this.glslVersion;
		data.uniforms = {};

		for (name in this.uniforms) {
			var uniform = this.uniforms[name];
			var value = uniform.value;

			if (value != null && Reflect.hasField(value, "isTexture") && value.isTexture) {
				data.uniforms[name] = {
					type: 't',
					value: value.toJSON(meta).uuid
				};
			} else if (value != null && Reflect.hasField(value, "isColor") && value.isColor) {
				data.uniforms[name] = {
					type: 'c',
					value: value.getHex()
				};
			} else if (value != null && Reflect.hasField(value, "isVector2") && value.isVector2) {
				data.uniforms[name] = {
					type: 'v2',
					value: value.toArray()
				};
			} else if (value != null && Reflect.hasField(value, "isVector3") && value.isVector3) {
				data.uniforms[name] = {
					type: 'v3',
					value: value.toArray()
				};
			} else if (value != null && Reflect.hasField(value, "isVector4") && value.isVector4) {
				data.uniforms[name] = {
					type: 'v4',
					value: value.toArray()
				};
			} else if (value != null && Reflect.hasField(value, "isMatrix3") && value.isMatrix3) {
				data.uniforms[name] = {
					type: 'm3',
					value: value.toArray()
				};
			} else if (value != null && Reflect.hasField(value, "isMatrix4") && value.isMatrix4) {
				data.uniforms[name] = {
					type: 'm4',
					value: value.toArray()
				};
			} else {
				data.uniforms[name] = {
					value: value
				};
				// Note: the array variants v2v, v3v, v4v, m4v and tv are not supported so far
			}
		}

		if (Reflect.fields(this.defines).length > 0) {
			data.defines = this.defines;
		}

		data.vertexShader = this.vertexShader;
		data.fragmentShader = this.fragmentShader;
		data.lights = this.lights;
		data.clipping = this.clipping;

		var extensions = {};
		for (key in this.extensions) {
			if (this.extensions[key] == true) {
				extensions[key] = true;
			}
		}

		if (Reflect.fields(extensions).length > 0) {
			data.extensions = extensions;
		}

		return data;
	}
}