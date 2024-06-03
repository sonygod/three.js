import TextureNode from '../accessors/TextureNode';
import { NodeUpdateType } from '../core/constants';
import { viewportTopLeft } from '../display/ViewportNode';
import { Matrix4, Vector2, Vector3, Vector4, Object3D, Plane, RenderTarget, HalfFloatType, LinearMipMapLinearFilter } from 'three';

class ReflectorNode extends TextureNode {

    public var _reflectorPlane:Plane = new Plane();
    public var _normal:Vector3 = new Vector3();
    public var _reflectorWorldPosition:Vector3 = new Vector3();
    public var _cameraWorldPosition:Vector3 = new Vector3();
    public var _rotationMatrix:Matrix4 = new Matrix4();
    public var _lookAtPosition:Vector3 = new Vector3( 0, 0, - 1 );
    public var clipPlane:Vector4 = new Vector4();

    public var _view:Vector3 = new Vector3();
    public var _target:Vector3 = new Vector3();
    public var _q:Vector4 = new Vector4();

    public var _size:Vector2 = new Vector2();

    public var _defaultRT:RenderTarget = new RenderTarget();
    public var _defaultUV:Dynamic = vec2( viewportTopLeft.x.oneMinus(), viewportTopLeft.y );

    public var _inReflector:Bool = false;

    public var target:Object3D;
    public var resolution:Float;
    public var generateMipmaps:Bool;
    public var bounces:Bool;

    public var virtualCameras:Map<Camera, Camera>;
    public var renderTargets:Map<Camera, RenderTarget>;

    public function new( parameters:Object = {}) {

        super( _defaultRT.texture, _defaultUV );

        this.target = parameters.target != null ? parameters.target : new Object3D();
        this.resolution = parameters.resolution != null ? parameters.resolution : 1;
        this.generateMipmaps = parameters.generateMipmaps != null ? parameters.generateMipmaps : false;
        this.bounces = parameters.bounces != null ? parameters.bounces : true;

        this.updateBeforeType = this.bounces ? NodeUpdateType.RENDER : NodeUpdateType.FRAME;

        this.virtualCameras = new haxe.ds.WeakMap();
        this.renderTargets = new haxe.ds.WeakMap();
    }

    public function _updateResolution( renderTarget:RenderTarget, renderer:Renderer ) {

        renderer.getDrawingBufferSize( _size );

        renderTarget.setSize( Math.round( _size.x * this.resolution ), Math.round( _size.y * this.resolution ) );
    }

    public function setup( builder:ShaderNodeBuilder ):Object {

        this._updateResolution( _defaultRT, builder.renderer );

        return super.setup( builder );
    }

    public function getTextureNode():TextureNode {

        return this.textureNode;
    }

    public function getVirtualCamera( camera:Camera ):Camera {

        let virtualCamera = this.virtualCameras.get( camera );

        if ( virtualCamera == null ) {

            virtualCamera = camera.clone();

            this.virtualCameras.set( camera, virtualCamera );
        }

        return virtualCamera;
    }

    public function getRenderTarget( camera:Camera ):RenderTarget {

        let renderTarget = this.renderTargets.get( camera );

        if ( renderTarget == null ) {

            renderTarget = new RenderTarget( 0, 0, { type: HalfFloatType } );

            if ( this.generateMipmaps ) {

                renderTarget.texture.minFilter = LinearMipMapLinearFilter;
                renderTarget.texture.generateMipmaps = true;
            }

            this.renderTargets.set( camera, renderTarget );
        }

        return renderTarget;
    }

    public function updateBefore( frame:Frame ):Bool {

        if ( !this.bounces && _inReflector ) return false;

        _inReflector = true;

        let { scene, camera, renderer, material } = frame;

        let virtualCamera = this.getVirtualCamera( camera );
        let renderTarget = this.getRenderTarget( virtualCamera );

        renderer.getDrawingBufferSize( _size );

        this._updateResolution( renderTarget, renderer );

        _reflectorWorldPosition.setFromMatrixPosition( this.target.matrixWorld );
        _cameraWorldPosition.setFromMatrixPosition( camera.matrixWorld );

        _rotationMatrix.extractRotation( this.target.matrixWorld );

        _normal.set( 0, 0, 1 );
        _normal.applyMatrix4( _rotationMatrix );

        _view.subVectors( _reflectorWorldPosition, _cameraWorldPosition );

        if ( _view.dot( _normal ) > 0 ) return false;

        _view.reflect( _normal ).negate();
        _view.add( _reflectorWorldPosition );

        _rotationMatrix.extractRotation( camera.matrixWorld );

        _lookAtPosition.set( 0, 0, - 1 );
        _lookAtPosition.applyMatrix4( _rotationMatrix );
        _lookAtPosition.add( _cameraWorldPosition );

        _target.subVectors( _reflectorWorldPosition, _lookAtPosition );
        _target.reflect( _normal ).negate();
        _target.add( _reflectorWorldPosition );

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

        _reflectorPlane.setFromNormalAndCoplanarPoint( _normal, _reflectorWorldPosition );
        _reflectorPlane.applyMatrix4( virtualCamera.matrixWorldInverse );

        clipPlane.set( _reflectorPlane.normal.x, _reflectorPlane.normal.y, _reflectorPlane.normal.z, _reflectorPlane.constant );

        let projectionMatrix = virtualCamera.projectionMatrix;

        _q.x = ( Math.sign( clipPlane.x ) + projectionMatrix.elements[ 8 ] ) / projectionMatrix.elements[ 0 ];
        _q.y = ( Math.sign( clipPlane.y ) + projectionMatrix.elements[ 9 ] ) / projectionMatrix.elements[ 5 ];
        _q.z = - 1.0;
        _q.w = ( 1.0 + projectionMatrix.elements[ 10 ] ) / projectionMatrix.elements[ 14 ];

        clipPlane.multiplyScalar( 1.0 / clipPlane.dot( _q ) );

        let clipBias = 0;

        projectionMatrix.elements[ 2 ] = clipPlane.x;
        projectionMatrix.elements[ 6 ] = clipPlane.y;
        projectionMatrix.elements[ 10 ] = clipPlane.z - clipBias;
        projectionMatrix.elements[ 14 ] = clipPlane.w;

        this.value = renderTarget.texture;

        material.visible = false;

        let currentRenderTarget = renderer.getRenderTarget();

        renderer.setRenderTarget( renderTarget );

        renderer.render( scene, virtualCamera );

        renderer.setRenderTarget( currentRenderTarget );

        material.visible = true;

        _inReflector = false;

        return true;
    }
}

static public function reflector( parameters:Object ):Object {
    return nodeObject( new ReflectorNode( parameters ) );
}