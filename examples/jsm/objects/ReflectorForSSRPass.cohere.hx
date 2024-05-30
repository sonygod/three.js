import h3d.Matrix4;
import h3d.Mesh;
import h3d.PerspectiveCamera;
import h3d.ShaderMaterial;
import h3d.Vector2;
import h3d.Vector3;
import h3d.WebGLRenderTarget;

class ReflectorForSSRPass extends Mesh {
    public var isReflectorForSSRPass:Bool;
    public var type:String;
    private var scope:ReflectorForSSRPass;
    private var color:Color;
    private var textureWidth:Int;
    private var textureHeight:Int;
    private var clipBias:Float;
    private var shader:ShaderMaterial;
    private var useDepthTexture:Bool;
    private var yAxis:Vector3;
    private var vecTemp0:Vector3;
    private var vecTemp1:Vector3;
    private var needsUpdate:Bool;
    public var maxDistance:Float;
    public var opacity:Float;
    public var resolution:Vector2;
    private var _distanceAttenuation:Bool;
    public var distanceAttenuation:Bool;
    private var _fresnel:Bool;
    public var fresnel:Bool;
    private var normal:Vector3;
    private var reflectorWorldPosition:Vector3;
    private var cameraWorldPosition:Vector3;
    private var rotationMatrix:Matrix4;
    private var lookAtPosition:Vector3;
    private var view:Vector3;
    private var target:Vector3;
    private var textureMatrix:Matrix4;
    private var virtualCamera:PerspectiveCamera;
    private var depthTexture:DepthTexture;
    private var parameters:Dynamic;
    private var renderTarget:WebGLRenderTarget;
    private var material:ShaderMaterial;
    private var globalPlane:Plane;
    private var globalPlanes:Array<Plane>;

    public function new(geometry:Geometry, options:Dynamic) {
        super(geometry);
        this.isReflectorForSSRPass = true;
        this.type = 'ReflectorForSSRPass';
        scope = this;
        color = options.color != null ? new Color(options.color) : new Color(0x7F7F7F);
        textureWidth = options.textureWidth.default(512);
        textureHeight = options.textureHeight.default(512);
        clipBias = options.clipBias.default(0);
        shader = options.shader.default(ReflectorForSSRPass.ReflectorShader);
        useDepthTexture = options.useDepthTexture.default(true);
        yAxis = new Vector3(0, 1, 0);
        vecTemp0 = new Vector3();
        vecTemp1 = new Vector3();
        needsUpdate = false;
        maxDistance = ReflectorForSSRPass.ReflectorShader.uniforms.maxDistance.value;
        opacity = ReflectorForSSRPass.ReflectorShader.uniforms.opacity.value;
        resolution = options.resolution.default(new Vector2(window.innerWidth, window.innerHeight));
        _distanceAttenuation = ReflectorForSSRPass.ReflectorShader.defines.DISTANCE_ATTENUATION;
        _fresnel = ReflectorForSSRPass.ReflectorShader.defines.FRESNEL;
        normal = new Vector3();
        reflectorWorldPosition = new Vector3();
        cameraWorldPosition = new Vector3();
        rotationMatrix = new Matrix4();
        lookAtPosition = new Vector3(0, 0, -1);
        view = new Vector3();
        target = new Vector3();
        textureMatrix = new Matrix4();
        virtualCamera = new PerspectiveCamera();
        if (useDepthTexture) {
            depthTexture = new DepthTexture();
            depthTexture.type = UnsignedShortType.UNSIGNED_SHORT;
            depthTexture.minFilter = NearestFilter.NEAREST;
            depthTexture.magFilter = NearestFilter.NEAREST;
        }
        parameters = {
            depthTexture: useDepthTexture ? depthTexture : null,
            type: HalfFloatType.HALF_FLOAT
        };
        renderTarget = new WebGLRenderTarget(textureWidth, textureHeight, parameters);
        material = new ShaderMaterial({
            name: shader.name != null ? shader.name : 'unspecified',
            transparent: useDepthTexture,
            defines: $merge(ReflectorForSSRPass.ReflectorShader.defines, {
                useDepthTexture: useDepthTexture
            }),
            uniforms: UniformsUtils.clone(shader.uniforms),
            fragmentShader: shader.fragmentShader,
            vertexShader: shader.vertexShader
        });
        material.uniforms['tDiffuse'].value = renderTarget.texture;
        material.uniforms['color'].value = scope.color;
        material.uniforms['textureMatrix'].value = textureMatrix;
        if (useDepthTexture) {
            material.uniforms['tDepth'].value = renderTarget.depthTexture;
        }
        this.material = material;
        globalPlane = new Plane(new Vector3(0, 1, 0), clipBias);
        globalPlanes = [globalPlane];
    }

