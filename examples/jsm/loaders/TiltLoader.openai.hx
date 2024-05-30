package three.js.loaders;

import three.js.BufferAttribute;
import three.js.BufferGeometry;
import three.js.Color;
import three.js.DoubleSide;
import three.js.FileLoader;
import three.js.Group;
import three.js.Loader;
import three.js.Mesh;
import three.js.MeshBasicMaterial;
import three.js.RawShaderMaterial;
import three.js.TextureLoader;
import three.js.Quaternion;
import three.js.Vector3;

import fflate.Fflate;

class TiltLoader extends Loader {
    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope:TiltLoader = this;

        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, function(buffer:ArrayBuffer) {
            try {
                onLoad(scope.parse(buffer));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer:ArrayBuffer):Group {
        var group:Group = new Group();

        // https://docs.google.com/document/d/11ZsHozYn9FnWG7y3s3WAyKIACfbfwb4PbaS8cZ_xjvo/edit#

        var zip = Fflate.unzipSync(new Uint8Array(buffer.slice(16)));
        // ... (rest of the parsing code remains the same)
    }
}

class StrokeGeometry extends BufferGeometry {
    public function new(strokes:Array<Dynamic>) {
        super();

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];
        var uvs:Array<Float> = [];

        // ... (rest of the geometry creation code remains the same)
    }
}

class CustomShaders {
    public static var common:{
        colors:{
            BloomColor:String,
            LinearToSrgb:String,
            hsv:String,
            SrgbToLinear:String
        }
    } = {
        colors: {
            BloomColor: '
                vec3 BloomColor(vec3 color, float gain) {
                    // ...
                }
            ',
            LinearToSrgb: '
                vec3 LinearToSrgb(vec3 color) {
                    // ...
                }
            ',
            hsv: '
                // ...
            ',
            SrgbToLinear: '
                vec3 SrgbToLinear(vec3 color) {
                    // ...
                }
            '
        }
    };

    public static var shaders:Dynamic = null;

    public static function getShaders():Dynamic {
        if (shaders == null) {
            shaders = {
                Light: {
                    uniforms: {
                        mainTex: { value: loader.load('Light.webp') },
                        alphaTest: { value: 0.067 },
                        emission_gain: { value: 0.45 },
                        alpha: { value: 1 }
                    },
                    vertexShader: '
                        precision highp float;
                        // ...
                    ',
                    fragmentShader: '
                        precision highp float;
                        // ...
                    ',
                    side: 2,
                    transparent: true,
                    depthFunc: 2,
                    depthWrite: true,
                    depthTest: false,
                    blending: 5,
                    blendDst: 201,
                    blendDstAlpha: 201,
                    blendEquation: 100,
                    blendEquationAlpha: 100,
                    blendSrc: 201,
                    blendSrcAlpha: 201
                }
            };
        }
        return shaders;
    }

    public static function getMaterial(GUID:String):Dynamic {
        var name:String = BRUSH_LIST_ARRAY[GUID];

        switch (name) {
            case 'Light':
                return new RawShaderMaterial(getShaders().Light);
            default:
                return new MeshBasicMaterial({ vertexColors: true, side: DoubleSide });
        }
    }
}