import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import three.DoubleSide;
import three.LinearFilter;
import three.Mesh;
import three.MeshBasicMaterial;
import three.OrthographicCamera;
import three.PlaneGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Texture;
import three.UniformsUtils;
import three.Uniform;
import three.Vector2;
import three.Vector3;
import UnpackDepthRGBAShader;

class ShadowMapViewer {
  private var _enabled:Bool;
  private var _size:Vector2;
  private var _position:Vector2;
  private var _light:three.Light;
  private var _camera:OrthographicCamera;
  private var _scene:Scene;
  private var _uniforms:haxe.ds.StringMap<Uniform>;
  private var _material:ShaderMaterial;
  private var _mesh:Mesh;
  private var _labelCanvas:CanvasElement;
  private var _labelMesh:Mesh;

  public function new(light:three.Light) {
    _light = light;
    _enabled = true;
    _size = new Vector2(256, 256);
    _position = new Vector2(10, 10);

    _camera = new OrthographicCamera(-window.innerWidth / 2, window.innerWidth / 2, window.innerHeight / 2, -window.innerHeight / 2, 1, 10);
    _camera.position.set(0, 0, 2);
    _scene = new Scene();

    var shader = UnpackDepthRGBAShader.getInstance();
    _uniforms = UniformsUtils.clone(shader.uniforms);
    _material = new ShaderMaterial(new haxe.ds.StringMap<Dynamic>([
      "uniforms", _uniforms,
      "vertexShader", shader.vertexShader,
      "fragmentShader", shader.fragmentShader
    ]));

    var plane = new PlaneGeometry(_size.x, _size.y);
    _mesh = new Mesh(plane, _material);
    _scene.add(_mesh);

    if (_light.name != null && _light.name != "") {
      _labelCanvas = js.html.CanvasElement.create();
      var context = _labelCanvas.getContext("2d");
      context.font = "Bold 20px Arial";

      var labelWidth = context.measureText(_light.name).width;
      _labelCanvas.width = labelWidth;
      _labelCanvas.height = 25;

      context.font = "Bold 20px Arial";
      context.fillStyle = "rgba(255, 0, 0, 1)";
      context.fillText(_light.name, 0, 20);

      var labelTexture = new Texture(_labelCanvas);
      labelTexture.magFilter = LinearFilter;
      labelTexture.minFilter = LinearFilter;
      labelTexture.needsUpdate = true;

      var labelMaterial = new MeshBasicMaterial(new haxe.ds.StringMap<Dynamic>([
        "map", labelTexture,
        "side", DoubleSide
      ]));
      labelMaterial.transparent = true;

      var labelPlane = new PlaneGeometry(_labelCanvas.width, _labelCanvas.height);
      _labelMesh = new Mesh(labelPlane, labelMaterial);
      _scene.add(_labelMesh);
    }

    update();
  }

  public function get enabled():Bool {
    return _enabled;
  }

  public function set enabled(value:Bool) {
    _enabled = value;
  }

  public function get size():Vector2 {
    return _size;
  }

  public function set size(value:Vector2) {
    _size = value;
    _mesh.scale.set(_size.x / 256, _size.y / 256, 1);
    updatePosition();
  }

  public function get position():Vector2 {
    return _position;
  }

  public function set position(value:Vector2) {
    _position = value;
    updatePosition();
  }

  private function updatePosition():Void {
    _mesh.position.set(-window.innerWidth / 2 + _size.x / 2 + _position.x, window.innerHeight / 2 - _size.y / 2 - _position.y, 0);
    if (_labelMesh != null) _labelMesh.position.set(_mesh.position.x, _mesh.position.y - _size.y / 2 + _labelCanvas.height / 2, 0);
  }

  public function render(renderer:three.WebGLRenderer):Void {
    if (_enabled) {
      _uniforms.get("tDiffuse").value = _light.shadow.map.texture;
      var userAutoClearSetting = renderer.autoClear;
      renderer.autoClear = false;
      renderer.clearDepth();
      renderer.render(_scene, _camera);
      renderer.autoClear = userAutoClearSetting;
    }
  }

  public function updateForWindowResize():Void {
    if (_enabled) {
      _camera.left = window.innerWidth / -2;
      _camera.right = window.innerWidth / 2;
      _camera.top = window.innerHeight / 2;
      _camera.bottom = window.innerHeight / -2;
      _camera.updateProjectionMatrix();
      update();
    }
  }

  public function update():Void {
    updatePosition();
    _mesh.scale.set(_size.x / 256, _size.y / 256, 1);
  }
}