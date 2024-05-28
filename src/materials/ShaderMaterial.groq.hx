package three.js.src.materials;

import three.js.src.Material;

import three.js.renderers.shaders.UniformsUtils;

@:nativeGen
class ShaderMaterial extends Material {
    public var isShaderMaterial:Bool = true;

    public var type:String = 'ShaderMaterial';

    public var defines:Dynamic = {};
    public var uniforms:Dynamic = {};
    public var uniformsGroups:Array<Dynamic> = [];

    public var vertexShader:String = default_vertex;
    public var fragmentShader:String = default_fragment;

    public var linewidth:Int = 1;

    public var wireframe:Bool = false;
    public var wireframeLinewidth:Int = 1;

    public var fog:Bool = false; // set to use scene fog
    public var lights:Bool = false; // set to use scene lights
    public var clipping:Bool = false; // set to use user-defined clipping planes

    public var forceSinglePass:Bool = true;

    public var extensions:Dynamic = {
        clipCullDistance: false, // set to use vertex shader clipping
        multiDraw: false // set to use vertex shader multi_draw / enable gl_DrawID
    };

    // When rendered geometry doesn't include these attributes but the material does,
    // use these default values in WebGL. This avoids errors when buffer data is missing.
    public var defaultAttributeValues:Dynamic = {
        'color': [1, 1, 1],
        'uv': [0, 0],
        'uv1': [0, 0]
    };

    public var index0AttributeName:String = null;
    public var uniformsNeedUpdate:Bool = false;

    public var glslVersion:Null<String> = null;

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

        defines = Object.assign({}, source.defines);

        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;

        fog = source.fog;
        lights = source.lights;
        clipping = source.clipping;

        extensions = Object.assign({}, source.extensions);

        glslVersion = source.glslVersion;

        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);

        data.glslVersion = glslVersion;
        data.uniforms = {};

        for (var name in uniforms) {
            var uniform:Dynamic = uniforms[name];
            var value:Dynamic = uniform.value;

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
            }
        }

        if (Object.keys(defines).length > 0) data.defines = defines;

        data.vertexShader = vertexShader;
        data.fragmentShader = fragmentShader;

        data.lights = lights;
        data.clipping = clipping;

        var extensions:Dynamic = {};

        for (var key in extensions) {
            if (extensions[key] == true) extensions[key] = true;
        }

        if (Object.keys(extensions).length > 0) data.extensions = extensions;

        return data;
    }
}