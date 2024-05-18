package three.js.examples.jvm.objects;

import three.js.Geometry;
import three.js.Material;
import three.js.Matrix4;
import three.js.Mesh;
import three.js.Object3D;
import three.js.PerspectiveCamera;
import three.js.RenderTarget;
import three.js.ShaderMaterial;
import three.js.Texture;
import three.js.UniformsUtils;
import three.js.Vector2;
import three.js.Vector3;
import three.js.WebGLRenderTarget;

class ReflectorForSSRPass extends Mesh {

    public var isReflectorForSSRPass:Bool = true;
    public var type:String = 'ReflectorForSSRPass';

    private var material:ShaderMaterial;
    private var textureWidth:Int = 512;
    private var textureHeight:Int = 512;
    private var clipBias:Float = 0;
    private var shader:Dynamic;
    private var useDepthTexture:Bool = false;
    private var yAxis:Vector3;
    private var vecTemp0:Vector3;
    private var vecTemp1:Vector3;
    private var needsUpdate:Bool = false;
    private var maxDistance:Float;
    private var opacity:Float;
    private var color:Vector3;
    private var resolution:Vector2;
    private var _distanceAttenuation:Bool;
    private var _fresnel:Bool;
    private var normal:Vector3;
    private var reflectorWorldPosition:Vector3;
    private var cameraWorldPosition:Vector3;
    private var rotationMatrix:Matrix4;
    private var lookAtPosition:Vector3;
    private var view:Vector3;
    private var target:Vector3;
    private var textureMatrix:Matrix4;
    private var virtualCamera:PerspectiveCamera;
    private var depthTexture:Texture;
    private var renderTarget:WebGLRenderTarget;

    public function new(geometry:Geometry, ?options:Dynamic) {
        super(geometry);

        if (options == null) options = {};

        var color:Vector3 = (options.color != null) ? new Vector3(options.color.r, options.color.g, options.color.b) : new Vector3(0.7, 0.7, 0.7);
        textureWidth = (options.textureWidth != null) ? options.textureWidth : 512;
        textureHeight = (options.textureHeight != null) ? options.textureHeight : 512;
        clipBias = (options.clipBias != null) ? options.clipBias : 0;
        shader = (options.shader != null) ? options.shader : ReflectorForSSRPass.ReflectorShader;
        useDepthTexture = (options.useDepthTexture != null) ? options.useDepthTexture : false;

        yAxis = new Vector3(0, 1, 0);
        vecTemp0 = new Vector3();
        vecTemp1 = new Vector3();

        needsUpdate = false;
        maxDistance = ReflectorForSSRPass.ReflectorShader.uniforms.maxDistance.value;
        opacity = ReflectorForSSRPass.ReflectorShader.uniforms.opacity.value;
        color = color;
        resolution = (options.resolution != null) ? options.resolution : new Vector2(window.innerWidth, window.innerHeight);

        _distanceAttenuation = ReflectorForSSRPass.ReflectorShader.defines.DISTANCE_ATTENUATION;
        Reflect.setProperty(this, 'distanceAttenuation', {
            get: function() {
                return _distanceAttenuation;
            },
            set: function(val:Bool) {
                if (_distanceAttenuation == val) return;
                _distanceAttenuation = val;
                material.defines.DISTANCE_ATTENUATION = val;
                material.needsUpdate = true;
            }
        });

        _fresnel = ReflectorForSSRPass.ReflectorShader.defines.FRESNEL;
        Reflect.setProperty(this, 'fresnel', {
            get: function() {
                return _fresnel;
            },
            set: function(val:Bool) {
                if (_fresnel == val) return;
                _fresnel = val;
                material.defines.FRESNEL = val;
                material.needsUpdate = true;
            }
        });

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
            depthTexture = new DepthTexture(UnsignedShortType, NearestFilter, NearestFilter);
        }

        var parameters = {
            depthTexture: useDepthTexture ? depthTexture : null,
            type: HalfFloatType
        };

        renderTarget = new WebGLRenderTarget(textureWidth, textureHeight, parameters);

        material = new ShaderMaterial({
            name: (shader.name != null) ? shader.name : 'unspecified',
            transparent: useDepthTexture,
            defines: Object.assign({}, ReflectorForSSRPass.ReflectorShader.defines, { useDepthTexture: useDepthTexture }),
            uniforms: UniformsUtils.clone(shader.uniforms),
            fragmentShader: shader.fragmentShader,
            vertexShader: shader.vertexShader
        });

        material.uniforms['tDiffuse'].value = renderTarget.texture;
        material.uniforms['color'].value = color;
        material.uniforms['textureMatrix'].value = textureMatrix;
        if (useDepthTexture) {
            material.uniforms['tDepth'].value = renderTarget.depthTexture;
        }

        this.material = material;

        var globalPlane = new Plane(new Vector3(0, 1, 0), clipBias);
        var globalPlanes = [globalPlane];

