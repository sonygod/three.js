import three.Color;
import three.Matrix4;
import three.Mesh;
import three.PerspectiveCamera;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.Vector2;
import three.Vector3;
import three.WebGLRenderTarget;
import three.DepthTexture;
import three.UnsignedShortType;
import three.NearestFilter;
import three.Plane;
import three.HalfFloatType;

class ReflectorForSSRPass extends Mesh {

    public var isReflectorForSSRPass:Bool;
    private var _color:Color;
    private var _maxDistance:Float;
    private var _opacity:Float;
    private var _resolution:Vector2;
    private var _distanceAttenuation:Bool;
    private var _fresnel:Bool;
    private var _renderTarget:WebGLRenderTarget;
    private var _material:ShaderMaterial;
    private var _doRender:Function;
    private var _getRenderTarget:Function;

    public function new(geometry:Geometry, ?options) {
        if (options == null) options = {};
        super(geometry);

        this.isReflectorForSSRPass = true;

        this.type = 'ReflectorForSSRPass';

        this._color = (options.hasOwnProperty('color')) ? new Color(options.color) : new Color(0x7F7F7F);
        var textureWidth:Int = options.hasOwnProperty('textureWidth') ? options.textureWidth : 512;
        var textureHeight:Int = options.hasOwnProperty('textureHeight') ? options.textureHeight : 512;
        var clipBias:Float = options.hasOwnProperty('clipBias') ? options.clipBys : 0;
        var shader:Object = options.hasOwnProperty('shader') ? options.shader : ReflectorForSSRPass.ReflectorShader;
        var useDepthTexture:Bool = options.hasOwnProperty('useDepthTexture') ? options.useDepthTexture : false;
        var yAxis:Vector3 = new Vector3(0, 1, 0);
        var vecTemp0:Vector3 = new Vector3();
        var vecTemp1:Vector3 = new Vector3();

        this._maxDistance = ReflectorForSSRPass.ReflectorShader.uniforms.maxDistance.value;
        this._opacity = ReflectorForSSRPass.ReflectorShader.uniforms.opacity.value;
        this._resolution = options.hasOwnProperty('resolution') ? options.resolution : new Vector2(js.Browser.document.window.innerWidth, js.Browser.document.window.innerHeight);

        this._distanceAttenuation = ReflectorForSSRPass.ReflectorShader.defines.DISTANCE_ATTENUATION;
        this._fresnel = ReflectorForSSRPass.ReflectorShader.defines.FRESNEL;

        var normal:Vector3 = new Vector3();
        var reflectorWorldPosition:Vector3 = new Vector3();
        var cameraWorldPosition:Vector3 = new Vector3();
        var rotationMatrix:Matrix4 = new Matrix4();
        var lookAtPosition:Vector3 = new Vector3(0, 0, -1);

        var view:Vector3 = new Vector3();
        var target:Vector3 = new Vector3();

        var textureMatrix:Matrix4 = new Matrix4();
        var virtualCamera:PerspectiveCamera = new PerspectiveCamera();

        var depthTexture:DepthTexture;

        if (useDepthTexture) {
            depthTexture = new DepthTexture();
            depthTexture.type = UnsignedShortType;
            depthTexture.minFilter = NearestFilter;
            depthTexture.magFilter = NearestFilter;
        }

        var parameters:Object = {
            depthTexture: useDepthTexture ? depthTexture : null,
            type: HalfFloatType
        };

        this._renderTarget = new WebGLRenderTarget(textureWidth, textureHeight, parameters);

        this._material = new ShaderMaterial({
            name: (shader.hasOwnProperty('name')) ? shader.name : 'unspecified',
            transparent: useDepthTexture,
            defines: {...ReflectorForSSRPass.ReflectorShader.defines, useDepthTexture},
            uniforms: UniformsUtils.clone(shader.uniforms),
            fragmentShader: shader.fragmentShader,
            vertexShader: shader.vertexShader
        });

        this._material.uniforms['tDiffuse'].value = this._renderTarget.texture;
        this._material.uniforms['color'].value = this._color;
        this._material.uniforms['textureMatrix'].value = textureMatrix;
        if (useDepthTexture) {
            this._material.uniforms['tDepth'].value = this._renderTarget.depthTexture;
        }

        this.material = this._material;

        var globalPlane:Plane = new Plane(new Vector3(0, 1, 0), clipBias);
        var globalPlanes:Array<Plane> = [globalPlane];

        this._doRender = function(renderer:WebGLRenderer, scene:Scene, camera:Camera) {
            // ... rest of the function
        };

        this._getRenderTarget = function() {
            return this._renderTarget;
        };
    }

    static public var ReflectorShader:Object = {
        // ... rest of the object
    };

    public function doRender(renderer:WebGLRenderer, scene:Scene, camera:Camera) {
        this._doRender(renderer, scene, camera);
    }

    public function getRenderTarget() {
        return this._getRenderTarget();
    }

    // ... getters and setters for private variables

}