import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.Texture2D;
import openfl.display3D.textures.Texture3D;
import openfl.display3D.textures.TextureCube;
import openfl.display3D.materials.ShaderMaterial;
import openfl.display3D.materials.TextureMaterial;
import openfl.display3D.geom.Vector3;
import openfl.display3D.geom.Matrix3D;
import openfl.display3D.geom.Vector4;
import openfl.display3D.renderables.Mesh;
import openfl.display3D.renderables.DefaultShader;
import openfl.display3D.renderables.Geometry;
import openfl.display3D.renderables.PlaneGeometry;
import openfl.display3D.renderables.CubeGeometry;
import openfl.display3D.renderables.SphereGeometry;
import openfl.display3D.renderables.Renderable;
import openfl.display3D.renderables.MeshData;
import openfl.display3D.renderables.VertexData;
import openfl.display3D.renderables.VertexBuffer;
import openfl.display3D.renderables.IndexBuffer;
import openfl.display3D.renderers.Renderer;
import openfl.display3D.renderers.DefaultRenderContext;
import openfl.display3D.renderers.RenderContext;
import openfl.display3D.cameras.Camera;
import openfl.display3D.cameras.OrthographicCamera;
import openfl.display3D.cameras.PerspectiveCamera;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.renderables.Renderable;
import openfl.display3D.textures.Texture2D;
import openfl.geom.ColorTransform;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.TextureBase;

class PMREMGenerator {

    private var _renderer:Renderer;
    private var _pingPongRenderTarget:Texture2D;

    private var _lodMax:Int;
    private var _cubeSize:Int;
    private var _lodPlanes:Array<Geometry>;
    private var _sizeLods:Array<Int>;
    private var _sigmas:Array<Float>;

    private var _blurMaterial:ShaderMaterial;
    private var _cubemapMaterial:ShaderMaterial;
    private var _equirectMaterial:ShaderMaterial;

    public function new(renderer:Renderer) {
        this._renderer = renderer;
        this._pingPongRenderTarget = null;

        this._lodMax = 0;
        this._cubeSize = 0;
        this._lodPlanes = [];
        this._sizeLods = [];
        this._sigmas = [];

        this._blurMaterial = null;
        this._cubemapMaterial = null;
        this._equirectMaterial = null;

        this._compileMaterial(this._blurMaterial);
    }

    public function fromScene(scene:Renderable, sigma:Float = 0, near:Float = 0.1, far:Float = 100):Texture2D {
        var oldTarget = this._renderer.renderContext.target;
        var oldActiveCubeFace = this._renderer.renderContext.activeCubeFace;
        var oldActiveMipmapLevel = this._renderer.renderContext.activeMipmapLevel;
        var oldXrEnabled = this._renderer.renderContext.xrEnabled;

        this._renderer.renderContext.xrEnabled = false;

        this._setSize(256);

        var cubeUVRenderTarget = this._allocateTargets();
        cubeUVRenderTarget.depthBuffer = true;

        this._sceneToCubeUV(scene, near, far, cubeUVRenderTarget);

        if (sigma > 0) {
            this._blur(cubeUVRenderTarget, 0, 0, sigma);
        }

        this._applyPMREM(cubeUVRenderTarget);
        this._cleanup(cubeUVRenderTarget);

        return cubeUVRenderTarget;
    }

    public function fromEquirectangular(equirectangular:TextureBase, renderTarget:Texture2D = null):Texture2D {
        return this._fromTexture(equirectangular, renderTarget);
    }

    public function fromCubemap(cubemap:CubeTexture, renderTarget:Texture2D = null):Texture2D {
        return this._fromTexture(cubemap, renderTarget);
    }

    public function compileCubemapShader() {
        if (this._cubemapMaterial == null) {
            this._cubemapMaterial = _getCubemapMaterial();
            this._compileMaterial(this._cubemapMaterial);
        }
    }

    public function compileEquirectangularShader() {
        if (this._equirectMaterial == null) {
            this._equirectMaterial = _getEquirectMaterial();
            this._compileMaterial(this._equirectMaterial);
        }
    }

