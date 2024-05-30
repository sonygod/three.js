onSinglePanEnd() {

		if ( this._state == STATE.ROTATE ) {


			if ( ! this.enableRotate ) {

				return;

			}

			if ( this.enableAnimations ) {

				//perform rotation animation
				const deltaTime = ( performance.now() - this._timeCurrent );
				if ( deltaTime < 120 ) {

					const w = Math.abs( ( this._wPrev + this._wCurr ) / 2 );

					const self = this;
					this._animationId = window.requestAnimationFrame( function ( t ) {

						self.updateTbState( STATE.ANIMATION_ROTATE, true );
						const rotationAxis = self.calculateRotationAxis( self._cursorPosPrev, self._cursorPosCurr );

						self.onRotationAnim( t, rotationAxis, Math.min( w, self.wMax ) );

					} );

				} else {

					//cursor has been standing still for over 120 ms since last movement
					this.updateTbState( STATE.IDLE, false );
					this.activateGizmos( false );
					this.dispatchEvent( _changeEvent );

				}

			} else {

				this.updateTbState( STATE.IDLE, false );
				this.activateGizmos( false );
				this.dispatchEvent( _changeEvent );

			}

		} else if ( this._state == STATE.PAN || this._state == STATE.IDLE ) {

			this.updateTbState( STATE.IDLE, false );

			if ( this.enableGrid ) {

				this.disposeGrid();

			}

			this.activateGizmos( false );
			this.dispatchEvent( _changeEvent );


		}

		this.dispatchEvent( _endEvent );

	}
onDoubleTap( event ) {

		if ( this.enabled && this.enablePan && this.scene != null ) {

			this.dispatchEvent( _startEvent );

			this.setCenter( event.clientX, event.clientY );
			const hitP = this.unprojectOnObj( this.getCursorNDC( _center.x, _center.y, this.domElement ), this.camera );

			if ( hitP != null && this.enableAnimations ) {

				const self = this;
				if ( this._animationId != - 1 ) {

					window.cancelAnimationFrame( this._animationId );

				}

				this._timeStart = - 1;
				this._animationId = window.requestAnimationFrame( function ( t ) {

					self.updateTbState( STATE.ANIMATION_FOCUS, true );
					self.onFocusAnim( t, hitP, self._cameraMatrixState, self._gizmoMatrixState );

				} );

			} else if ( hitP != null && ! this.enableAnimations ) {

				this.updateTbState( STATE.FOCUS, true );
				this.focus( hitP, this.scaleFactor );
				this.updateTbState( STATE.IDLE, false );
				this.dispatchEvent( _changeEvent );

			}

		}

		this.dispatchEvent( _endEvent );

	}
onDoublePanStart() {

		if ( this.enabled && this.enablePan ) {

			this.dispatchEvent( _startEvent );

			this.updateTbState( STATE.PAN, true );

			this.setCenter( ( this._touchCurrent[ 0 ].clientX + this._touchCurrent[ 1 ].clientX ) / 2, ( this._touchCurrent[ 0 ].clientY + this._touchCurrent[ 1 ].clientY ) / 2 );
			this._startCursorPosition.copy( this.unprojectOnTbPlane( this.camera, _center.x, _center.y, this.domElement, true ) );
			this._currentCursorPosition.copy( this._startCursorPosition );

			this.activateGizmos( false );

		}

	}
onDoublePanMove() {

		if ( this.enabled && this.enablePan ) {

			this.setCenter( ( this._touchCurrent[ 0 ].clientX + this._touchCurrent[ 1 ].clientX ) / 2, ( this._touchCurrent[ 0 ].clientY + this._touchCurrent[ 1 ].clientY ) / 2 );

			if ( this._state != STATE.PAN ) {

				this.updateTbState( STATE.PAN, true );
				this._startCursorPosition.copy( this._currentCursorPosition );

			}

			this._currentCursorPosition.copy( this.unprojectOnTbPlane( this.camera, _center.x, _center.y, this.domElement, true ) );
			this.applyTransformMatrix( this.pan( this._startCursorPosition, this._currentCursorPosition, true ) );
			this.dispatchEvent( _changeEvent );

		}

	}
onDoublePanEnd() {

		this.updateTbState( STATE.IDLE, false );
		this.dispatchEvent( _endEvent );

	}
