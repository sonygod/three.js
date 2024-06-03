import js.Browser;
import js.Boot;
import js.html.compat.JSArray;
import js.Lib;

class Color {
    public var r: Float;
    public var g: Float;
    public var b: Float;

    public function new(hex: Int) {
        this.r = ((hex >> 16) & 0xFF) / 255;
        this.g = ((hex >> 8) & 0xFF) / 255;
        this.b = (hex & 0xFF) / 255;
    }

    public function copy(color: Color): Color {
        this.r = color.r;
        this.g = color.g;
        this.b = color.b;
        return this;
    }
}

class UniformsUtils {
    public static function merge(arrays: Array<Dynamic>): Dynamic {
        var result = {};
        for (array in arrays) {
            for (key in Reflect.fields(array)) {
                result[key] = array[key];
            }
        }
        return result;
    }

    public static function clone(uniforms: Dynamic): Dynamic {
        var result = {};
        for (key in Reflect.fields(uniforms)) {
            result[key] = uniforms[key].value.copy ? uniforms[key].value.copy() : uniforms[key].value;
        }
        return result;
    }
}

class UniformsLib {
    public static var common = {
        "diffuse": { "value": new Color(0xFFFFFF) },
        "opacity": { "value": 1.0 }
        //... add other common uniforms
    };

    //... add other uniform libraries
}

class ShaderMaterial {
    public var defines: Dynamic = {};
    public var uniforms: Dynamic = {};
    public var vertexShader: String = "";
    public var fragmentShader: String = "";
    public var fog: Bool = false;
    public var lights: Bool = true;
    public var clipping: Bool = false;

    public function setValues(parameters: Dynamic) {
        if (parameters != null) {
            for (key in Reflect.fields(parameters)) {
                if (this.hasOwnProperty(key)) {
                    this[key] = parameters[key];
                }
            }
        }
    }

    public function copy(source: ShaderMaterial): ShaderMaterial {
        //... copy properties
        return this;
    }
}

class MeshGouraudMaterial extends ShaderMaterial {
    public var isMeshGouraudMaterial: Bool = true;
    public var type: String = "MeshGouraudMaterial";
    public var combine: String = "MultiplyOperation";

    public function new(parameters: Dynamic = null) {
        super();

        var shader = GouraudShader;

        this.defines = js.Boot.clone(shader.defines);
        this.uniforms = UniformsUtils.clone(shader.uniforms);
        this.vertexShader = shader.vertexShader;
        this.fragmentShader = shader.fragmentShader;

        var exposePropertyNames = ["map", "lightMap", "lightMapIntensity", "aoMap", "aoMapIntensity", "emissive", "emissiveIntensity", "emissiveMap", "specularMap", "alphaMap", "envMap", "reflectivity", "refractionRatio", "opacity", "diffuse"];

        for (propertyName in exposePropertyNames) {
            var this1 = this;
            var propertyName1 = propertyName;
            Object.defineProperty(this, propertyName, {
                get: function() {
                    return this1.uniforms[propertyName1].value;
                },
                set: function(value) {
                    this1.uniforms[propertyName1].value = value;
                }
            });
        }

        Object.defineProperty(this, "color", Object.getOwnPropertyDescriptor(this, "diffuse"));

        this.setValues(parameters);
    }
}

var GouraudShader = {
    name: "GouraudShader",
    uniforms: UniformsUtils.merge([UniformsLib.common, /*... other uniform libraries */]),
    vertexShader: "/*... vertex shader code */",
    fragmentShader: "/*... fragment shader code */"
};

class MultiplyOperation {} // Dummy class