    public function dispose() {
        this._dispose();

        if (this._cubemapMaterial != null) this._cubemapMaterial.dispose();
        if (this._equirectMaterial != null) this._equirectMaterial.dispose();
    }

    private function _setSize(cubeSize:Int) {
        this._lodMax = Math.floor(Math.log2(cubeSize));
        this._cubeSize = Math.pow(2, this._lodMax);
    }

    private function _dispose() {
        if (this._blurMaterial != null) this._blurMaterial.dispose();

        if (this._pingPongRenderTarget != null) this._pingPongRenderTarget.dispose();

        for (i in 0...this._lodPlanes.length) {
            this._lodPlanes[i].dispose();
        }
    }

    private function _cleanup(outputTarget:Texture2D) {
        this._renderer.renderContext.target = oldTarget;
        this._renderer.renderContext.activeCubeFace = oldActiveCubeFace;
        this._renderer.renderContext.activeMipmapLevel = oldActiveMipmapLevel;
        this._renderer.renderContext.xrEnabled = oldXrEnabled;

        outputTarget.scissorTest = false;
        _setViewport(outputTarget, 0, 0, outputTarget.width, outputTarget.height);
    }

    private function _fromTexture(texture:TextureBase, renderTarget:Texture2D):Texture2D {
        if (Std.is(texture, CubeTexture)) {
            this._setSize(texture.bitmapData.width);
        } else {
            this._setSize(texture.bitmapData.width / 4);
        }

        var oldTarget = this._renderer.renderContext.target;
        var oldActiveCubeFace = this._renderer.renderContext.activeCubeFace;
        var oldActiveMipmapLevel = this._renderer.renderContext.activeMipmapLevel;
        var oldXrEnabled = this._renderer.renderContext.xrEnabled;

        this._renderer.renderContext.xrEnabled = false;

        var cubeUVRenderTarget = renderTarget || this._allocateTargets();
        this._textureToCubeUV(texture, cubeUVRenderTarget);
        this._applyPMREM(cubeUVRenderTarget);
        this._cleanup(cubeUVRenderTarget);

        return cubeUVRenderTarget;
    }

    private function _allocateTargets():Texture2D {
        var width = 3 * Math.max(this._cubeSize, 16 * 7);
        var height = 4 * this._cubeSize;

        var params = {
            magFilter: Context3D.LINEAR,
            minFilter: Context3D.LINEAR,
            generateMipmaps: false,
            type: Context3D.HALF_FLOAT,
            format: Context3D.RGBA,
            colorSpace: Context3D.LINEAR_SRGB,
            depthBuffer: false
        };

        var cubeUVRenderTarget = _createRenderTarget(width, height, params);

        if (this._pingPongRenderTarget == null || this._pingPongRenderTarget.width != width || this._pingPongRenderTarget.height != height) {
            if (this._pingPongRenderTarget != null) {
                this._dispose();
            }

            this._pingPongRenderTarget = _createRenderTarget(width, height, params);

            var _lodMax = this._lodMax;
            ({ sizeLods: this._sizeLods, lodPlanes: this._lodPlanes, sigmas: this._sigmas } = _createPlanes(_lodMax));

            this._blurMaterial = _getBlurShader(_lodMax, width, height);
        }

        return cubeUVRenderTarget;
    }

    private function _compileMaterial(material:ShaderMaterial) {
        var tmpMesh = new Mesh(this._lodPlanes[0], material);
        this._renderer.compile(tmpMesh, _flatCamera);
    }

