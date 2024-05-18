package three.js.examples.jsm.objects;

import three.js.BufferGeometry;
import three.js.Color;
import three.js.FramebufferTexture;
import three.js.InterleavedBuffer;
import three.js.InterleavedBufferAttribute;
import three.js.Mesh;
import three.js.MeshBasicMaterial;
import three.js.RawShaderMaterial;
import three.jsUnsignedByteType;
import three.js.Vector2;
import three.js.Vector3;
import three.js.Vector4;

class Lensflare extends Mesh {

    public var isLensflare:Bool = true;
    public var type:String = 'Lensflare';
    public var frustumCulled:Bool = false;
    public var renderOrder:Float = Math.POSITIVE_INFINITY;

    private var positionScreen:Vector3;
    private var positionView:Vector3;

    private var tempMap:FramebufferTexture;
    private var occlusionMap:FramebufferTexture;

    private var material1a:RawShaderMaterial;
    private var material1b:RawShaderMaterial;
    private var material2:RawShaderMaterial;

    private var mesh1:Mesh;
    private var mesh2:Mesh;

    private var elements:Array<LensflareElement>;

    public function new() {
        super(LensflareGeometry, new MeshBasicMaterial({ opacity: 0, transparent: true }));

        positionScreen = new Vector3();
        positionView = new Vector3();

        tempMap = new FramebufferTexture(16, 16);
        occlusionMap = new FramebufferTexture(16, 16);

        material1a = new RawShaderMaterial({
            uniforms: {
                scale: { value: null },
                screenPosition: { value: null }
            },
            vertexShader: '
                precision highp float;
                uniform vec3 screenPosition;
                uniform vec2 scale;
                attribute vec3 position;
                void main() {
                    gl_Position = vec4( position.xy * scale + screenPosition.xy, screenPosition.z, 1.0 );
                }',
            fragmentShader: '
                precision highp float;
                void main() {
                    gl_FragColor = vec4( 1.0, 0.0, 1.0, 1.0 );
                }',
            depthTest: true,
            depthWrite: false,
            transparent: false
        });

        material1b = new RawShaderMaterial({
            uniforms: {
                map: { value: tempMap },
                scale: { value: null },
                screenPosition: { value: null }
            },
            vertexShader: '
                precision highp float;
                uniform vec3 screenPosition;
                uniform vec2 scale;
                attribute vec3 position;
                attribute vec2 uv;
                varying vec2 vUV;
                void main() {
                    vUV = uv;
                    gl_Position = vec4( position.xy * scale + screenPosition.xy, screenPosition.z, 1.0 );
                }',
            fragmentShader: '
                precision highp float;
                uniform sampler2D map;
                varying vec2 vUV;
                void main() {
                    gl_FragColor = texture2D( map, vUV );
                }',
            depthTest: false,
            depthWrite: false,
            transparent: false
        });

        mesh1 = new Mesh(LensflareGeometry, material1a);

        elements = new Array<LensflareElement>();

        material2 = new RawShaderMaterial({
            name: LensflareElement.Shader.name,
            uniforms: {
                map: { value: null },
                occlusionMap: { value: occlusionMap },
                color: { value: new Color(0xffffff) },
                scale: { value: new Vector2() },
                screenPosition: { value: new Vector3() }
            },
            vertexShader: LensflareElement.Shader.vertexShader,
            fragmentShader: LensflareElement.Shader.fragmentShader,
            blending: AdditiveBlending,
            transparent: true,
            depthWrite: false
        });

        mesh2 = new Mesh(LensflareGeometry, material2);

        addElement = function(element:LensflareElement) {
            elements.push(element);
        };
    }

    public function onBeforeRender(renderer:Renderer, scene:Scene, camera:Camera) {
        // implementation
    }

    public function dispose() {
        material1a.dispose();
        material1b.dispose();
        material2.dispose();

        tempMap.dispose();
        occlusionMap.dispose();

        for (element in elements) {
            element.texture.dispose();
        }
    }
}

class LensflareElement {
    public var texture:Texture;
    public var size:Float;
    public var distance:Float;
    public var color:Color;

    public function new(texture:Texture, size:Float = 1, distance:Float = 0, color:Color = new Color(0xffffff)) {
        this.texture = texture;
        this.size = size;
        this.distance = distance;
        this.color = color;
    }
}

class LensflareElementShader {
    public static var name:String = 'LensflareElementShader';
    public static var uniforms:Dynamic = {
        map: { value: null },
        occlusionMap: { value: null },
        color: { value: null },
        scale: { value: null },
        screenPosition: { value: null }
    };
    public static var vertexShader:String = '
        precision highp float;
        uniform vec3 screenPosition;
        uniform vec2 scale;
        uniform sampler2D occlusionMap;
        attribute vec3 position;
        attribute vec2 uv;
        varying vec2 vUV;
        varying float vVisibility;
        void main() {
            vUV = uv;
            vec2 pos = position.xy;
            vec4 visibility = texture2D( occlusionMap, vec2( 0.1, 0.1 ) );
            visibility += texture2D( occlusionMap, vec2( 0.5, 0.1 ) );
            visibility += texture2D( occlusionMap, vec2( 0.9, 0.1 ) );
            visibility += texture2D( occlusionMap, vec2( 0.9, 0.5 ) );
            visibility += texture2D( occlusionMap, vec2( 0.9, 0.9 ) );
            visibility += texture2D( occlusionMap, vec2( 0.5, 0.9 ) );
            visibility += texture2D( occlusionMap, vec2( 0.1, 0.9 ) );
            visibility += texture2D( occlusionMap, vec2( 0.1, 0.5 ) );
            visibility += texture2D( occlusionMap, vec2( 0.5, 0.5 ) );
            vVisibility =        visibility.r / 9.0;
            vVisibility *= 1.0 - visibility.g / 9.0;
            vVisibility *=       visibility.b / 9.0;
            gl_Position = vec4( ( pos * scale + screenPosition.xy ).xy, screenPosition.z, 1.0 );
        }';
    public static var fragmentShader:String = '
        precision highp float;
        uniform sampler2D map;
        uniform vec3 color;
        varying vec2 vUV;
        varying float vVisibility;
        void main() {
            vec4 texture = texture2D( map, vUV );
            texture.a *= vVisibility;
            gl_FragColor = texture;
            gl_FragColor.rgb *= color;
        }';
}

class LensflareGeometry {
    private static var geometry:BufferGeometry;

    public static function getGeometry():BufferGeometry {
        if (geometry == null) {
            geometry = new BufferGeometry();

            var float32Array:Array<Float> = [
                -1, -1, 0, 0, 0,
                1, -1, 0, 1, 0,
                1, 1, 0, 1, 1,
                -1, 1, 0, 0, 1
            ];

            var interleavedBuffer:InterleavedBuffer = new InterleavedBuffer(new Float32Array(float32Array), 5);

            geometry.setIndex([0, 1, 2, 0, 2, 3]);
            geometry.setAttribute('position', new InterleavedBufferAttribute(interleavedBuffer, 3, 0, false));
            geometry.setAttribute('uv', new InterleavedBufferAttribute(interleavedBuffer, 2, 3, false));
        }

        return geometry;
    }
}