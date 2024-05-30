import js.three.*;

class Lensflare extends Mesh {
    public var isLensflare:Bool;
    public var type:String;
    public var frustumCulled:Bool;
    public var renderOrder:Float;
    private var positionScreen:Vector3;
    private var positionView:Vector3;
    private var tempMap:FramebufferTexture;
    private var occlusionMap:FramebufferTexture;
    private var currentType:UnsignedByteType;
    private var geometry:BufferGeometry;
    private var material1a:RawShaderMaterial;
    private var material1b:RawShaderMaterial;
    private var mesh1:Mesh;
    private var elements:Array<LensflareElement>;
    private var shader:Shader;
    private var material2:RawShaderMaterial;
    private var mesh2:Mesh;
    private var scale:Vector2;
    private var screenPositionPixels:Vector2;
    private var validArea:Box2;
    private var viewport:Vector4;

    public function new() {
        super(Lensflare.Geometry, new MeshBasicMaterial({ opacity: 0, transparent: true }));
        isLensflare = true;
        type = 'Lensflare';
        frustumCulled = false;
        renderOrder = Infinity;
        positionScreen = new Vector3();
        positionView = new Vector3();
        tempMap = new FramebufferTexture(16, 16);
        occlusionMap = new FramebufferTexture(16, 16);
        currentType = UnsignedByteType.INSTANCE;
        geometry = Lensflare.Geometry;
        material1a = new RawShaderMaterial({
            uniforms: {
                'scale': { value: null },
                'screenPosition': { value: null }
            },
            vertexShader: "precision highp float;\n\nuniform vec3 screenPosition;\nuniform vec2 scale;\n\nattribute vec3 position;\n\nvoid main() {\n\n    gl_Position = vec4( position.xy * scale + screenPosition.xy, screenPosition.z, 1.0 );\n\n}",
            fragmentShader: "precision highp float;\n\nvoid main() {\n\n    gl_FragColor = vec4( 1.0, 0.0, 1.0, 1.0 );\n\n}",
            depthTest: true,
            depthWrite: false,
            transparent: false
        });
        material1b = new RawShaderMaterial({
            uniforms: {
                'map': { value: tempMap },
                'scale': { value: null },
                'screenPosition': { value: null }
            },
            vertexShader: "precision highp float;\n\nuniform vec3 screenPosition;\nuniform vec2 scale;\n\nattribute vec3 position;\nattribute vec2 uv;\n\nvarying vec2 vUV;\n\nvoid main() {\n\n    vUV = uv;\n\n    gl_Position = vec4( position.xy * scale + screenPosition.xy, screenPosition.z, 1.0 );\n\n}",
            fragmentShader: "precision highp float;\n\nuniform sampler2D map;\n\nvarying vec2 vUV;\n\nvoid main() {\n\n    gl_FragColor = texture2D( map, vUV );\n\n}",
            depthTest: false,
            depthWrite: false,
            transparent: false
        });
        mesh1 = new Mesh(geometry, material1a);
        elements = [];
        shader = LensflareElement.Shader;
        material2 = new RawShaderMaterial({
            name: shader.name,
            uniforms: {
                'map': { value: null },
                'occlusionMap': { value: occlusionMap },
                'color': { value: new Color(0xffffff) },
                'scale': { value: new Vector2() },
                'screenPosition': { value: new Vector3() }
            },
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            blending: AdditiveBlending.INSTANCE,
            transparent: true,
            depthWrite: false
        });
        mesh2 = new Mesh(geometry, material2);
    }

    public function addElement(element:LensflareElement) {
        elements.push(element);
    }