    private function _sceneToCubeUV(scene:Renderable, near:Float, far:Float, cubeUVRenderTarget:Texture2D) {
        var fov = 90;
        var aspect = 1;
        var cubeCamera = new PerspectiveCamera(fov, aspect, near, far);
        var upSign = [1, -1, 1, 1, 1, 1];
        var forwardSign = [1, 1, 1, -1, -1, -1];
        var renderer = this._renderer;

        var originalAutoClear = renderer.renderContext.autoClear;
        var toneMapping = renderer.renderContext.toneMapping;
        renderer.renderContext.getClearColor(clearColor);

        renderer.renderContext.toneMapping = Context3D.NONE;
        renderer.renderContext.autoClear = false;

        var backgroundMaterial = new TextureMaterial(null);
        backgroundMaterial.name = "PMREM.Background";
        backgroundMaterial.side = Context3D.BACK;
        backgroundMaterial.depthWrite = false;
        backgroundMaterial.depthTest = false;

        var backgroundBox = new Mesh(new CubeGeometry(), backgroundMaterial);

        var useSolidColor = false;
        var background = scene.background;

        if (background != null) {
            if (Std.is(background, Texture2D)) {
                backgroundMaterial.texture = background;
                scene.background = null;
                useSolidColor = true;
            }
        } else {
            backgroundMaterial.color = clearColor;
            useSolidColor = true;
        }

        for (i in 0...6) {
            var col = i % 3;

            if (col == 0) {
                cubeCamera.up.set(0, upSign[i], 0);
                cubeCamera.lookAt(forwardSign[i], 0, 0);
            } else if (col == 1) {
                cubeCamera.up.set(0, 0, upSign[i]);
                cubeCamera.lookAt(0, forwardSign[i], 0);
            } else {
                cubeCamera.up.set(0, upSign[i], 0);
                cubeCamera.lookAt(0, 0, forwardSign[i]);
            }

            var size = this._cubeSize;

            _setViewport(cubeUVRenderTarget, col * size, i > 2 ? size : 0, size, size);

            renderer.renderContext.target = cubeUVRenderTarget;

            if (useSolidColor) {
                renderer.render(backgroundBox, cubeCamera);
            }

            renderer.render(scene, cubeCamera);
        }

        backgroundBox.geometry.dispose();
        backgroundBox.material.dispose();

        renderer.renderContext.toneMapping = toneMapping;
        renderer.renderContext.autoClear = originalAutoClear;
        scene.background = background;
    }

    private function _textureToCubeUV(texture:TextureBase, cubeUVRenderTarget:Texture2D) {
        var renderer = this._renderer;

        var isCubeTexture = Std.is(texture, CubeTexture);

        if (isCubeTexture) {
            if (this._cubemapMaterial == null) {
                this._cubemapMaterial = _getCubemapMaterial();
            }

            this._cubemapMaterial.uniforms.flipEnvMap.value = (texture.isRenderTargetTexture == false) ? -1 : 1;
        } else {
            if (this._equirectMaterial == null) {
                this._equirectMaterial = _getEquirectMaterial();
            }
        }

        var material = isCubeTexture ? this._cubemapMaterial : this._equirectMaterial;
        var mesh = new Mesh(this._lodPlanes[0], material);

        var uniforms = material.uniforms;

        uniforms['envMap'].value = texture;

        var size = this._cubeSize;

        _setViewport(cubeUVRenderTarget, 0, 0, 3 * size, 2 * size);

        renderer.renderContext.target = cubeUVRenderTarget;
        renderer.render(mesh, _flatCamera);
    }

    private function _applyPMREM(cubeUVRenderTarget:Texture2D) {
        var renderer = this._renderer;
        var autoClear = renderer.renderContext.autoClear;
        renderer.renderContext.autoClear = false;
        var n = this._lodPlanes.length;

        for (i in 1...n) {
            var sigma = Math.sqrt(this._sigmas[i] * this._sigmas[i] - this._sigmas[i - 1] * this._sigmas[i - 1]);

            var poleAxis = _axisDirections[(n - i - 1) % _axisDirections.length];

            this._blur(cubeUVRenderTarget, i - 1, i, sigma, poleAxis);
        }

        renderer.renderContext.autoClear = autoClear;
    }

    private function _blur(cubeUVRenderTarget:Texture2D, lodIn:Int, lodOut:Int, sigmaRadians:Float, poleAxis:Vector3) {
        var pingPongRenderTarget = this._pingPongRenderTarget;

        this._halfBlur(cubeUVRenderTarget, pingPongRenderTarget, lodIn, lodOut, sigmaRadians, 'latitudinal', poleAxis);

        this._halfBlur(pingPongRenderTarget, cubeUVRenderTarget, lodOut, lodOut, sigmaRadians, 'longitudinal', poleAxis);
    }