onRotateStart() {

		if ( this.enabled && this.enableRotate ) {

			this.dispatchEvent( _startEvent );

			this.updateTbState( STATE.ZROTATE, true );

			//this._startFingerRotation = event.rotation;

			this._startFingerRotation = this.getAngle( this._touchCurrent[ 1 ], this._touchCurrent[ 0 ] ) + this.getAngle( this._touchStart[ 1 ], this._touchStart[ 0 ] );
			this._currentFingerRotation = this._startFingerRotation;

			this.camera.getWorldDirection( this._rotationAxis ); //rotation axis

			if ( ! this.enablePan && ! this.enableZoom ) {

				this.activateGizmos( true );

			}

		}

	}
onRotateMove() {

		if ( this.enabled && this.enableRotate ) {

			this.setCenter( ( this._touchCurrent[ 0 ].clientX + this._touchCurrent[ 1 ].clientX ) / 2, ( this._touchCurrent[ 0 ].clientY + this._touchCurrent[ 1 ].clientY ) / 2 );
			let rotationPoint;

			if ( this._state != STATE.ZROTATE ) {

				this.updateTbState( STATE.ZROTATE, true );
				this._startFingerRotation = this._currentFingerRotation;

			}

			//this._currentFingerRotation = event.rotation;
			this._currentFingerRotation = this.getAngle( this._touchCurrent[ 1 ], this._touchCurrent[ 0 ] ) + this.getAngle( this._touchStart[ 1 ], this._touchStart[ 0 ] );

			if ( ! this.enablePan ) {

				rotationPoint = new Vector3().setFromMatrixPosition( this._gizmoMatrixState );

			} else {

				this._v3_2.setFromMatrixPosition( this._gizmoMatrixState );
				rotationPoint = this.unprojectOnTbPlane( this.camera, _center.x, _center.y, this.domElement ).applyQuaternion( this.camera.quaternion ).multiplyScalar( 1 / this.camera.zoom ).add( this._v3_2 );

			}

			const amount = MathUtils.DEG2RAD * ( this._startFingerRotation - this._currentFingerRotation );

			this.applyTransformMatrix( this.zRotate( rotationPoint, amount ) );
			this.dispatchEvent( _changeEvent );

		}

	}
onRotateEnd() {

		this.updateTbState( STATE.IDLE, false );
		this.activateGizmos( false );
		this.dispatchEvent( _endEvent );

	}
onPinchStart() {

		if ( this.enabled && this.enableZoom ) {

			this.dispatchEvent( _startEvent );
			this.updateTbState( STATE.SCALE, true );

			this._startFingerDistance = this.calculatePointersDistance( this._touchCurrent[ 0 ], this._touchCurrent[ 1 ] );
			this._currentFingerDistance = this._startFingerDistance;

			this.activateGizmos( false );

		}

	}
onPinchMove() {

		if ( this.enabled && this.enableZoom ) {

			this.setCenter( ( this._touchCurrent[ 0 ].clientX + this._touchCurrent[ 1 ].clientX ) / 2, ( this._touchCurrent[ 0 ].clientY + this._touchCurrent[ 1 ].clientY ) / 2 );
			const minDistance = 12; //minimum distance between fingers (in css pixels)

			if ( this._state != STATE.SCALE ) {

				this._startFingerDistance = this._currentFingerDistance;
				this.updateTbState( STATE.SCALE, true );

			}

			this._currentFingerDistance = Math.max( this.calculatePointersDistance( this._touchCurrent[ 0 ], this._touchCurrent[ 1 ] ), minDistance * this._devPxRatio );
			const amount = this._currentFingerDistance / this._startFingerDistance;

			let scalePoint;

			if ( ! this.enablePan ) {

				scalePoint = this._gizmos.position;

			} else {

				if ( this.camera.isOrthographicCamera ) {

					scalePoint = this.unprojectOnTbPlane( this.camera, _center.x, _center.y, this.domElement )
						.applyQuaternion( this.camera.quaternion )
						.multiplyScalar( 1 / this.camera.zoom )
						.add( this._gizmos.position );

				} else if ( this.camera.isPerspectiveCamera ) {

					scalePoint = this.unprojectOnTbPlane( this.camera, _center.x, _center.y, this.domElement )
						.applyQuaternion( this.camera.quaternion )
						.add( this._gizmos.position );

				}

			}

			this.applyTransformMatrix( this.scale( amount, scalePoint ) );
			this.dispatchEvent( _changeEvent );

		}

	}