    public function onBeforeRender(renderer:WebGLRenderer, scene:Scene, camera:Camera) {
        renderer.getCurrentViewport(viewport);
        var renderTarget = renderer.getRenderTarget();
        var type = (renderTarget != null) ? renderTarget.texture.type : UnsignedByteType.INSTANCE;
        if (currentType != type) {
            tempMap.dispose();
            occlusionMap.dispose();
            tempMap.type = occlusionMap.type = type;
            currentType = type;
        }
        var invAspect = viewport.w / viewport.z;
        var halfViewportWidth = viewport.z / 2.0;
        var halfViewportHeight = viewport.w / 2.0;
        var size = 16 / viewport.w;
        scale.set(size * invAspect, size);
        validArea.min.set(viewport.x, viewport.y);
        validArea.max.set(viewport.x + (viewport.z - 16), viewport.y + (viewport.w - 16));
        positionView.setFromMatrixPosition(this.matrixWorld);
        positionView.applyMatrix4(camera.matrixWorldInverse);
        if (positionView.z > 0) return; // lensflare is behind the camera
        positionScreen.copy(positionView).applyMatrix4(camera.projectionMatrix);
        screenPositionPixels.x = viewport.x + (positionScreen.x * halfViewportWidth) + halfViewportWidth - 8;
        screenPositionPixels.y = viewport.y + (positionScreen.y * halfViewportHeight) + halfViewportHeight - 8;
        if (validArea.containsPoint(screenPositionPixels)) {
            renderer.copyFramebufferToTexture(tempMap, screenPositionPixels);
            var uniforms = material1a.uniforms;
            uniforms['scale'].value = scale;
            uniforms['screenPosition'].value = positionScreen;
            renderer.renderBufferDirect(camera, null, geometry, material1a, mesh1, null);
            renderer.copyFramebufferToTexture(occlusionMap, screenPositionPixels);
            uniforms = material1b.uniforms;
            uniforms['scale'].value = scale;
            uniforms['screenPosition'].value = positionScreen;
            renderer.renderBufferDirect(camera, null, geometry, material1b, mesh1, null);
            var vecX = - positionScreen.x * 2;
            var vecY = - positionScreen.y * 2;
            var i = 0;
            while (i < elements.length) {
                var element = elements[i];
                var uniforms = material2.uniforms;
                uniforms['color'].value.copy(element.color);
                uniforms['map'].value = element.texture;
                uniforms['screenPosition'].value.x = positionScreen.x + vecX * element.distance;
                uniforms['screenPosition'].value.y = positionScreen.y + vecY * element.distance;
                size = element.size / viewport.w;
                invAspect = viewport.w / viewport.z;
                uniforms['scale'].value.set(size * invAspect, size);
                material2.uniformsNeedUpdate = true;
                renderer.renderBufferDirect(camera, null, geometry, material2, mesh2, null);
                i++;
            }
        }
    }

    public function dispose() {
        material1a.dispose();
        material1b.dispose();
        material2.dispose();
        tempMap.dispose();
        occlusionMap.dispose();
        var i = 0;
        while (i < elements.length) {
            elements[i].texture.dispose();
            i++;
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

static var Shader:Shader;

class Lensflare {
    static var Geometry:BufferGeometry;
}

class LensflareElement {
    static var Shader:Shader;
}

static function __init__() {
    Lensflare.Geometry = (function() {
        var geometry = new BufferGeometry();
        var float32Array = new Float32Array([-1, -1, 0, 0, 0, 1, -1, 0, 1, 0, 1, 1, 0, 1, 1, -1, 1, 0, 0, 1]);
        var interleavedBuffer = new InterleavedBuffer(float32Array, 5);
        geometry.setIndex([0, 1, 2, 0, 2, 3]);
        geometry.setAttribute('position', new InterleavedBufferAttribute(interleavedBuffer, 3, 0, false));
        geometry.setAttribute('uv', new InterleavedBufferAttribute(interleavedBuffer, 2, 3, false));
        return geometry;
    })();
    LensflareElement.Shader = {
        name: 'LensflareElementShader',
        uniforms: {
            'map': { value: null },
            'occlusionMap': { value: null },
            'color': { value: null },
            'scale': { value: null },
            'screenPosition': { value: null }
        },
        vertexShader: "precision highp float;\n\nuniform vec3 screenPosition;\nuniform vec2 scale;\n\nuniform sampler2D occlusionMap;\n\nattribute vec3 position;\nattribute vec2 uv;\n\nvarying vec2 vUV;\nvarying float vVisibility;\n\nvoid main() {\n\n    vUV = uv;\n\n    vec2 pos = position.xy;\n\n    vec4 visibility = texture2D( occlusionMap, vec2( 0.1, 0.1 ) );\n    visibility += texture2D( occlusionMap, vec2( 0.5, 0.1 ) );\n    visibility += texture2D( occlusionMap, vec2( 0.9, 0.1 ) );\n    visibility += texture2D( occlusionMap, vec2( 0.9, 0.5 ) );\n    visibility += texture2D( occlusionMap, vec2( 0.9, 0.9 ) );\n    visibility += texture2D( occlusionMap, vec2( 0.5, 0.9 ) );\n    visibility += texture2D( occlusionMap, vec2( 0.1, 0.9 ) );\n    visibility += texture2D( occlusionMap, vec2( 0.1, 0.5 ) );\n    visibility += texture2D( occlusionMap, vec2( 0.5, 0.5 ) );\n\n    vVisibility =        visibility.r / 9.0;\n    vVisibility *= 1.0 - visibility.g / 9.0;\n    vVisibility *=       visibility.b / 9.0;\n\n    gl_Position = vec4( ( pos * scale + screenPosition.xy ).xy, screenPosition.z, 1.0 );\n\n}",
        fragmentShader: "precision highp float;\n\nuniform sampler2D map;\nuniform vec3 color;\n\nvarying vec2 vUV;\nvarying float vVisibility;\n\nvoid main() {\n\n    vec4 texture = texture2D( map, vUV );\n    texture.a *= vVisibility;\n    gl_FragColor = texture;\n    gl_FragColor.rgb *= color;\n\n}"
    };
}