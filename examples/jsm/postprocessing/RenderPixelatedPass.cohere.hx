import js.three.WebGLRenderTarget;
import js.three.MeshNormalMaterial;
import js.three.ShaderMaterial;
import js.three.Vector2;
import js.three.Vector4;
import js.three.DepthTexture;
import js.three.NearestFilter;
import js.three.HalfFloatType;
import js.three.Pass;
import js.three.FullScreenQuad;

class RenderPixelatedPass extends Pass {
    var pixelSize:Float;
    var resolution:Vector2;
    var renderResolution:Vector2;
    var pixelatedMaterial:ShaderMaterial;
    var normalMaterial:MeshNormalMaterial;
    var fsQuad:FullScreenQuad;
    var scene:Dynamic;
    var camera:Dynamic;
    var normalEdgeStrength:Float;
    var depthEdgeStrength:Float;
    var beautyRenderTarget:WebGLRenderTarget;
    var normalRenderTarget:WebGLRenderTarget;

    public function new(pixelSize:Float, scene:Dynamic, camera:Dynamic, ?options) {
        super();
        this.pixelSize = pixelSize;
        this.resolution = new Vector2();
        this.renderResolution = new Vector2();
        this.pixelatedMaterial = this.createPixelatedMaterial();
        this.normalMaterial = new MeshNormalMaterial();
        this.fsQuad = new FullScreenQuad(this.pixelatedMaterial);
        this.scene = scene;
        this.camera = camera;
        this.normalEdgeStrength = options?.normalEdgeStrength ?? 0.3;
        this.depthEdgeStrength = options?.depthEdgeStrength ?? 0.4;
        this.beautyRenderTarget = new WebGLRenderTarget();
        this.beautyRenderTarget.texture.minFilter = NearestFilter.new();
        this.beautyRenderTarget.texture.magFilter = NearestFilter.new();
        this.beautyRenderTarget.texture.type = HalfFloatType.new();
        this.beautyRenderTarget.depthTexture = new DepthTexture();
        this.normalRenderTarget = new WebGLRenderTarget();
        this.normalRenderTarget.texture.minFilter = NearestFilter.new();
        this.normalRenderTarget.texture.magFilter = NearestFilter.new();
        this.normalRenderTarget.texture.type = HalfFloatType.new();
    }

    public function dispose() {
        this.beautyRenderTarget.dispose();
        this.normalRenderTarget.dispose();
        this.pixelatedMaterial.dispose();
        this.normalMaterial.dispose();
        this.fsQuad.dispose();
    }

    public function setSize(width:Int, height:Int) {
        this.resolution.set(width, height);
        this.renderResolution.set(Std.int(width / this.pixelSize), Std.int(height / this.pixelSize));
        var x = this.renderResolution.x;
        var y = this.renderResolution.y;
        this.beautyRenderTarget.setSize(x, y);
        this.normalRenderTarget.setSize(x, y);
        this.fsQuad.material.uniforms.resolution.value.set(x, y, 1 / x, 1 / y);
    }

    public function setPixelSize(pixelSize:Float) {
        this.pixelSize = pixelSize;
        this.setSize(this.resolution.x, this.resolution.y);
    }

