package three.materials;

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

    public var fog:Bool = false; // set to use scene fog
    public var lights:Bool = false; // set to use scene lights
    public var clipping:Bool = false; // set to use user-defined clipping planes

    public var forceSinglePass:Bool = true;

    public var extensions:Dynamic = {
        clipCullDistance:false, // set to use vertex shader clipping
        multiDraw:false // set to use vertex shader multi_draw / enable gl_DrawID
    };

    public var defaultAttributeValues:Dynamic = {
        'color': [1, 1, 1],
        'uv': [0, 0],
        'uv1': [0, 0]
    };

    public var index0AttributeName:String = null;
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

        defines = cloneDefines(source.defines);

        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;

        fog = source.fog;
        lights = source.lights;
        clipping = source.clipping;

        extensions = cloneExtensions(source.extensions);

        glslVersion = source.glslVersion;

        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);

        data.glslVersion = glslVersion;
        data.uniforms = {};

        for (uniform in uniforms) {
            var value:Dynamic = uniforms[uniform];

            if (value.isTexture) {
                data.uniforms[uniform] = {
                    type: 't',
                    value: value.toJSON(meta).uuid
                };

            } else if (value.isColor) {
                data.uniforms[uniform] = {
                    type: 'c',
                    value: value.getHex()
                };

            } else if (value.isVector2) {
                data.uniforms[uniform] = {
                    type: 'v2',
                    value: value.toArray()
                };

            } else if (value.isVector3) {
                data.uniforms[uniform] = {
                    type: 'v3',
                    value: value.toArray()
                };

            } else if (value.isVector4) {
                data.uniforms[uniform] = {
                    type: 'v4',
                    value: value.toArray()
                };

            } else if (value.isMatrix3) {
                data.uniforms[uniform] = {
                    type: 'm3',
                    value: value.toArray()
                };

            } else if (value.isMatrix4) {
                data.uniforms[uniform] = {
                    type: 'm4',
                    value: value.toArray()
                };

            } else {
                data.uniforms[uniform] = {
                    value: value
                };
            }
        }

        if (defines != null && reflects(defines).fields().length > 0) data.defines = defines;

        data.vertexShader = vertexShader;
        data.fragmentShader = fragmentShader;

        data.lights = lights;
        data.clipping = clipping;

        var extensions:Dynamic = {};

        for (key in extensions) {
            if (extensions[key] == true) extensions[key] = true;
        }

        if (extensions != null && reflects(extensions).fields().length > 0) data.extensions = extensions;

        return data;
    }
}