    private function _halfBlur(targetIn:Texture2D, targetOut:Texture2D, lodIn:Int, lodOut:Int, sigmaRadians:Float, direction:String, poleAxis:Vector3) {
        var renderer = this._renderer;
        var blurMaterial = this._blurMaterial;

        if (direction != 'latitudinal' && direction != 'longitudinal') {
            console.error('blur direction must be either latitudinal or longitudinal!');
        }

        var STANDARD_DEVIATIONS = 3;

        var blurMesh = new Mesh(this._lodPlanes[lodOut], blurMaterial);
        var blurUniforms = blurMaterial.uniforms;

        var pixels = this._sizeLods[lodIn] - 1;
        var radiansPerPixel = Math.isFinite(sigmaRadians) ? Math.PI / (2 * pixels) : 2 * Math.PI / (2 * MAX_SAMPLES - 1);
        var sigmaPixels = sigmaRadians / radiansPerPixel;
        var samples = Math.isFinite(sigmaRadians) ? 1 + Math.floor(STANDARD_DEVIATIONS * sigmaPixels) : MAX_SAMPLES;

        if (samples > MAX_SAMPLES) {
            console.warn('sigmaRadians, ' + sigmaRadians + ', is too large and will clip, as it requested ' + samples + ' samples when the maximum is set to ' + MAX_SAMPLES);
        }

        var weights = [];
        var sum = 0;

        for (i in 0...MAX_SAMPLES) {
            var x = i / sigmaPixels;
            var weight = Math.exp(-x * x / 2);
            weights.push(weight);

            if (i == 0) {
                sum += weight;
            } else if (i < samples) {
                sum += 2 * weight;
            }
        }

        for (i in 0...weights.length) {
            weights[i] = weights[i] / sum;
        }

        blurUniforms['envMap'].value = targetIn;
        blurUniforms['samples'].value = samples;
        blurUniforms['weights'].value = weights;
        blurUniforms['latitudinal'].value = direction == 'latitudinal';

        if (poleAxis != null) {
            blurUniforms['poleAxis'].value = poleAxis;
        }

        var _lodMax = this._lodMax;
        blurUniforms['dTheta'].value = radiansPerPixel;
        blurUniforms['mipInt'].value = _lodMax - lodIn;

        var outputSize = this._sizeLods[lodOut];
        var x = 3 * outputSize * (lodOut > _lodMax - LOD_MIN ? lodOut - _lodMax + LOD_MIN : 0);
        var y = 4 * (this._cubeSize - outputSize);

        _setViewport(targetOut, x, y, 3 * outputSize, 2 * outputSize);
        renderer.renderContext.target = targetOut;
        renderer.render(blurMesh, _flatCamera);
    }
}

private static var _flatCamera:OrthographicCamera = new OrthographicCamera();
private static var _clearColor:Vector4 = new Vector4();
private static var oldTarget:Texture2D = null;
private static var oldActiveCubeFace:Int = 0;
private static var oldActiveMipmapLevel:Int = 0;
private static var oldXrEnabled:Bool = false;

private static var PHI:Float = (1 + Math.sqrt(5)) / 2;
private static var INV_PHI:Float = 1 / PHI;

private static var _axisDirections:Array<Vector3> = [
    new Vector3(-PHI, INV_PHI, 0),
    new Vector3(PHI, INV_PHI, 0),
    new Vector3(-INV_PHI, 0, PHI),
    new Vector3(INV_PHI, 0, PHI),
    new Vector3(0, PHI, -INV_PHI),
    new Vector3(0, PHI, INV_PHI),
    new Vector3(-1, 1, -1),
    new Vector3(1, 1, -1),
    new Vector3(-1, 1, 1),
    new Vector3(1, 1, 1)
];

private static var LOD_MIN:Int = 4;

private static var EXTRA_LOD_SIGMA:Array<Float> = [0.125, 0.215, 0.35, 0.446, 0.526, 0.582];

