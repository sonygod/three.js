setMouseAction( operation, mouse, key = null ) {

		const operationInput = [ 'PAN', 'ROTATE', 'ZOOM', 'FOV' ];
		const mouseInput = [ 0, 1, 2, 'WHEEL' ];
		const keyInput = [ 'CTRL', 'SHIFT', null ];
		let state;

		if ( ! operationInput.includes( operation ) || ! mouseInput.includes( mouse ) || ! keyInput.includes( key ) ) {

			//invalid parameters
			return false;

		}

		if ( mouse == 'WHEEL' ) {

			if ( operation != 'ZOOM' && operation != 'FOV' ) {

				//cannot associate 2D operation to 1D input
				return false;

			}

		}

		switch ( operation ) {

			case 'PAN':

				state = STATE.PAN;
				break;

			case 'ROTATE':

				state = STATE.ROTATE;
				break;

			case 'ZOOM':

				state = STATE.SCALE;
				break;

			case 'FOV':

				state = STATE.FOV;
				break;

		}

		const action = {

			operation: operation,
			mouse: mouse,
			key: key,
			state: state

		};

		for ( let i = 0; i < this.mouseActions.length; i ++ ) {

			if ( this.mouseActions[ i ].mouse == action.mouse && this.mouseActions[ i ].key == action.key ) {

				this.mouseActions.splice( i, 1, action );
				return true;

			}

		}

		this.mouseActions.push( action );
		return true;

	}
unsetMouseAction( mouse, key = null ) {

		for ( let i = 0; i < this.mouseActions.length; i ++ ) {

			if ( this.mouseActions[ i ].mouse == mouse && this.mouseActions[ i ].key == key ) {

				this.mouseActions.splice( i, 1 );
				return true;

			}

		}

		return false;

	}
getOpFromAction( mouse, key ) {

		let action;

		for ( let i = 0; i < this.mouseActions.length; i ++ ) {

			action = this.mouseActions[ i ];
			if ( action.mouse == mouse && action.key == key ) {

				return action.operation;

			}

		}

		if ( key != null ) {

			for ( let i = 0; i < this.mouseActions.length; i ++ ) {

				action = this.mouseActions[ i ];
				if ( action.mouse == mouse && action.key == null ) {

					return action.operation;

				}

			}

		}

		return null;

	}
getOpStateFromAction( mouse, key ) {

		let action;

		for ( let i = 0; i < this.mouseActions.length; i ++ ) {

			action = this.mouseActions[ i ];
			if ( action.mouse == mouse && action.key == key ) {

				return action.state;

			}

		}

		if ( key != null ) {

			for ( let i = 0; i < this.mouseActions.length; i ++ ) {

				action = this.mouseActions[ i ];
				if ( action.mouse == mouse && action.key == null ) {

					return action.state;

				}

			}

		}

		return null;

	}
getAngle( p1, p2 ) {

		return Math.atan2( p2.clientY - p1.clientY, p2.clientX - p1.clientX ) * 180 / Math.PI;

	}
updateTouchEvent( event ) {

		for ( let i = 0; i < this._touchCurrent.length; i ++ ) {

			if ( this._touchCurrent[ i ].pointerId == event.pointerId ) {

				this._touchCurrent.splice( i, 1, event );
				break;

			}

		}

	}
