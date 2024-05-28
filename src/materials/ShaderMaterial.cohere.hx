import Material from "./Material";
import { cloneUniforms, cloneUniformsGroups } from "../renderers/shaders/UniformsUtils";

import default_vertex from "../renderers/shaders/ShaderChunk/default_vertex.glsl";
import default_fragment from "../renderers/shaders/ShaderChunk/default_fragment.glsl";

class ShaderMaterial extends Material {
    public isShaderMaterial:Bool = true;
    public type:String = "ShaderMaterial";
    public defines:Map<String, Dynamic> = new Map();
    public uniforms:Map<String, Dynamic> = new Map();
    public uniformsGroups:Array<Dynamic> = [];
    public vertexShader:String = default_vertex;
    public fragmentShader:String = default_fragment;
    public linewidth:Float = 1.0;
    public wireframe:Bool;
    public wireframeLinewidth:Float;
    public fog:Bool;
    public lights:Bool;
    public clipping:Bool;
    public forceSinglePass:Bool = true;
    public extensions:Map<String, Bool> = new Map();
    public defaultAttributeValues:Map<String, Array<Float>> = new Map();
    public index0AttributeName:String;
    public uniformsNeedUpdate:Bool;
    public glslVersion:String;

    public function new(parameters:Map<String, Dynamic> = null) {
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
        data.uniforms = {};
        for (var name in this.uniforms) {
            var uniform = this.uniforms.get(name);
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
            }
        }
        if (this.defines.size() > 0) data.defines = this.defines;
        data.vertexShader = this.vertexShader;
        data.fragmentShader = this.fragmentShader;
        data.lights = this.lights;
        data.clipping = this.clipping;
        var extensions = new Map<String, Bool>();
        for (var key in this.extensions) {
            if (this.extensions.get(key)) extensions.set(key, true);
        }
        if (extensions.size() > 0) data.extensions = extensions;
        return data;
    }
}

class ShaderMaterialExtern {
    public static function __properties__() {
        return {
            isShaderMaterial: { set: null },
            type: { set: null },
            defines: { set: null },
            uniforms: { set: null },
            uniformsGroups: { set: null },
            vertexShader: { set: null },
            fragmentShader: { set: null },
            linewidth: { set: null },
            wireframe: { set: null },
            wireframeLinewidth: { set: null },
            fog: { set: null },
            lights: { set: null },
            clipping: { set: null },
            forceSinglePass: { set: null },
            extensions: { set: null },
            defaultAttributeValues: { set: null },
            index0AttributeName: { set: null },
            uniformsNeedUpdate: { set: null },
            glslVersion: { set: null }
        };
    }
}