private static var MAX_SAMPLES:Int = 20;

private static function _createPlanes(lodMax:Int):Dynamic {
    var lodPlanes = [];
    var sizeLods = [];
    var sigmas = [];

    var lod = lodMax;

    var totalLods = lodMax - LOD_MIN + 1 + EXTRA_LOD_SIGMA.length;

    for (i in 0...totalLods) {
        var sizeLod = Math.pow(2, lod);
        sizeLods.push(sizeLod);
        var sigma = 1.0 / sizeLod;

        if (i > lodMax - LOD_MIN) {
            sigma = EXTRA_LOD_SIGMA[i - lodMax + LOD_MIN - 1];
        } else if (i == 0) {
            sigma = 0;
        }

        sigmas.push(sigma);

        var texelSize = 1.0 / (sizeLod - 2);
        var min = -texelSize;
        var max = 1 + texelSize;
        var uv1 = [min, min, max, min, max, max, min, min, max, max, min, max];

        var cubeFaces = 6;
        var vertices = 6;
        var positionSize = 3;
        var uvSize = 2;
        var faceIndexSize = 1;

        var position = new Float32Array(positionSize * vertices * cubeFaces);
        var uv = new Float32Array(uvSize * vertices * cubeFaces);
        var faceIndex = new Float32Array(faceIndexSize * vertices * cubeFaces);

        for (face in 0...cubeFaces) {
            var x = (face % 3) * 2 / 3 - 1;
            var y = face > 2 ? 0 : -1;
            var coordinates = [
                x, y, 0,
                x + 2 / 3, y, 0,
                x + 2 / 3, y + 1, 0,
                x, y, 0,
                x + 2 / 3, y + 1, 0,
                x, y + 1, 0
            ];
            position.set(coordinates, positionSize * vertices * face);
            uv.set(uv1, uvSize * vertices * face);
            var fill = [face, face, face, face, face, face];
            faceIndex.set(fill, faceIndexSize * vertices * face);
        }

        var planes = new PlaneGeometry();
        planes.setAttribute('position', new VertexBuffer(position, positionSize));
        planes.setAttribute('uv', new VertexBuffer(uv, uvSize));
        planes.setAttribute('faceIndex', new VertexBuffer(faceIndex, faceIndexSize));
        lodPlanes.push(planes);

        if (lod > LOD_MIN) {
            lod--;
        }
    }

    return { lodPlanes, sizeLods, sigmas };
}

private static function _createRenderTarget(width:Int, height:Int, params:Dynamic):Texture2D {
    var cubeUVRenderTarget = new Texture2D(width, height, params);
    cubeUVRenderTarget.name = 'PMREM.cubeUv';
    cubeUVRenderTarget.scissorTest = true;
    return cubeUVRenderTarget;
}

private static function _setViewport(target:Texture2D, x:Int, y:Int, width:Int, height:Int) {
    target.viewport.set(x, y, width, height);
    target.scissor.set(x, y, width, height);
}