        doRender = function(renderer:Object3D, scene:Object3D, camera:PerspectiveCamera) {
            material.uniforms['maxDistance'].value = maxDistance;
            material.uniforms['color'].value = color;
            material.uniforms['opacity'].value = opacity;

            vecTemp0.copy(camera.position).normalize();
            vecTemp1.copy(vecTemp0).reflect(yAxis);
            material.uniforms['fresnelCoe'].value = (vecTemp0.dot(vecTemp1) + 1.) / 2.;

            reflectorWorldPosition.setFromMatrixPosition(this.matrixWorld);
            cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);

            rotationMatrix.extractRotation(this.matrixWorld);

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
            material.uniforms['resolution'].value = resolution;

            textureMatrix.set(
                0.5, 0.0, 0.0, 0.5,
                0.0, 0.5, 0.0, 0.5,
                0.0, 0.0, 0.5, 0.5,
                0.0, 0.0, 0.0, 1.0
            );
            textureMatrix.multiply(virtualCamera.projectionMatrix);
            textureMatrix.multiply(virtualCamera.matrixWorldInverse);
            textureMatrix.multiply(this.matrixWorld);
        };

        getRenderTarget = function() {
            return renderTarget;
        };
    }

    public static var ReflectorShader:Dynamic = {
        name: 'ReflectorShader',
        defines: {
            DISTANCE_ATTENUATION: true,
            FRESNEL: true
        },
        uniforms: {
            color: { value: null },
            tDiffuse: { value: null },
            tDepth: { value: null },
            textureMatrix: { value: new Matrix4() },
            maxDistance: { value: 180 },
            opacity: { value: 0.5 },
            fresnelCoe: { value: null },
            virtualCameraNear: { value: null },
            virtualCameraFar: { value: null },
            virtualCameraProjectionMatrix: { value: new Matrix4() },
            virtualCameraMatrixWorld: { value: new Matrix4() },
            virtualCameraProjectionMatrixInverse: { value: new Matrix4() },
            resolution: { value: new Vector2() }
        },
        vertexShader: '
            uniform mat4 textureMatrix;
            varying vec4 vUv;

            void main() {

                vUv = textureMatrix * vec4( position, 1.0 );

                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

            }',
        fragmentShader: '
            uniform vec3 color;
            uniform sampler2D tDiffuse;
            uniform sampler2D tDepth;
            uniform float maxDistance;
            uniform float opacity;
            uniform float fresnelCoe;
            uniform float virtualCameraNear;
            uniform float virtualCameraFar;
            uniform mat4 virtualCameraProjectionMatrix;
            uniform mat4 virtualCameraProjectionMatrixInverse;
            uniform mat4 virtualCameraMatrixWorld;
            uniform vec2 resolution;
            varying vec4 vUv;
            #include <packing>
            float blendOverlay( float base, float blend ) {
                return( base < 0.5 ? ( 2.0 * base * blend ) : ( 1.0 - 2.0 * ( 1.0 - base ) * ( 1.0 - blend ) ) );
            }
            vec3 blendOverlay( vec3 base, vec3 blend ) {
                return vec3( blendOverlay( base.r, blend.r ), blendOverlay( base.g, blend.g ), blendOverlay( base.b, blend.b ) );
            }
            float getDepth( const in vec2 uv ) {
                return texture2D( tDepth, uv ).x;
            }
            float getViewZ( const in float depth ) {
                return perspectiveDepthToViewZ( depth, virtualCameraNear, virtualCameraFar );
            }
            vec3 getViewPosition( const in vec2 uv, const in float depth/*clip space*/, const in float clipW ) {
                vec4 clipPosition = vec4( ( vec3( uv, depth ) - 0.5 ) * 2.0, 1.0 );//ndc
                clipPosition *= clipW; //clip
                return ( virtualCameraProjectionMatrixInverse * clipPosition ).xyz;//view
            }
            void main() {
                vec4 base = texture2DProj( tDiffuse, vUv );
                #ifdef useDepthTexture
                vec2 uv=(gl_FragCoord.xy-.5)/resolution.xy;
                uv.x=1.-uv.x;
                float depth = texture2DProj( tDepth, vUv ).r;
                float viewZ = getViewZ( depth );
                float clipW = virtualCameraProjectionMatrix[2][3] * viewZ+virtualCameraProjectionMatrix[3][3];
                vec3 viewPosition=getViewPosition( uv, depth, clipW );
                vec3 worldPosition=(virtualCameraMatrixWorld*vec4(viewPosition,1)).xyz;
                if(worldPosition.y>maxDistance) discard;
                float op=opacity;
                #ifdef DISTANCE_ATTENUATION
                float ratio=1.-(worldPosition.y/maxDistance);
                float attenuation=ratio*ratio;
                op=opacity*attenuation;
                #endif
                #ifdef FRESNEL
                op*=fresnelCoe;
                #endif
                gl_FragColor = vec4( blendOverlay( base.rgb, color ), op );
            } else {
                gl_FragColor = vec4( blendOverlay( base.rgb, color ), 1.0 );
            }
        }'
    };
}