onPinchEnd() {

		this.updateTbState( STATE.IDLE, false );
		this.dispatchEvent( _endEvent );

	}
onTriplePanStart() {

		if ( this.enabled && this.enableZoom ) {

			this.dispatchEvent( _startEvent );

			this.updateTbState( STATE.SCALE, true );

			//const center = event.center;
			let clientX = 0;
			let clientY = 0;
			const nFingers = this._touchCurrent.length;

			for ( let i = 0; i < nFingers; i ++ ) {

				clientX += this._touchCurrent[ i ].clientX;
				clientY += this._touchCurrent[ i ].clientY;

			}

			this.setCenter( clientX / nFingers, clientY / nFingers );

			this._startCursorPosition.setY( this.getCursorNDC( _center.x, _center.y, this.domElement ).y * 0.5 );
			this._currentCursorPosition.copy( this._startCursorPosition );

		}

	}
onTriplePanMove() {

		if ( this.enabled && this.enableZoom ) {

			//	  fov / 2
			//		|\
			//		| \
			//		|  \
			//	x	|	\
			//		| 	 \
			//		| 	  \
			//		| _ _ _\
			//			y

			//const center = event.center;
			let clientX = 0;
			let clientY = 0;
			const nFingers = this._touchCurrent.length;

			for ( let i = 0; i < nFingers; i ++ ) {

				clientX += this._touchCurrent[ i ].clientX;
				clientY += this._touchCurrent[ i ].clientY;

			}

			this.setCenter( clientX / nFingers, clientY / nFingers );

			const screenNotches = 8;	//how many wheel notches corresponds to a full screen pan
			this._currentCursorPosition.setY( this.getCursorNDC( _center.x, _center.y, this.domElement ).y * 0.5 );

			const movement = this._currentCursorPosition.y - this._startCursorPosition.y;

			let size = 1;

			if ( movement < 0 ) {

				size = 1 / ( Math.pow( this.scaleFactor, - movement * screenNotches ) );

			} else if ( movement > 0 ) {

				size = Math.pow( this.scaleFactor, movement * screenNotches );

			}

			this._v3_1.setFromMatrixPosition( this._cameraMatrixState );
			const x = this._v3_1.distanceTo( this._gizmos.position );
			let xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

			//check min and max distance
			xNew = MathUtils.clamp( xNew, this.minDistance, this.maxDistance );

			const y = x * Math.tan( MathUtils.DEG2RAD * this._fovState * 0.5 );

			//calculate new fov
			let newFov = MathUtils.RAD2DEG * ( Math.atan( y / xNew ) * 2 );

			//check min and max fov
			newFov = MathUtils.clamp( newFov, this.minFov, this.maxFov );

			const newDistance = y / Math.tan( MathUtils.DEG2RAD * ( newFov / 2 ) );
			size = x / newDistance;
			this._v3_2.setFromMatrixPosition( this._gizmoMatrixState );

			this.setFov( newFov );
			this.applyTransformMatrix( this.scale( size, this._v3_2, false ) );

			//adjusting distance
			_offset.copy( this._gizmos.position ).sub( this.camera.position ).normalize().multiplyScalar( newDistance / x );
			this._m4_1.makeTranslation( _offset.x, _offset.y, _offset.z );

			this.dispatchEvent( _changeEvent );

		}

	}
onTriplePanEnd() {

		this.updateTbState( STATE.IDLE, false );
		this.dispatchEvent( _endEvent );
		//this.dispatchEvent( _changeEvent );

	}
setCenter( clientX, clientY ) {

		_center.x = clientX;
		_center.y = clientY;

	}
initializeMouseActions() {

		this.setMouseAction( 'PAN', 0, 'CTRL' );
		this.setMouseAction( 'PAN', 2 );

		this.setMouseAction( 'ROTATE', 0 );

		this.setMouseAction( 'ZOOM', 'WHEEL' );
		this.setMouseAction( 'ZOOM', 1 );

		this.setMouseAction( 'FOV', 'WHEEL', 'SHIFT' );
		this.setMouseAction( 'FOV', 1, 'SHIFT' );


	}
compareMouseAction( action1, action2 ) {

		if ( action1.operation == action2.operation ) {

			if ( action1.mouse == action2.mouse && action1.key == action2.key ) {

				return true;

			} else {

				return false;

			}

		} else {

			return false;

		}

	}