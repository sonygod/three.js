package materials;

import three.materials.Material;

class ShaderMaterial extends Material {
    public var isShaderMaterial:Bool = true;
    public var type:String = 'ShaderMaterial';
    public var defines:Dynamic = {};
    public var uniforms:Dynamic = {};
    public var uniformsGroups:Array<Dynamic> = [];
    public var vertexShader:String = default_vertex;
    public var fragmentShader:String = default_fragment;
    public var linewidth:Float = 1;
    public var wireframe:Bool = false;
    public var wireframeLinewidth:Float = 1;
    public var fog:Bool = false;
    public var lights:Bool = false;
    public var clipping:Bool = false;
    public var forceSinglePass:Bool = true;
    public var extensions:Dynamic = { clipCullDistance: false, multiDraw: false };
    public var defaultAttributeValues:Dynamic = { color: [1, 1, 1], uv: [0, 0], uv1: [0, 0] };
    public var index0AttributeName:String;
    public var uniformsNeedUpdate:Bool = false;
    public var glslVersion:Null<String>;

    public function new(parameters:Dynamic = null) {
        super();
        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:ShaderMaterial):ShaderMaterial {
        super.copy(source);
        vertexShader = source.vertexShader;
        fragmentShader = source.fragmentShader;
        uniforms = cloneUniforms(source.uniforms);
        uniformsGroups = cloneUniformsGroups(source.uniformsGroups);
        defines = Reflect.copy(source.defines);
        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;
        fog = source.fog;
        lights = source.lights;
        clipping = source.clipping;
        extensions = Reflect.copy(source.extensions);
        glslVersion = source.glslVersion;
        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);
        data.glslVersion = glslVersion;
        data.uniforms = {};
        for (name in uniforms.keys()) {
            var uniform:Dynamic = uniforms[name];
            var value:Dynamic = uniform.value;
            if (value.isTexture) {
                data.uniforms[name] = { type: 't', value: value.toJSON(meta).uuid };
            } else if (value.isColor) {
                data.uniforms[name] = { type: 'c', value: value.getHex() };
            } else if (value.isVector2) {
                data.uniforms[name] = { type: 'v2', value: value.toArray() };
            } else if (value.isVector3) {
                data.uniforms[name] = { type: 'v3', value: value.toArray() };
            } else if (value.isVector4) {
                data.uniforms[name] = { type: 'v4', value: value.toArray() };
            } else if (value.isMatrix3) {
                data.uniforms[name] = { type: 'm3', value: value.toArray() };
            } else if (value.isMatrix4) {
                data.uniforms[name] = { type: 'm4', value: value.toArray() };
            } else {
                data.uniforms[name] = { value: value };
            }
        }
        if (Reflect.fields(defines).length > 0) data.defines = defines;
        data.vertexShader = vertexShader;
        data.fragmentShader = fragmentShader;
        data.lights = lights;
        data.clipping = clipping;
        var extensions:Dynamic = {};
        for (key in extensions.keys()) {
            if (extensions[key] == true) extensions[key] = true;
        }
        if (Reflect.fields(extensions).length > 0) data.extensions = extensions;
        return data;
    }
}