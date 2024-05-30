import TextureNode from '../accessors/TextureNode.js';
import { nodeObject, vec2 } from '../shadernode/ShaderNode.js';
import { NodeUpdateType } from '../core/constants.js';
import { viewportTopLeft } from '../display/ViewportNode.js';
import { Matrix4, Vector2, Vector3, Vector4, Object3D, Plane, RenderTarget, HalfFloatType, LinearMipMapLinearFilter } from 'three';

class ReflectorNode extends TextureNode {

    public static var _reflectorPlane(new Plane());
    public static var _normal(new Vector3());
    public static var _reflectorWorldPosition(new Vector3());
    public static var _cameraWorldPosition(new Vector3());
    public static var _rotationMatrix(new Matrix4());
    public static var _lookAtPosition(new Vector3( 0, 0, - 1 ));
    public static var clipPlane(new Vector4());

    public static var _view(new Vector3());
    public static var _target(new Vector3());
    public static var _q(new Vector4());

    public static var _size(new Vector2());

    public static var _defaultRT(new RenderTarget());
    public static var _defaultUV(vec2( viewportTopLeft.x.oneMinus(), viewportTopLeft.y ));

    public static var _inReflector(false);

    public var target:Object3D;
    public var resolution:Float;
    public var generateMipmaps:Bool;
    public var bounces:Bool;
    public var virtualCameras:WeakMap<Camera, Camera>;
    public var renderTargets:WeakMap<Camera, RenderTarget>;

    public function new( parameters:Dynamic ? = null ) {

        super( _defaultRT.texture, _defaultUV );

        if (parameters == null) parameters = new Dynamic();
        var target = parameters.target ?? new Object3D();
        var resolution = parameters.resolution ?? 1;
        var generateMipmaps = parameters.generateMipmaps ?? false;
        var bounces = parameters.bounces ?? true;

        this.target = target;
        this.resolution = resolution;
        this.generateMipmaps = generateMipmaps;
        this.bounces = bounces;

        this.updateBeforeType = bounces ? NodeUpdateType.RENDER : NodeUpdateType.FRAME;

        this.virtualCameras = new WeakMap();
        this.renderTargets = new WeakMap();

    }

    private function _updateResolution( renderTarget:RenderTarget, renderer:Renderer ) {

        var resolution = this.resolution;

        renderer.getDrawingBufferSize( _size );

        renderTarget.setSize( Math.round( _size.width * resolution ), Math.round( _size.height * resolution ) );

    }

    public function setup( builder:Builder ) {

        this._updateResolution( _defaultRT, builder.renderer );

        return super.setup( builder );

    }

    public function getTextureNode() {

        return this.textureNode;

    }

    public function getVirtualCamera( camera:Camera ) {

        var virtualCamera = this.virtualCameras.get( camera );

        if (virtualCamera == null) {

            virtualCamera = camera.clone();

            this.virtualCameras.set( camera, virtualCamera );

        }

        return virtualCamera;

    }

    public function getRenderTarget( camera:Camera ) {

        var renderTarget = this.renderTargets.get( camera );

        if (renderTarget == null) {

            renderTarget = new RenderTarget( 0, 0, { type: HalfFloatType } );

            if (this.generateMipmaps == true) {

                renderTarget.texture.minFilter = LinearMipMapLinearFilter;
                renderTarget.texture.generateMipmaps = true;

            }

            this.renderTargets.set( camera, renderTarget );

        }

        return renderTarget;

    }

    public function updateBefore( frame:Frame ) {

        if (this.bounces == false && _inReflector) return false;

        _inReflector = true;

        var scene = frame.scene;
        var camera = frame.camera;
        var renderer = frame.renderer;
        var material = frame.material;
        var target = this.target;

        var virtualCamera = this.getVirtualCamera( camera );
        var renderTarget = this.getRenderTarget( virtualCamera );

        renderer.getDrawingBufferSize( _size );

        this._updateResolution( renderTarget, renderer );

        //

        _reflectorWorldPosition.setFromMatrixPosition( target.matrixWorld );
        _cameraWorldPosition.setFromMatrixPosition( camera.matrixWorld );

        _rotationMatrix.extractRotation( target.matrixWorld );

        _normal.set( 0, 0, 1 );
        _normal.applyMatrix4( _rotationMatrix );

        _view.subVectors( _reflectorWorldPosition, _cameraWorldPosition );

        // Avoid rendering when reflector is facing away

        if ( _view.dot( _normal ) > 0 ) return;

        _view.reflect( _normal ).negate();
        _view.add( _reflectorWorldPosition );

        _rotationMatrix.extractRotation( camera.matrixWorld );

        _lookAtPosition.set( 0, 0, - 1 );
        _lookAtPosition.applyMatrix4( _rotationMatrix );
        _lookAtPosition.add( _cameraWorldPosition );

        _target.subVectors( _reflectorWorldPosition, _lookAtPosition );
        _target.reflect( _normal ).negate();
        _target.add( _reflectorWorldPosition );

        //

        virtualCamera.coordinateSystem = camera.coordinateSystem;
        virtualCamera.position.copy( _view );
        virtualCamera.up.set( 0, 1, 0 );
        virtualCamera.up.applyMatrix4( _rotationMatrix );
        virtualCamera.up.reflect( _normal );
        virtualCamera.lookAt( _target );

        virtualCamera.near = camera.near;
        virtualCamera.far = camera.far;

        virtualCamera.updateMatrixWorld();
        virtualCamera.projectionMatrix.copy( camera.projectionMatrix );

        // Now update projection matrix with new clip plane, implementing code from: http://www.terathon.com/code/oblique.html
        // Paper explaining this technique: http://www.terathon.com/lengyel/Lengyel-Oblique.pdf
        _reflectorPlane.setFromNormalAndCoplanarPoint( _normal, _reflectorWorldPosition );
        _reflectorPlane.applyMatrix4( virtualCamera.matrixWorldInverse );

        clipPlane.set( _reflectorPlane.normal.x, _reflectorPlane.normal.y, _reflectorPlane.normal.z, _reflectorPlane.constant );

        var projectionMatrix = virtualCamera.projectionMatrix;

        _q.x = ( Math.sign( clipPlane.x ) + projectionMatrix.elements[ 8 ] ) / projectionMatrix.elements[ 0 ];
        _q.y = ( Math.sign( clipPlane.y ) + projectionMatrix.elements[ 9 ] ) / projectionMatrix.elements[ 5 ];
        _q.z = - 1.0;
        _q.w = ( 1.0 + projectionMatrix.elements[ 10 ] ) / projectionMatrix.elements[ 14 ];

        // Calculate the scaled plane vector
        clipPlane.multiplyScalar( 1.0 / clipPlane.dot( _q ) );

        var clipBias = 0;

        // Replacing the third row of the projection matrix
        projectionMatrix.elements[ 2 ] = clipPlane.x;
        projectionMatrix.elements[ 6 ] = clipPlane.y;
        projectionMatrix.elements[ 10 ] = clipPlane.z - clipBias;
        projectionMatrix.elements[ 14 ] = clipPlane.w;

        //

        this.value = renderTarget.texture;

        material.visible = false;

        var currentRenderTarget = renderer.getRenderTarget();

        renderer.setRenderTarget( renderTarget );

        renderer.render( scene, virtualCamera );

        renderer.setRenderTarget( currentRenderTarget );

        material.visible = true;

        _inReflector = false;

    }

}

export const reflector( parameters:Dynamic ? = null ) => nodeObject( new ReflectorNode( parameters ) );

export default ReflectorNode;