import three.math.Quaternion;
import three.math.Vector3;
import three.math.Matrix4;
import three.core.EventDispatcher;
import three.math.Euler;
import three.core.Layers;
import three.math.Matrix3;
import three.math.MathUtils;

private static var _object3DId = 0;

private static var _v1 = new Vector3();
private static var _q1 = new Quaternion();
private static var _m1 = new Matrix4();
private static var _target = new Vector3();

private static var _position = new Vector3();
private static var _scale = new Vector3();
private static var _quaternion = new Quaternion();

private static var _xAxis = new Vector3( 1, 0, 0 );
private static var _yAxis = new Vector3( 0, 1, 0 );
private static var _zAxis = new Vector3( 0, 0, 1 );

private static var _addedEvent = { type: 'added' };
private static var _removedEvent = { type: 'removed' };

private static var _childaddedEvent = { type: 'childadded', child: null };
private static var _childremovedEvent = { type: 'childremoved', child: null };

class Object3D extends EventDispatcher {

	public function new() {

		super();

		this.isObject3D = true;

		this.id = _object3DId ++;

		this.uuid = MathUtils.generateUUID();

		this.name = '';
		this.type = 'Object3D';

		this.parent = null;
		this.children = [];

		this.up = Object3D.DEFAULT_UP.clone();

		var position = new Vector3();
		var rotation = new Euler();
		var quaternion = new Quaternion();
		var scale = new Vector3( 1, 1, 1 );

		function onRotationChange() {

			quaternion.setFromEuler( rotation, false );

		}

		function onQuaternionChange() {

			rotation.setFromQuaternion( quaternion, undefined, false );

		}

		rotation._onChange( onRotationChange );
		quaternion._onChange( onQuaternionChange );

		this.position = position;
		this.rotation = rotation;
		this.quaternion = quaternion;
		this.scale = scale;
		this.modelViewMatrix = new Matrix4();
		this.normalMatrix = new Matrix3();

		this.matrix = new Matrix4();
		this.matrixWorld = new Matrix4();

		this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;

		this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // checked by the renderer
		this.matrixWorldNeedsUpdate = false;

		this.layers = new Layers();
		this.visible = true;

		this.castShadow = false;
		this.receiveShadow = false;

		this.frustumCulled = true;
		this.renderOrder = 0;

		this.animations = [];

		this.userData = {};

	}