applyTransformMatrix( transformation ) {

		if ( transformation.camera != null ) {

			this._m4_1.copy( this._cameraMatrixState ).premultiply( transformation.camera );
			this._m4_1.decompose( this.camera.position, this.camera.quaternion, this.camera.scale );
			this.camera.updateMatrix();

			//update camera up vector
			if ( this._state == STATE.ROTATE || this._state == STATE.ZROTATE || this._state == STATE.ANIMATION_ROTATE ) {

				this.camera.up.copy( this._upState ).applyQuaternion( this.camera.quaternion );

			}

		}

		if ( transformation.gizmos != null ) {

			this._m4_1.copy( this._gizmoMatrixState ).premultiply( transformation.gizmos );
			this._m4_1.decompose( this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale );
			this._gizmos.updateMatrix();

		}

		if ( this._state == STATE.SCALE || this._state == STATE.FOCUS || this._state == STATE.ANIMATION_FOCUS ) {

			this._tbRadius = this.calculateTbRadius( this.camera );

			if ( this.adjustNearFar ) {

				const cameraDistance = this.camera.position.distanceTo( this._gizmos.position );

				const bb = new Box3();
				bb.setFromObject( this._gizmos );
				const sphere = new Sphere();
				bb.getBoundingSphere( sphere );

				const adjustedNearPosition = Math.max( this._nearPos0, sphere.radius + sphere.center.length() );
				const regularNearPosition = cameraDistance - this._initialNear;

				const minNearPos = Math.min( adjustedNearPosition, regularNearPosition );
				this.camera.near = cameraDistance - minNearPos;


				const adjustedFarPosition = Math.min( this._farPos0, - sphere.radius + sphere.center.length() );
				const regularFarPosition = cameraDistance - this._initialFar;

				const minFarPos = Math.min( adjustedFarPosition, regularFarPosition );
				this.camera.far = cameraDistance - minFarPos;

				this.camera.updateProjectionMatrix();

			} else {

				let update = false;

				if ( this.camera.near != this._initialNear ) {

					this.camera.near = this._initialNear;
					update = true;

				}

				if ( this.camera.far != this._initialFar ) {

					this.camera.far = this._initialFar;
					update = true;

				}

				if ( update ) {

					this.camera.updateProjectionMatrix();

				}

			}

		}

	}
calculateAngularSpeed( p0, p1, t0, t1 ) {

		const s = p1 - p0;
		const t = ( t1 - t0 ) / 1000;
		if ( t == 0 ) {

			return 0;

		}

		return s / t;

	}
calculatePointersDistance( p0, p1 ) {

		return Math.sqrt( Math.pow( p1.clientX - p0.clientX, 2 ) + Math.pow( p1.clientY - p0.clientY, 2 ) );

	}
calculateRotationAxis( vec1, vec2 ) {

		this._rotationMatrix.extractRotation( this._cameraMatrixState );
		this._quat.setFromRotationMatrix( this._rotationMatrix );

		this._rotationAxis.crossVectors( vec1, vec2 ).applyQuaternion( this._quat );
		return this._rotationAxis.normalize().clone();

	}
calculateTbRadius( camera ) {

		const distance = camera.position.distanceTo( this._gizmos.position );

		if ( camera.type == 'PerspectiveCamera' ) {

			const halfFovV = MathUtils.DEG2RAD * camera.fov * 0.5; //vertical fov/2 in radians
			const halfFovH = Math.atan( ( camera.aspect ) * Math.tan( halfFovV ) ); //horizontal fov/2 in radians
			return Math.tan( Math.min( halfFovV, halfFovH ) ) * distance * this.radiusFactor;

		} else if ( camera.type == 'OrthographicCamera' ) {

			return Math.min( camera.top, camera.right ) * this.radiusFactor;

		}

	}
focus( point, size, amount = 1 ) {

		//move center of camera (along with gizmos) towards point of interest
		_offset.copy( point ).sub( this._gizmos.position ).multiplyScalar( amount );
		this._translationMatrix.makeTranslation( _offset.x, _offset.y, _offset.z );

		_gizmoMatrixStateTemp.copy( this._gizmoMatrixState );
		this._gizmoMatrixState.premultiply( this._translationMatrix );
		this._gizmoMatrixState.decompose( this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale );

		_cameraMatrixStateTemp.copy( this._cameraMatrixState );
		this._cameraMatrixState.premultiply( this._translationMatrix );
		this._cameraMatrixState.decompose( this.camera.position, this.camera.quaternion, this.camera.scale );

		//apply zoom
		if ( this.enableZoom ) {

			this.applyTransformMatrix( this.scale( size, this._gizmos.position ) );

		}

		this._gizmoMatrixState.copy( _gizmoMatrixStateTemp );
		this._cameraMatrixState.copy( _cameraMatrixStateTemp );

	}