private static function _getBlurShader(lodMax:Int, width:Int, height:Int):ShaderMaterial {
    var weights = new Float32Array(MAX_SAMPLES);
    var poleAxis = new Vector3(0, 1, 0);
    var shaderMaterial = new ShaderMaterial(
        new DefaultShader(
            _getCommonVertexShader(),
            /* glsl */`
                precision mediump float;
                precision mediump int;

                varying vec3 vOutputDirection;

                uniform sampler2D envMap;
                uniform int samples;
                uniform float weights[ n ];
                uniform bool latitudinal;
                uniform float dTheta;
                uniform float mipInt;
                uniform vec3 poleAxis;

                #define ENVMAP_TYPE_CUBE_UV
                #include <cube_uv_reflection_fragment>

                vec3 getSample(float theta, vec3 axis) {
                    float cosTheta = cos(theta);
                    // Rodrigues' axis-angle rotation
                    vec3 sampleDirection = vOutputDirection * cosTheta
                        + cross(axis, vOutputDirection) * sin(theta)
                        + axis * dot(axis, vOutputDirection) * (1.0 - cosTheta);

                    return bilinearCubeUV(envMap, sampleDirection, mipInt);
                }

                void main() {
                    vec3 axis = latitudinal ? poleAxis : cross(poleAxis, vOutputDirection);

                    if (all(equal(axis, vec3(0.0)))) {
                        axis = vec3(vOutputDirection.z, 0.0, -vOutputDirection.x);
                    }

                    axis = normalize(axis);

                    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
                    gl_FragColor.rgb += weights[0] * getSample(0.0, axis);

                    for (int i = 1; i < n; i++) {
                        if (i >= samples) {
                            break;
                        }

                        float theta = dTheta * float(i);
                        gl_FragColor.rgb += weights[i] * getSample(-1.0 * theta, axis);
                        gl_FragColor.rgb += weights[i] * getSample(theta, axis);
                    }
                }
            `
        ),
        {
            'envMap': { value: null },
            'samples': { value: 1 },
            'weights': { value: weights },
            'latitudinal': { value: false },
            'dTheta': { value: 0 },
            'mipInt': { value: 0 },
            'poleAxis': { value: poleAxis }
        }
    );

    shaderMaterial.defines = {
        'n': MAX_SAMPLES,
        'CUBEUV_TEXEL_WIDTH': 1.0 / width,
        'CUBEUV_TEXEL_HEIGHT': 1.0 / height,
        'CUBEUV_MAX_MIP': lodMax + ".0"
    };

    shaderMaterial.blending = Context3D.NONE;
    shaderMaterial.depthTest = false;
    shaderMaterial.depthWrite = false;

    return shaderMaterial;
}

private static function _getEquirectMaterial():ShaderMaterial {
    return new ShaderMaterial(
        new DefaultShader(
            _getCommonVertexShader(),
            /* glsl */`
                precision mediump float;
                precision mediump int;

                varying vec3 vOutputDirection;

                uniform sampler2D envMap;

                #include <common>

                void main() {
                    vec3 outputDirection = normalize(vOutputDirection);
                    vec2 uv = equirectUv(outputDirection);

                    gl_FragColor = vec4(texture2D(envMap, uv).rgb, 1.0);
                }
            `
        ),
        {
            'envMap': { value: null }
        }
    );
}

private static function _getCubemapMaterial():ShaderMaterial {
    return new ShaderMaterial(
        new DefaultShader(
            _getCommonVertexShader(),
            /* glsl */`
                precision mediump float;
                precision mediump int;

                uniform float flipEnvMap;

                varying vec3 vOutputDirection;

                uniform samplerCube envMap;

                void main() {
                    gl_FragColor = textureCube(envMap, vec3(flipEnvMap * vOutputDirection.x, vOutputDirection.yz));
                }
            `
        ),
        {
            'envMap': { value: null },
            'flipEnvMap': { value: -1 }
        }
    );
}

private static function _getCommonVertexShader():String {
    return /* glsl */`
        precision mediump float;
        precision mediump int;

        attribute float faceIndex;

        varying vec3 vOutputDirection;

        // RH coordinate system; PMREM face-indexing convention
        vec3 getDirection(vec2 uv, float face) {
            uv = 2.0 * uv - 1.0;

            vec3 direction = vec3(uv, 1.0);

            if (face == 0.0) {
                direction = direction.zyx; // ( 1, v, u ) pos x
            } else if (face == 1.0) {
                direction = direction.xzy;
                direction.xz *= -1.0; // ( -u, 1, -v ) pos y
            } else if (face == 2.0) {
                direction.x *= -1.0; // ( -u, v, 1 ) pos z
            } else if (face == 3.0) {
                direction = direction.zyx;
                direction.xz *= -1.0; // ( -1, v, -u ) neg x
            } else if (face == 4.0) {
                direction = direction.xzy;
                direction.xy *= -1.0; // ( -u, -1, v ) neg y
            } else if (face == 5.0) {
                direction.z *= -1.0; // ( u, v, -1 ) neg z
            }

            return direction;
        }

        void main() {
            vOutputDirection = getDirection(uv, faceIndex);
            gl_Position = vec4(position, 1.0);
        }
    `;
}