	public function onBeforeShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */ ) {}
	public function onAfterShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */ ) {}
	public function onBeforeRender( /* renderer, scene, camera, geometry, material, group */ ) {}
	public function onAfterRender( /* renderer, scene, camera, geometry, material, group */ ) {}
	public function applyMatrix4( matrix : Matrix4 ) {

		if ( this.matrixAutoUpdate ) this.updateMatrix();

		this.matrix.premultiply( matrix );

		this.matrix.decompose( this.position, this.quaternion, this.scale );

	}
	public function applyQuaternion( q : Quaternion ) {

		this.quaternion.premultiply( q );

		return this;

	}
	public function setRotationFromAxisAngle( axis : Vector3, angle : Float ) {

		// assumes axis is normalized

		this.quaternion.setFromAxisAngle( axis, angle );

	}
	public function setRotationFromEuler( euler : Euler ) {

		this.quaternion.setFromEuler( euler, true );

	}
	public function setRotationFromMatrix( m : Matrix4 ) {

		// assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

		this.quaternion.setFromRotationMatrix( m );

	}
	public function setRotationFromQuaternion( q : Quaternion ) {

		// assumes q is normalized

		this.quaternion.copy( q );

	}
	public function rotateOnAxis( axis : Vector3, angle : Float ) {

		// rotate object on axis in object space
		// axis is assumed to be normalized

		_q1.setFromAxisAngle( axis, angle );

		this.quaternion.multiply( _q1 );

		return this;

	}
	public function rotateOnWorldAxis( axis : Vector3, angle : Float ) {

		// rotate object on axis in world space
		// axis is assumed to be normalized
		// method assumes no rotated parent

		_q1.setFromAxisAngle( axis, angle );

		this.quaternion.premultiply( _q1 );

		return this;

	}
	public function rotateX( angle : Float ) {

		return this.rotateOnAxis( _xAxis, angle );

	}
	public function rotateY( angle : Float ) {

		return this.rotateOnAxis( _yAxis, angle );

	}
	public function rotateZ( angle : Float ) {

		return this.rotateOnAxis( _zAxis, angle );

	}
	public function translateOnAxis( axis : Vector3, distance : Float ) {

		// translate object by distance along axis in object space
		// axis is assumed to be normalized

		_v1.copy( axis ).applyQuaternion( this.quaternion );

		this.position.add( _v1.multiplyScalar( distance ) );

		return this;

	}
	public function translateX( distance : Float ) {

		return this.translateOnAxis( _xAxis, distance );

	}
	public function translateY( distance : Float ) {

		return this.translateOnAxis( _yAxis, distance );

	}
	public function translateZ( distance : Float ) {

		return this.translateOnAxis( _zAxis, distance );

	}
	public function localToWorld( vector : Vector3 ) {

		this.updateWorldMatrix( true, false );

		return vector.applyMatrix4( this.matrixWorld );

	}
	public function worldToLocal( vector : Vector3 ) {

		this.updateWorldMatrix( true, false );

		return vector.applyMatrix4( _m1.copy( this.matrixWorld ).invert() );

	}
	public function lookAt( x : Float, y : Float, z : Float ) {

		// This method does not support objects having non-uniformly-scaled parent(s)

		if ( x.isVector3 ) {

			_target.copy( x );

		} else {

			_target.set( x, y, z );

		}

		var parent = this.parent;

		this.updateWorldMatrix( true, false );

		_position.setFromMatrixPosition( this.matrixWorld );

		if ( this.isCamera || this.isLight ) {

			_m1.lookAt( _position, _target, this.up );

		} else {

			_m1.lookAt( _target, _position, this.up );

		}

		this.quaternion.setFromRotationMatrix( _m1 );

		if ( parent ) {

			_m1.extractRotation( parent.matrixWorld );
			_q1.setFromRotationMatrix( _m1 );
			this.quaternion.premultiply( _q1.invert() );

		}

	}
	public function add( object : Object3D ) {

		if ( arguments.length > 1 ) {

			for ( i in arguments ) {

				this.add( arguments[ i ] );

			}

			return this;

		}

		if ( object === this ) {

			trace( 'THREE.Object3D.add: object can\'t be added as a child of itself.', object );
			return this;

		}

		if ( object && object.isObject3D ) {

			object.removeFromParent();
			object.parent = this;
			this.children.push( object );

			object.dispatchEvent( _addedEvent );

			_childaddedEvent.child = object;
			this.dispatchEvent( _childaddedEvent );
			_childaddedEvent.child = null;

		} else {

			trace( 'THREE.Object3D.add: object not an instance of THREE.Object3D.', object );

		}

		return this;

	}
	public function remove( object : Object3D ) {

		if ( arguments.length > 1 ) {

			for ( i in arguments ) {

				this.remove( arguments[ i ] );

			}

			return this;

		}

		var index = this.children.indexOf( object );

		if ( index !== - 1 ) {

			object.parent = null;
			this.children.splice( index, 1 );

			object.dispatchEvent( _removedEvent );

			_childremovedEvent.child = object;
			this.dispatchEvent( _childremovedEvent );
			_childremovedEvent.child = null;

		}

		return this;

	}
	public function removeFromParent() {

		var parent = this.parent;

		if ( parent !== null ) {

			parent.remove( this );

		}

		return this;

	}
	public function clear() {

		return this.remove( ... this.children );

	}
	public function attach( object : Object3D ) {

		// adds object as a child of this, while maintaining the object's world transform

		// Note: This method does not support scene graphs having non-uniformly-scaled nodes(s)

		this.updateWorldMatrix( true, false );

		_m1.copy( this.matrixWorld ).invert();

		if ( object.parent !== null ) {

			object.parent.updateWorldMatrix( true, false );

			_m1.multiply( object.parent.matrixWorld );

		}

		object.applyMatrix4( _m1 );

		object.removeFromParent();
		object.parent = this;
		this.children.push( object );

		object.updateWorldMatrix( false, true );

		object.dispatchEvent( _addedEvent );

		_childaddedEvent.child = object;
		this.dispatchEvent( _childaddedEvent );
		_childaddedEvent.child = null;

		return this;

	}
	public function getObjectById( id : Int ) {

		return this.getObjectByProperty( 'id', id );

	}
	public function getObjectByName( name : String ) {

		return this.getObjectByProperty( 'name', name );

	}
	public function getObjectByProperty( name : String, value : Dynamic ) {

		if ( this[ name ] === value ) return this;

		for ( i in this.children ) {

			var child = this.children[ i ];
			var object = child.getObjectByProperty( name, value );

			if ( object !== undefined ) {

				return object;

			}

		}

		return undefined;

	}
	public function getObjectsByProperty( name : String, value : Dynamic, result = [] ) {

		if ( this[ name ] === value ) result.push( this );

		var children = this.children;

		for ( i in children ) {

			children[ i ].getObjectsByProperty( name, value, result );

		}

		return result;

	}
	public function getWorldPosition( target : Vector3 ) {

		this.updateWorldMatrix( true, false );

		return target.setFromMatrixPosition( this.matrixWorld );

	}
	public function getWorldQuaternion( target : Quaternion ) {

		this.updateWorldMatrix( true, false );

		this.matrixWorld.decompose( _position, target, _scale );

		return target;

	}
	public function getWorldScale( target : Vector3 ) {

		this.updateWorldMatrix( true, false );

		this.matrixWorld.decompose( _position, _quaternion, target );

		return target;

	}
	public function getWorldDirection( target : Vector3 ) {

		this.updateWorldMatrix( true, false );

		var e = this.matrixWorld.elements;

		return target.set( e[ 8 ], e[ 9 ], e[ 10 ] ).normalize();

	}
	public function raycast( /* raycaster, intersects */ ) {}
}