drawGrid() {

		if ( this.scene != null ) {

			const color = 0x888888;
			const multiplier = 3;
			let size, divisions, maxLength, tick;

			if ( this.camera.isOrthographicCamera ) {

				const width = this.camera.right - this.camera.left;
				const height = this.camera.bottom - this.camera.top;

				maxLength = Math.max( width, height );
				tick = maxLength / 20;

				size = maxLength / this.camera.zoom * multiplier;
				divisions = size / tick * this.camera.zoom;

			} else if ( this.camera.isPerspectiveCamera ) {

				const distance = this.camera.position.distanceTo( this._gizmos.position );
				const halfFovV = MathUtils.DEG2RAD * this.camera.fov * 0.5;
				const halfFovH = Math.atan( ( this.camera.aspect ) * Math.tan( halfFovV ) );

				maxLength = Math.tan( Math.max( halfFovV, halfFovH ) ) * distance * 2;
				tick = maxLength / 20;

				size = maxLength * multiplier;
				divisions = size / tick;

			}

			if ( this._grid == null ) {

				this._grid = new GridHelper( size, divisions, color, color );
				this._grid.position.copy( this._gizmos.position );
				this._gridPosition.copy( this._grid.position );
				this._grid.quaternion.copy( this.camera.quaternion );
				this._grid.rotateX( Math.PI * 0.5 );

				this.scene.add( this._grid );

			}

		}

	}
dispose() {

		if ( this._animationId != - 1 ) {

			window.cancelAnimationFrame( this._animationId );

		}

		this.domElement.removeEventListener( 'pointerdown', this._onPointerDown );
		this.domElement.removeEventListener( 'pointercancel', this._onPointerCancel );
		this.domElement.removeEventListener( 'wheel', this._onWheel );
		this.domElement.removeEventListener( 'contextmenu', this._onContextMenu );

		window.removeEventListener( 'pointermove', this._onPointerMove );
		window.removeEventListener( 'pointerup', this._onPointerUp );

		window.removeEventListener( 'resize', this._onWindowResize );

		if ( this.scene !== null ) this.scene.remove( this._gizmos );
		this.disposeGrid();

	}
disposeGrid() {

		if ( this._grid != null && this.scene != null ) {

			this.scene.remove( this._grid );
			this._grid = null;

		}

	}
easeOutCubic( t ) {

		return 1 - Math.pow( 1 - t, 3 );

	}
activateGizmos( isActive ) {

		const gizmoX = this._gizmos.children[ 0 ];
		const gizmoY = this._gizmos.children[ 1 ];
		const gizmoZ = this._gizmos.children[ 2 ];

		if ( isActive ) {

			gizmoX.material.setValues( { opacity: 1 } );
			gizmoY.material.setValues( { opacity: 1 } );
			gizmoZ.material.setValues( { opacity: 1 } );

		} else {

			gizmoX.material.setValues( { opacity: 0.6 } );
			gizmoY.material.setValues( { opacity: 0.6 } );
			gizmoZ.material.setValues( { opacity: 0.6 } );

		}

	}
getCursorNDC( cursorX, cursorY, canvas ) {

		const canvasRect = canvas.getBoundingClientRect();
		this._v2_1.setX( ( ( cursorX - canvasRect.left ) / canvasRect.width ) * 2 - 1 );
		this._v2_1.setY( ( ( canvasRect.bottom - cursorY ) / canvasRect.height ) * 2 - 1 );
		return this._v2_1.clone();

	}
getCursorPosition( cursorX, cursorY, canvas ) {

		this._v2_1.copy( this.getCursorNDC( cursorX, cursorY, canvas ) );
		this._v2_1.x *= ( this.camera.right - this.camera.left ) * 0.5;
		this._v2_1.y *= ( this.camera.top - this.camera.bottom ) * 0.5;
		return this._v2_1.clone();

	}
setCamera( camera ) {

		camera.lookAt( this.target );
		camera.updateMatrix();

		//setting state
		if ( camera.type == 'PerspectiveCamera' ) {

			this._fov0 = camera.fov;
			this._fovState = camera.fov;

		}

		this._cameraMatrixState0.copy( camera.matrix );
		this._cameraMatrixState.copy( this._cameraMatrixState0 );
		this._cameraProjectionState.copy( camera.projectionMatrix );
		this._zoom0 = camera.zoom;
		this._zoomState = this._zoom0;

		this._initialNear = camera.near;
		this._nearPos0 = camera.position.distanceTo( this.target ) - camera.near;
		this._nearPos = this._initialNear;

		this._initialFar = camera.far;
		this._farPos0 = camera.position.distanceTo( this.target ) - camera.far;
		this._farPos = this._initialFar;

		this._up0.copy( camera.up );
		this._upState.copy( camera.up );

		this.camera = camera;
		this.camera.updateProjectionMatrix();

		//making gizmos
		this._tbRadius = this.calculateTbRadius( camera );
		this.makeGizmos( this.target, this._tbRadius );

	}
setGizmosVisible( value ) {

		this._gizmos.visible = value;
		this.dispatchEvent( _changeEvent );

	}