package three.js.examples.jsm.utils;

import three.core.objects.Mesh;
import three.core.objects.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.materials.Uniform;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.textures.CanvasTexture;
import three.textures.Texture;
import three.cameras.PerspectiveCamera;
import three.constants.SRGBColorSpace;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.Browser;

class TextureUtils {
    private static var _renderer:WebGLRenderer;
    private static var fullscreenQuadGeometry:PlaneGeometry;
    private static var fullscreenQuadMaterial:ShaderMaterial;
    private static var fullscreenQuad:Mesh;

    public static function decompress(texture:Texture, maxTextureSize:Int = Int.POSITIVE_INFINITY, renderer:WebGLRenderer = null):CanvasTexture {
        if (fullscreenQuadGeometry == null) fullscreenQuadGeometry = new PlaneGeometry(2, 2, 1, 1);
        if (fullscreenQuadMaterial == null) {
            var uniforms = js.Boot.typedMap(Dynamic, Dynamic);
            uniforms["blitTexture"] = new Uniform(texture);

            fullscreenQuadMaterial = new ShaderMaterial(js.Boot.typedMap(String, Dynamic)
                ..["uniforms"] = uniforms
                ..["vertexShader"] = "varying vec2 vUv;void main(){vUv = uv;gl_Position = vec4(position.xy * 1.0,0.,.999999);}"
                ..["fragmentShader"] = "uniform sampler2D blitTexture;varying vec2 vUv;void main(){#ifdef IS_SRGB gl_FragColor = LinearTosRGB( texture2D( blitTexture, vUv) );#else gl_FragColor = texture2D( blitTexture, vUv);#endif}"
            );
        }

        fullscreenQuadMaterial.uniforms["blitTexture"].value = texture;
        fullscreenQuadMaterial.defines["IS_SRGB"] = texture.colorSpace == SRGBColorSpace;
        fullscreenQuadMaterial.needsUpdate = true;

        if (fullscreenQuad == null) {
            fullscreenQuad = new Mesh(fullscreenQuadGeometry, fullscreenQuadMaterial);
            fullscreenQuad.frustumCulled = false;
        }

        var _camera = new PerspectiveCamera();
        var _scene = new Scene();
        _scene.add(fullscreenQuad);

        if (renderer == null) {
            renderer = _renderer = new WebGLRenderer(js.Boot.typedMap(String, Dynamic)..["antialias"] = false);
        }

        var width = Math.min(texture.image.width, maxTextureSize);
        var height = Math.min(texture.image.height, maxTextureSize);

        renderer.setSize(width, height);
        renderer.clear();
        renderer.render(_scene, _camera);

        var canvas:CanvasElement = Browser.document.createElement("canvas").cast();
        var context:CanvasRenderingContext2D = canvas.getContext("2d").cast();

        canvas.width = width;
        canvas.height = height;

        context.drawImage(renderer.domElement, 0, 0, width, height);

        var readableTexture = new CanvasTexture(canvas);

        readableTexture.minFilter = texture.minFilter;
        readableTexture.magFilter = texture.magFilter;
        readableTexture.wrapS = texture.wrapS;
        readableTexture.wrapT = texture.wrapT;
        readableTexture.name = texture.name;

        if (_renderer != null) {
            _renderer.forceContextLoss();
            _renderer.dispose();
            _renderer = null;
        }

        return readableTexture;
    }
}