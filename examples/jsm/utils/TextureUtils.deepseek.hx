import three.PlaneGeometry;
import three.ShaderMaterial;
import three.Uniform;
import three.Mesh;
import three.PerspectiveCamera;
import three.Scene;
import three.WebGLRenderer;
import three.CanvasTexture;
import three.SRGBColorSpace;

var _renderer:WebGLRenderer;
var fullscreenQuadGeometry:PlaneGeometry;
var fullscreenQuadMaterial:ShaderMaterial;
var fullscreenQuad:Mesh;

public function decompress(texture:Dynamic, maxTextureSize:Float = Infinity, renderer:WebGLRenderer = null):CanvasTexture {

	if (fullscreenQuadGeometry == null) fullscreenQuadGeometry = new PlaneGeometry(2, 2, 1, 1);
	if (fullscreenQuadMaterial == null) fullscreenQuadMaterial = new ShaderMaterial({
		uniforms: { blitTexture: new Uniform(texture) },
		vertexShader: `
			varying vec2 vUv;
			void main(){
				vUv = uv;
				gl_Position = vec4(position.xy * 1.0,0.,.999999);
			}`,
		fragmentShader: `
			uniform sampler2D blitTexture; 
			varying vec2 vUv;

			void main(){ 
				gl_FragColor = vec4(vUv.xy, 0, 1);
				
				#ifdef IS_SRGB
				gl_FragColor = LinearTosRGB( texture2D( blitTexture, vUv) );
				#else
				gl_FragColor = texture2D( blitTexture, vUv);
				#endif
			}`
	});

	fullscreenQuadMaterial.uniforms.blitTexture.value = texture;
	fullscreenQuadMaterial.defines.IS_SRGB = texture.colorSpace == SRGBColorSpace;
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

	var width = Math.min(texture.image.width, maxTextureSize);
	var height = Math.min(texture.image.height, maxTextureSize);

	renderer.setSize(width, height);
	renderer.clear();
	renderer.render(_scene, _camera);

	var canvas = js.Browser.document.createElement('canvas');
	var context = canvas.getContext('2d');

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