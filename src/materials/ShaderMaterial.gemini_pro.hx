import Material from "./Material";
import UniformsUtils from "../renderers/shaders/UniformsUtils";
import DefaultVertex from "../renderers/shaders/ShaderChunk/default_vertex.glsl";
import DefaultFragment from "../renderers/shaders/ShaderChunk/default_fragment.glsl";

class ShaderMaterial extends Material {
  public isShaderMaterial: Bool;
  public type: String;
  public defines: Dynamic<String>;
  public uniforms: Dynamic<Dynamic>;
  public uniformsGroups: Array<Dynamic>;
  public vertexShader: String;
  public fragmentShader: String;
  public linewidth: Float;
  public wireframe: Bool;
  public wireframeLinewidth: Float;
  public fog: Bool;
  public lights: Bool;
  public clipping: Bool;
  public forceSinglePass: Bool;
  public extensions: Dynamic<Bool>;
  public defaultAttributeValues: Dynamic<Array<Float>>;
  public index0AttributeName: String;
  public uniformsNeedUpdate: Bool;
  public glslVersion: String;

  public function new(parameters: Dynamic = null) {
    super();
    this.isShaderMaterial = true;
    this.type = 'ShaderMaterial';
    this.defines = {};
    this.uniforms = {};
    this.uniformsGroups = [];
    this.vertexShader = DefaultVertex;
    this.fragmentShader = DefaultFragment;
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
      'color': [1, 1, 1],
      'uv': [0, 0],
      'uv1': [0, 0]
    };
    this.index0AttributeName = null;
    this.uniformsNeedUpdate = false;
    this.glslVersion = null;
    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  public function copy(source: ShaderMaterial): ShaderMaterial {
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

  public function toJSON(meta: Dynamic): Dynamic {
    var data = super.toJSON(meta);
    data.glslVersion = this.glslVersion;
    data.uniforms = {};
    for (name in this.uniforms) {
      var uniform = this.uniforms[name];
      var value = uniform.value;
      if (value.isTexture) {
        data.uniforms[name] = {
          type: 't',
          value: value.toJSON(meta).uuid
        };
      } else if (value.isColor) {
        data.uniforms[name] = {
          type: 'c',
          value: value.getHex()
        };
      } else if (value.isVector2) {
        data.uniforms[name] = {
          type: 'v2',
          value: value.toArray()
        };
      } else if (value.isVector3) {
        data.uniforms[name] = {
          type: 'v3',
          value: value.toArray()
        };
      } else if (value.isVector4) {
        data.uniforms[name] = {
          type: 'v4',
          value: value.toArray()
        };
      } else if (value.isMatrix3) {
        data.uniforms[name] = {
          type: 'm3',
          value: value.toArray()
        };
      } else if (value.isMatrix4) {
        data.uniforms[name] = {
          type: 'm4',
          value: value.toArray()
        };
      } else {
        data.uniforms[name] = {
          value: value
        };
      }
    }
    if (Reflect.fields(this.defines).length > 0) data.defines = this.defines;
    data.vertexShader = this.vertexShader;
    data.fragmentShader = this.fragmentShader;
    data.lights = this.lights;
    data.clipping = this.clipping;
    var extensions = {};
    for (key in this.extensions) {
      if (this.extensions[key]) extensions[key] = true;
    }
    if (Reflect.fields(extensions).length > 0) data.extensions = extensions;
    return data;
  }
}

export default ShaderMaterial;