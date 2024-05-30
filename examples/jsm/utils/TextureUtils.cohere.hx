import js.three.WebGLRenderer;
import js.three.PerspectiveCamera;
import js.three.Scene;
import js.three.PlaneGeometry;
import js.three.ShaderMaterial;
import js.three.Uniform;
import js.three.Mesh;
import js.three.CanvasTexture;
import js.three.ColorSpace;

var _renderer:WebGLRenderer;
var fullscreenQuadGeometry:PlaneGeometry;
var fullscreenQuadMaterial:ShaderMaterial;
var fullscreenQuad:Mesh;

function decompress(texture:CanvasTexture, maxTextureSize:Int = Int.MaxValue, ?renderer:WebGLRenderer) -> CanvasTexture {
    if (fullscreenQuadGeometry == null) {
        fullscreenQuadGeometry = new PlaneGeometry(2.0, 2.0, 1, 1);
    }
    if (fullscreenQuadMaterial == null) {
        fullscreenQuadMaterial = new ShaderMaterial({
            uniforms: {
                blitTexture: new Uniform(texture)
            },
            vertexShader: "
                varying vec2 vUv;
                void main(){
                    vUv = uv;
                    gl_Position = vec4(position.xy * 1.0,0.,0.999999);
                }
            ",
            fragmentShader: "
                uniform sampler2D blitTexture;
                varying vec2 vUv;
                void main(){
                    gl_FragColor = vec4(vUv.xy, 0, 1);
                    #ifdef IS_SRGB
                    gl_FragColor = LinearTosRGB(texture2D(blitTexture, vUv));
                    #else
                    gl_FragColor = texture2D(blitTexture, vUv);
                    #endif
                }
            "
        });
    }

    fullscreenQuadMaterial.uniforms.blitTexture.value = texture;
    fullscreenQuadMaterial.defines.IS_SRGB = texture.colorSpace == ColorSpace.SRGB;
    fullscreenQuadMaterial.needsUpdate = true;

    if (fullscreenQuad == null) {
        fullscreenQuad = new Mesh(fullscreenQuadGeometry, fullscreenQuadMaterial);
        fullscreenQuad.frustumCulled = false;
    }

    var _camera = new PerspectiveCamera();
    var _scene = new Scene();
    _scene.add(fullscreenQuad);

    if (renderer == null) {
        renderer = _renderer = new WebGLRenderer({ antialias: false });
    }

    var width = min(texture.image.width, maxTextureSize);
    var height = min(texture.image.height, maxTextureSize);

    renderer.setSize(width, height);
    renderer.clear();
    renderer.render(_scene, _camera);

    var canvas = new js.html.CanvasElement();
    var context = canvas.getContext2d();

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