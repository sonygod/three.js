import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderer;
import three.RenderTarget;
import three.Texture;
import three.FullScreenQuad;
import three.Shader;
import three.Pass;

class TexturePass extends Pass {

    public var map:Texture;
    public var opacity:Float;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(map:Texture, opacity:Float = 1.0) {
        super();

        this.map = map;
        this.opacity = opacity;

        this.uniforms = UniformsUtils.clone(CopyShader.uniforms);

        this.material = new ShaderMaterial({
            uniforms: this.uniforms,
            vertexShader: CopyShader.vertexShader,
            fragmentShader: CopyShader.fragmentShader,
            depthTest: false,
            depthWrite: false,
            premultipliedAlpha: true
        });

        this.needsSwap = false;

        this.fsQuad = new FullScreenQuad(null);
    }

    public function render(renderer:WebGLRenderer, writeBuffer:RenderTarget, readBuffer:RenderTarget) {
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;

        this.fsQuad.material = this.material;

        this.uniforms["opacity"].value = this.opacity;
        this.uniforms["tDiffuse"].value = this.map;
        this.material.transparent = (this.opacity < 1.0);

        renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);
        if (this.clear) renderer.clear();
        this.fsQuad.render(renderer);

        renderer.autoClear = oldAutoClear;
    }

    public function dispose() {
        this.material.dispose();
        this.fsQuad.dispose();
    }
}

class CopyShader extends Shader {

    public static var uniforms:Dynamic = {
        "tDiffuse": { value: null },
        "opacity": { value: 1.0 }
    };

    public static var vertexShader:String = "
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ";

    public static var fragmentShader:String = "
        uniform sampler2D tDiffuse;
        uniform float opacity;
        varying vec2 vUv;
        void main() {
            gl_FragColor = texture2D( tDiffuse, vUv ) * opacity;
        }
    ";
}