import three.MathUtils;
import three.Spherical;
import three.Vector3;
import three.core.Object3D;
import js.html.Element;
import js.Browser;

class FirstPersonControls {

	// API

	public var enabled:Bool;

	public var movementSpeed:Float;
	public var lookSpeed:Float;

	public var lookVertical:Bool;
	public var autoForward:Bool;

	public var activeLook:Bool;

	public var heightSpeed:Bool;
	public var heightCoef:Float;
	public var heightMin:Float;
	public var heightMax:Float;

	public var constrainVertical:Bool;
	public var verticalMin:Float;
	public var verticalMax:Float;

	// internals

	var autoSpeedFactor:Float;

	var pointerX:Float;
	var pointerY:Float;

	var moveForward:Bool;
	var moveBackward:Bool;
	var moveLeft:Bool;
	var moveRight:Bool;
	var moveUp:Bool;
	var moveDown:Bool;

	var viewHalfX:Float;
	var viewHalfY:Float;

	// private variables

	var lat:Float;
	var lon:Float;

	var object:Object3D;
	var domElement:Element;

	// temp variables
	static var _lookDirection = new Vector3();
	static var _spherical = new Spherical();
	static var _target = new Vector3();

	public function new(object:Object3D, domElement:Element) {

		this.object = object;
		this.domElement = domElement;

		// API

		this.enabled = true;

		this.movementSpeed = 1.0;
		this.lookSpeed = 0.005;

		this.lookVertical = true;
		this.autoForward = false;

		this.activeLook = true;

		this.heightSpeed = false;
		this.heightCoef = 1.0;
		this.heightMin = 0.0;
		this.heightMax = 1.0;

		this.constrainVertical = false;
		this.verticalMin = 0;
		this.verticalMax = Math.PI;

		// internals

		this.autoSpeedFactor = 0.0;

		this.pointerX = 0;
		this.pointerY = 0;

		this.moveForward = false;
		this.moveBackward = false;
		this.moveLeft = false;
		this.moveRight = false;

		this.viewHalfX = 0;
		this.viewHalfY = 0;

		// private variables

		lat = 0;
		lon = 0;

		//

		if (this.domElement == Browser.document) {

			this.viewHalfX = Browser.window.innerWidth / 2;
			this.viewHalfY = Browser.window.innerHeight / 2;

		} else {

			this.viewHalfX = this.domElement.offsetWidth / 2;
			this.viewHalfY = this.domElement.offsetHeight / 2;

		}

		Browser.window.onResize = this.handleResize;
		this.domElement.onPointerDown = this.onPointerDown;
		this.domElement.onPointerMove = this.onPointerMove;
		this.domElement.onPointerUp = this.onPointerUp;
		this.domElement.onContextMenu = function(_) {
			_.preventDefault();
			return false;
		};

		Browser.window.onKeyDown = this.onKeyDown;
		Browser.window.onKeyUp = this.onKeyUp;

		setOrientation(this);

	}

	public function handleResize(?_:Dynamic):Void {

		if (this.domElement == Browser.document) {

			this.viewHalfX = Browser.window.innerWidth / 2;
			this.viewHalfY = Browser.window.innerHeight / 2;

		} else {

			this.viewHalfX = this.domElement.offsetWidth / 2;
			this.viewHalfY = this.domElement.offsetHeight / 2;

		}

	}

	public function onPointerDown(event:Dynamic):Void {

		if (this.domElement != Browser.document) {

			// this.domElement.focus(); // Not available in Haxe

		}

		if (this.activeLook) {

			switch (event.button) {

				case 0: this.moveForward = true; break;
				case 2: this.moveBackward = true; break;

			}

		}

	}

	public function onPointerUp(event:Dynamic):Void {

		if (this.activeLook) {

			switch (event.button) {

				case 0: this.moveForward = false; break;
				case 2: this.moveBackward = false; break;

			}

		}

	}

	public function onPointerMove(event:Dynamic):Void {

		if (this.domElement == Browser.document) {

			this.pointerX = event.pageX - this.viewHalfX;
			this.pointerY = event.pageY - this.viewHalfY;

		} else {

			this.pointerX = event.pageX - this.domElement.offsetLeft - this.viewHalfX;
			this.pointerY = event.pageY - this.domElement.offsetTop - this.viewHalfY;

		}

	}

