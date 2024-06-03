import three.materials.Material;
import three.renderers.shaders.UniformsUtils;

import three.renderers.shaders.ShaderChunk.default_vertex;
import three.renderers.shaders.ShaderChunk.default_fragment;

class ShaderMaterial extends Material {

    public var defines:haxe.ds.StringMap<Dynamic>;
    public var uniforms:haxe.ds.StringMap<Dynamic>;
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

    public var extensions:haxe.ds.StringMap<Bool>;

    public var defaultAttributeValues:haxe.ds.StringMap<Array<Dynamic>>;

    public var index0AttributeName:String;
    public var uniformsNeedUpdate:Bool;

    public var glslVersion:String;

    public function new(parameters:Dynamic = null) {
        super();

        isShaderMaterial = true;

        type = "ShaderMaterial";

        defines = new haxe.ds.StringMap();
        uniforms = new haxe.ds.StringMap();
        uniformsGroups = new Array<Dynamic>();

        vertexShader = default_vertex;
        fragmentShader = default_fragment;

        linewidth = 1;

        wireframe = false;
        wireframeLinewidth = 1;

        fog = false;
        lights = false;
        clipping = false;

        forceSinglePass = true;

        extensions = new haxe.ds.StringMap();
        extensions.set("clipCullDistance", false);
        extensions.set("multiDraw", false);

        defaultAttributeValues = new haxe.ds.StringMap();
        defaultAttributeValues.set("color", [1, 1, 1]);
        defaultAttributeValues.set("uv", [0, 0]);
        defaultAttributeValues.set("uv1", [0, 0]);

        index0AttributeName = null;
        uniformsNeedUpdate = false;

        glslVersion = null;

        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:ShaderMaterial):ShaderMaterial {
        super.copy(source);

        fragmentShader = source.fragmentShader;
        vertexShader = source.vertexShader;

        uniforms = UniformsUtils.cloneUniforms(source.uniforms);
        uniformsGroups = UniformsUtils.cloneUniformsGroups(source.uniformsGroups);

        defines = source.defines.copy();

        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;

        fog = source.fog;
        lights = source.lights;
        clipping = source.clipping;

        extensions = source.extensions.copy();

        glslVersion = source.glslVersion;

        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);

        data.glslVersion = glslVersion;
        data.uniforms = new haxe.ds.StringMap();

        for (uniform in uniforms.keys()) {
            var value = uniforms.get(uniform).value;

            if (value != null) {
                if (Std.is(value, three.textures.Texture)) {
                    data.uniforms.set(uniform, {
                        type: "t",
                        value: value.toJSON(meta).uuid
                    });
                } else if (Std.is(value, three.math.Color)) {
                    data.uniforms.set(uniform, {
                        type: "c",
                        value: value.getHex()
                    });
                } else if (Std.is(value, three.math.Vector2)) {
                    data.uniforms.set(uniform, {
                        type: "v2",
                        value: value.toArray()
                    });
                } else if (Std.is(value, three.math.Vector3)) {
                    data.uniforms.set(uniform, {
                        type: "v3",
                        value: value.toArray()
                    });
                } else if (Std.is(value, three.math.Vector4)) {
                    data.uniforms.set(uniform, {
                        type: "v4",
                        value: value.toArray()
                    });
                } else if (Std.is(value, three.math.Matrix3)) {
                    data.uniforms.set(uniform, {
                        type: "m3",
                        value: value.toArray()
                    });
                } else if (Std.is(value, three.math.Matrix4)) {
                    data.uniforms.set(uniform, {
                        type: "m4",
                        value: value.toArray()
                    });
                } else {
                    data.uniforms.set(uniform, {
                        value: value
                    });
                }
            }
        }

        if (defines.keys().length > 0) data.defines = defines;

        data.vertexShader = vertexShader;
        data.fragmentShader = fragmentShader;

        data.lights = lights;
        data.clipping = clipping;

        var extensions = new haxe.ds.StringMap();

        for (key in this.extensions.keys()) {
            if (this.extensions.get(key) == true) extensions.set(key, true);
        }

        if (extensions.keys().length > 0) data.extensions = extensions;

        return data;
    }
}