    public function doRender(renderer:Renderer, scene:Scene, camera:Camera) {
        material.uniforms['maxDistance'].value = scope.maxDistance;
        material.uniforms['color'].value = scope.color;
        material.uniforms['opacity'].value = scope.opacity;
        vecTemp0.copy(camera.position).normalize();
        vecTemp1.copy(vecTemp0).reflect(yAxis);
        material.uniforms['fresnelCoe'].value = (vecTemp0.dot(vecTemp1) + 1) / 2;
        reflectorWorldPosition.setFromMatrixPosition(scope.matrixWorld);
        cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);
        rotationMatrix.extractRotation(scope.matrixWorld);
        normal.set(0, 0, 1);
        normal.applyMatrix4(rotationMatrix);
        view.subVectors(reflectorWorldPosition, cameraWorldPosition);
        if (view.dot(normal) > 0) return;
        view.reflect(normal).negate();
        view.add(reflectorWorldPosition);
        rotationMatrix.extractRotation(camera.matrixWorld);
        lookAtPosition.set(0, 0, -1);
        lookAtPosition.applyMatrix4(rotationMatrix);
        lookAtPosition.add(cameraWorldPosition);
        target.subVectors(reflectorWorldPosition, lookAtPosition);
        target.reflect(normal).negate();
        target.add(reflectorWorldPosition);
        virtualCamera.position.copy(view);
        virtualCamera.up.set(0, 1, 0);
        virtualCamera.up.applyMatrix4(rotationMatrix);
        virtualCamera.up.reflect(normal);
        virtualCamera.lookAt(target);
        virtualCamera.far = camera.far;
        virtualCamera.updateMatrixWorld();
        virtualCamera.projectionMatrix.copy(camera.projectionMatrix);
        material.uniforms['virtualCameraNear'].value = camera.near;
        material.uniforms['virtualCameraFar'].value = camera.far;
        material.uniforms['virtualCameraMatrixWorld'].value = virtualCamera.matrixWorld;
        material.uniforms['virtualCameraProjectionMatrix'].value = camera.projectionMatrix;
        material.uniforms['virtualCameraProjectionMatrixInverse'].value = camera.projectionMatrixInverse;
        material.uniforms['resolution'].value = scope.resolution;
        textureMatrix.set(
            0.5, 0.0, 0.0, 0.5,
            0.0, 0.5, 0.0, 0.5,
            0.0, 0.0, 0.5, 0.5,
            0.0, 0.0, 0.0, 1.0
        );
        textureMatrix.multiply(virtualCamera.projectionMatrix);
        textureMatrix.multiply(virtualCamera.matrixWorldInverse);
        textureMatrix.multiply(scope.matrixWorld);
        renderer.setRenderTarget(renderTarget);
        renderer.state.buffers.depth.setMask(true);
        if (renderer.autoClear == false) renderer.clear();
        renderer.render(scene, virtualCamera);
        renderer.setRenderTarget(renderer.getRenderTarget());
    }

    public function getRenderTarget():WebGLRenderTarget {
        return renderTarget;
    }
}

class ReflectorForSSRPass {
    static public var ReflectorShader:Dynamic;
}

class Color {
    public function new(value:Dynamic) {}
}

class DepthTexture {
    public var type:UnsignedShortType;
    public var minFilter:NearestFilter;
    public var magFilter:NearestFilter;
}

class UnsignedShortType {
    static public var UNSIGNED_SHORT:UnsignedShortType;
}

class NearestFilter {
    static public var NEAREST:NearestFilter;
}

class Plane {
    public function new(normal:Vector3, constant:Float) {}
}

class Vector3 {
    public function new(x:Float, y:Float, z:Float) {}
    public function set(x:Float, y:Float, z:Float):Vector3 {}
    public function copy(v:Vector3):Vector3 {}
    public function normalize():Vector3 {}
    public function reflect(normal:Vector3):Vector3 {}
    public function applyMatrix4(m:Matrix4):Vector3 {}
    public function negate():Vector3 {}
    public function add(v:Vector3):Vector3 {}
    public function subVectors(a:Vector3, b:Vector3):Vector3 {}
}

class Matrix4 {
    public function new(
        n11:Float, n12:Float, n13:Float, n14:Float,
        n21:Float, n22:Float, n23:Float, n24:Float,
        n31:Float, n32:Float, n33:Float, n34:Float,
        n41:Float, n42:Float, n43:Float, n44:Float
    ) {}
    public function extractRotation(m:Matrix4):Matrix4 {}
    public function multiply(m:Matrix4):Matrix4 {}
}

class PerspectiveCamera {
    public var position:Vector3;
    public var up:Vector3;
    public var far:Float;
    public var projectionMatrix:Matrix4;
    public var matrixWorldInverse:Matrix4;
    public function new() {}
    public function updateMatrixWorld():Void {}
    public function lookAt(target:Vector3):Void {}
}

class ShaderMaterial {
    public var name:String;
    public var transparent:Bool;
    public var defines:Dynamic;
    public var uniforms:Dynamic;
    public var fragmentShader:String;
    public var vertexShader:String;
    public function new(args:Dynamic) {}
}

class UniformsUtils {
    static public function clone(uniforms:Dynamic):Dynamic {}
}

class WebGLRenderTarget {
    public var texture:Texture;
    public var depthTexture:DepthTexture;
}

class Texture {

}

class Window {
    static public var innerWidth:Int;
    static public var innerHeight:Int;
}

class Renderer {
    public var autoClear:Bool;
    public function clear():Void {}
    public function render(scene:Scene, camera:Camera):Void {}
    public function setRenderTarget(renderTarget:WebGLRenderTarget):Void {}
    public var state:Dynamic;
}

class Scene {

}

class Camera {
    public var near:Float;
    public var far:Float;
    public var projectionMatrix:Matrix4;
    public var projectionMatrixInverse:Matrix4;
    public var matrixWorld:Matrix4;
    public var viewport:Dynamic;
}

class Dynamic {
    public function merge(other:Dynamic):Dynamic {}
}

class Int {
    public function default(value:Int):Int {}
}

class Float {
    public function default(value:Float):Float {}
}

class Bool {
    public function default(value:Bool):Bool {}
}