    public function render(renderer, writeBuffer) {
        var uniforms = this.fsQuad.material.uniforms;
        uniforms.normalEdgeStrength.value = this.normalEdgeStrength;
        uniforms.depthEdgeStrength.value = this.depthEdgeStrength;
        renderer.setRenderTarget(this.beautyRenderTarget);
        renderer.render(this.scene, this.camera);
        var overrideMaterial_old = this.scene.overrideMaterial;
        renderer.setRenderTarget(this.normalRenderTarget);
        this.scene.overrideMaterial = this.normalMaterial;
        renderer.render(this.scene, this.camera);
        this.scene.overrideMaterial = overrideMaterial_old;
        uniforms.tDiffuse.value = this.beautyRenderTarget.texture;
        uniforms.tDepth.value = this.beautyRenderTarget.depthTexture;
        uniforms.tNormal.value = this.normalRenderTarget.texture;
        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) {
                renderer.clear();
            }
        }
        this.fsQuad.render(renderer);
    }

    function createPixelatedMaterial():ShaderMaterial {
        return new ShaderMaterial({
            uniforms: {
                tDiffuse: { value: null },
                tDepth: { value: null },
                tNormal: { value: null },
                resolution: {
                    value: new Vector4(
                        this.renderResolution.x,
                        this.renderResolution.y,
                        1 / this.renderResolution.x,
                        1 / this.renderResolution.y
                    )
                },
                normalEdgeStrength: { value: 0 },
                depthEdgeStrength: { value: 0 }
            },
            vertexShader: /* glsl */`
                varying vec2 vUv;

                void main() {

                    vUv = uv;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

                }
            `,
            fragmentShader: /* glsl */`
                uniform sampler2D tDiffuse;
                uniform sampler2D tDepth;
                uniform sampler2D tNormal;
                uniform vec4 resolution;
                uniform float normalEdgeStrength;
                uniform float depthEdgeStrength;
                varying vec2 vUv;

                float getDepth(int x, int y) {

                    return texture2D( tDepth, vUv + vec2(x, y) * resolution.zw ).r;

                }

                vec3 getNormal(int x, int y) {

                    return texture2D( tNormal, vUv + vec2(x, y) * resolution.zw ).rgb * 2.0 - 1.0;

                }

                float depthEdgeIndicator(float depth, vec3 normal) {

                    float diff = 0.0;
                    diff += clamp(getDepth(1, 0) - depth, 0.0, 1.0);
                    diff += clamp(getDepth(-1, 0) - depth, 0.0, 1.0);
                    diff += clamp(getDepth(0, 1) - depth, 0.0, 1.0);
                    diff += clamp(getDepth(0, -1) - depth, 0.0, 1.0);
                    return floor(smoothstep(0.01, 0.02, diff) * 2.) / 2.;

                }

                float neighborNormalEdgeIndicator(int x, int y, float depth, vec3 normal) {

                    float depthDiff = getDepth(x, y) - depth;
                    vec3 neighborNormal = getNormal(x, y);

                    // Edge pixels should yield to faces who's normals are closer to the bias normal.
                    vec3 normalEdgeBias = vec3(1., 1., 1.); // This should probably be a parameter.
                    float normalDiff = dot(normal - neighborNormal, normalEdgeBias);
                    float normalIndicator = clamp(smoothstep(-.01, .01, normalDiff), 0.0, 1.0);

                    // Only the shallower pixel should detect the normal edge.
                    float depthIndicator = clamp(sign(depthDiff * .25 + .0025), 0.0, 1.0);

                    return (1.0 - dot(normal, neighborNormal)) * depthIndicator * normalIndicator;

                }

                float normalEdgeIndicator(float depth, vec3 normal) {

                    float indicator = 0.0;

                    indicator += neighborNormalEdgeIndicator(0, -1, depth, normal);
                    indicator += neighborNormalEdgeIndicator(0, 1, depth, normal);
                    indicator += neighborNormalEdgeIndicator(-1, 0, depth, normal);
                    indicator += neighborNormalEdgeIndicator(1, 0, depth, normal);

                    return step(0.1, indicator);

                }

                void main() {

                    vec4 texel = texture2D( tDiffuse, vUv );

                    float depth = 0.0;
                    vec3 normal = vec3(0.0);

                    if (depthEdgeStrength > 0.0 || normalEdgeStrength > 0.0) {

                        depth = getDepth(0, 0);
                        normal = getNormal(0, 0);

                    }

                    float dei = 0.0;
                    if (depthEdgeStrength > 0.0)
                        dei = depthEdgeIndicator(depth, normal);

                    float nei = 0.0;
                    if (normalEdgeStrength > 0.0)
                        nei = normalEdgeIndicator(depth, normal);

                    float Strength = dei > 0.0 ? (1.0 - depthEdgeStrength * dei) : (1.0 + normalEdgeStrength * nei);

                    gl_FragColor = texel * Strength;

                }
            `
        });
    }
}