	public function onKeyDown(event:Dynamic):Void {

		switch (event.code) {

			case 'ArrowUp':
			case 'KeyW': this.moveForward = true; break;

			case 'ArrowLeft':
			case 'KeyA': this.moveLeft = true; break;

			case 'ArrowDown':
			case 'KeyS': this.moveBackward = true; break;

			case 'ArrowRight':
			case 'KeyD': this.moveRight = true; break;

			case 'KeyR': this.moveUp = true; break;
			case 'KeyF': this.moveDown = true; break;

		}

	}

	public function onKeyUp(event:Dynamic):Void {

		switch (event.code) {

			case 'ArrowUp':
			case 'KeyW': this.moveForward = false; break;

			case 'ArrowLeft':
			case 'KeyA': this.moveLeft = false; break;

			case 'ArrowDown':
			case 'KeyS': this.moveBackward = false; break;

			case 'ArrowRight':
			case 'KeyD': this.moveRight = false; break;

			case 'KeyR': this.moveUp = false; break;
			case 'KeyF': this.moveDown = false; break;

		}

	}

	public function lookAt(x:Dynamic, y:Float = 0, z:Float = 0):FirstPersonControls {

		if (Std.is(x, Vector3)) {

			_target.copy(x);

		} else {

			_target.set(cast x, y, z);

		}

		this.object.lookAt(_target);

		setOrientation(this);

		return this;

	}

	public function update(delta:Float):Void {

		if (!this.enabled) return;

		if (this.heightSpeed) {

			var y = MathUtils.clamp(this.object.position.y, this.heightMin, this.heightMax);
			var heightDelta = y - this.heightMin;

			this.autoSpeedFactor = delta * (heightDelta * this.heightCoef);

		} else {

			this.autoSpeedFactor = 0.0;

		}

		var actualMoveSpeed = delta * this.movementSpeed;

		if (this.moveForward || (this.autoForward && !this.moveBackward)) this.object.translateZ(-(actualMoveSpeed + this.autoSpeedFactor));
		if (this.moveBackward) this.object.translateZ(actualMoveSpeed);

		if (this.moveLeft) this.object.translateX(-actualMoveSpeed);
		if (this.moveRight) this.object.translateX(actualMoveSpeed);

		if (this.moveUp) this.object.translateY(actualMoveSpeed);
		if (this.moveDown) this.object.translateY(-actualMoveSpeed);

		var actualLookSpeed = delta * this.lookSpeed;

		if (!this.activeLook) {

			actualLookSpeed = 0;

		}

		var verticalLookRatio = 1.0;

		if (this.constrainVertical) {

			verticalLookRatio = Math.PI / (this.verticalMax - this.verticalMin);

		}

		lon -= this.pointerX * actualLookSpeed;
		if (this.lookVertical) lat -= this.pointerY * actualLookSpeed * verticalLookRatio;

		lat = Math.max(-85, Math.min(85, lat));

		var phi = MathUtils.degToRad(90 - lat);
		var theta = MathUtils.degToRad(lon);

		if (this.constrainVertical) {

			phi = MathUtils.mapLinear(phi, 0, Math.PI, this.verticalMin, this.verticalMax);

		}

		var targetPosition = new Vector3();
		var position = this.object.position;

		targetPosition.setFromSphericalCoords(1, phi, theta).add(position);

		this.object.lookAt(targetPosition);

	}

	public function dispose():Void {

		this.domElement.removeEventListener('contextmenu', null);
		this.domElement.removeEventListener('pointerdown', null);
		this.domElement.removeEventListener('pointermove', null);
		this.domElement.removeEventListener('pointerup', null);

		Browser.window.removeEventListener('keydown', null);
		Browser.window.removeEventListener('keyup', null);

	}

	static function setOrientation(controls:FirstPersonControls):Void {

		var quaternion = controls.object.quaternion;

		_lookDirection.set(0, 0, -1).applyQuaternion(quaternion);
		_spherical.setFromVector3(_lookDirection);

		controls.lat = 90 - MathUtils.radToDeg(_spherical.phi);
		controls.lon = MathUtils.radToDeg(_spherical.theta);

	}

}