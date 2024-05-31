import threejs.materials.Material;
import threejs.renderers.shaders.UniformsUtils;
import threejs.renderers.shaders.ShaderChunk.default_vertex;
import threejs.renderers.shaders.ShaderChunk.default_fragment;

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
    public var extensions:Dynamic = {
        clipCullDistance: false,
        multiDraw: false
    };
    public var defaultAttributeValues:Dynamic = {
        'color': [ 1, 1, 1 ],
        'uv': [ 0, 0 ],
        'uv1': [ 0, 0 ]
    };
    public var index0AttributeName:Null<String> = null;
    public var uniformsNeedUpdate:Bool = false;
    public var glslVersion:Null<Dynamic> = null;

    public function new(parameters:Dynamic = null) {
        super();

        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:ShaderMaterial):ShaderMaterial {
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

    public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);

        data.glslVersion = this.glslVersion;
        data.uniforms = {};

        for (name in Reflect.fields(this.uniforms)) {
            var uniform = Reflect.field(this.uniforms, name);
            var value = uniform.value;

            if (value != null && Reflect.hasField(value, "isTexture")) {
                data.uniforms[name] = {
                    type: 't',
                    value: value.toJSON(meta).uuid
                };
            } else if (value != null && Reflect.hasField(value, "isColor")) {
                data.uniforms[name] = {
                    type: 'c',
                    value: value.getHex()
                };
            } else if (value != null && Reflect.hasField(value, "isVector2")) {
                data.uniforms[name] = {
                    type: 'v2',
                    value: value.toArray()
                };
            } else if (value != null && Reflect.hasField(value, "isVector3")) {
                data.uniforms[name] = {
                    type: 'v3',
                    value: value.toArray()
                };
            } else if (value != null && Reflect.hasField(value, "isVector4")) {
                data.uniforms[name] = {
                    type: 'v4',
                    value: value.toArray()
                };
            } else if (value != null && Reflect.hasField(value, "isMatrix3")) {
                data.uniforms[name] = {
                    type: 'm3',
                    value: value.toArray()
                };
            } else if (value != null && Reflect.hasField(value, "isMatrix4")) {
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

        var extensions = {};

        for (key in Reflect.fields(this.extensions)) {
            if (Reflect.field(this.extensions, key) == true) extensions[key] = true;
        }

        if (Reflect.fields(extensions).length > 0) data.extensions = extensions;

        return data;
    }
}