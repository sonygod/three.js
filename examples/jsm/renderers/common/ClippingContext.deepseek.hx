import three.Plane;
import three.Matrix3;
import three.Vector4;

class ClippingContext {

	var _plane:Plane = new Plane();
	static var _clippingContextVersion:Int = 0;

	public var version:Int;
	public var globalClippingCount:Int;
	public var localClippingCount:Int;
	public var localClippingEnabled:Bool;
	public var localClipIntersection:Bool;
	public var planes:Array<Vector4>;
	public var parentVersion:Int;
	public var viewNormalMatrix:Matrix3;
	public var viewMatrix:Matrix3;

	public function new() {

		this.version = ++ _clippingContextVersion;

		this.globalClippingCount = 0;

		this.localClippingCount = 0;
		this.localClippingEnabled = false;
		this.localClipIntersection = false;

		this.planes = [];

		this.parentVersion = 0;
		this.viewNormalMatrix = new Matrix3();

	}

	public function projectPlanes( source:Array<Plane>, offset:Int ) {

		var l = source.length;
		var planes = this.planes;

		for (i in 0...l) {

			_plane.copy( source[i] ).applyMatrix4( this.viewMatrix, this.viewNormalMatrix );

			var v = planes[offset + i];
			var normal = _plane.normal;

			v.x = - normal.x;
			v.y = - normal.y;
			v.z = - normal.z;
			v.w = _plane.constant;

		}

	}

	public function updateGlobal( renderer:Dynamic, camera:Dynamic ) {

		var rendererClippingPlanes = cast(renderer.clippingPlanes, Array<Plane>);
		this.viewMatrix = cast(camera.matrixWorldInverse, Matrix3);

		this.viewNormalMatrix.getNormalMatrix( this.viewMatrix );

		var update = false;

		if (Array.isArray( rendererClippingPlanes ) && rendererClippingPlanes.length !== 0 ) {

			var l = rendererClippingPlanes.length;

			if ( l !== this.globalClippingCount ) {

				var planes = [];

				for (i in 0...l) {

					planes.push( new Vector4() );

				}

				this.globalClippingCount = l;
				this.planes = planes;

				update = true;

			}

			this.projectPlanes( rendererClippingPlanes, 0 );

		} else if ( this.globalClippingCount !== 0 ) {

			this.globalClippingCount = 0;
			this.planes = [];
			update = true;

		}

		if ( cast(renderer.localClippingEnabled, Bool) !== this.localClippingEnabled ) {

			this.localClippingEnabled = cast(renderer.localClippingEnabled, Bool);
			update = true;

		}

		if ( update ) this.version = ++ _clippingContextVersion;

	}

	public function update( parent:ClippingContext, material:Dynamic ) {

		var update = false;

		if ( this !== parent && parent.version !== this.parentVersion ) {

			this.globalClippingCount = cast(material.isShadowNodeMaterial, Bool) ? 0 : parent.globalClippingCount;
			this.localClippingEnabled = parent.localClippingEnabled;
			this.planes = Array.from( parent.planes );
			this.parentVersion = parent.version;
			this.viewMatrix = parent.viewMatrix;
			this.viewNormalMatrix = parent.viewNormalMatrix;

			update = true;

		}

		if ( this.localClippingEnabled ) {

			var localClippingPlanes = cast(material.clippingPlanes, Array<Plane>);

			if ( ( Array.isArray( localClippingPlanes ) && localClippingPlanes.length !== 0 ) ) {

				var l = localClippingPlanes.length;
				var planes = this.planes;
				var offset = this.globalClippingCount;

				if ( update || l !== this.localClippingCount ) {

					planes.length = offset + l;

					for (i in 0...l) {

						planes[ offset + i ] = new Vector4();

					}

					this.localClippingCount = l;
					update = true;

				}

				this.projectPlanes( localClippingPlanes, offset );


			} else if ( this.localClippingCount !== 0 ) {

				this.localClippingCount = 0;
				update = true;

			}

			if ( this.localClipIntersection !== cast(material.clipIntersection, Bool) ) {

				this.localClipIntersection = cast(material.clipIntersection, Bool);
				update = true;

			}

		}

		if ( update ) this.version = ++ _clippingContextVersion;

	}

}