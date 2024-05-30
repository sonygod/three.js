zRotate( point, angle ) {

		this._rotationMatrix.makeRotationAxis( this._rotationAxis, angle );
		this._translationMatrix.makeTranslation( - point.x, - point.y, - point.z );

		this._m4_1.makeTranslation( point.x, point.y, point.z );
		this._m4_1.multiply( this._rotationMatrix );
		this._m4_1.multiply( this._translationMatrix );

		this._v3_1.setFromMatrixPosition( this._gizmoMatrixState ).sub( point );	//vector from rotation center to gizmos position
		this._v3_2.copy( this._v3_1 ).applyAxisAngle( this._rotationAxis, angle );	//apply rotation
		this._v3_2.sub( this._v3_1 );

		this._m4_2.makeTranslation( this._v3_2.x, this._v3_2.y, this._v3_2.z );

		this.setTransformationMatrices( this._m4_1, this._m4_2 );
		return _transformation;

	}
getRaycaster() {

		return _raycaster;

	}
unprojectOnObj( cursor, camera ) {

		const raycaster = this.getRaycaster();
		raycaster.near = camera.near;
		raycaster.far = camera.far;
		raycaster.setFromCamera( cursor, camera );

		const intersect = raycaster.intersectObjects( this.scene.children, true );

		for ( let i = 0; i < intersect.length; i ++ ) {

			if ( intersect[ i ].object.uuid != this._gizmos.uuid && intersect[ i ].face != null ) {

				return intersect[ i ].point.clone();

			}

		}

		return null;

	}
unprojectOnTbSurface( camera, cursorX, cursorY, canvas, tbRadius ) {

		if ( camera.type == 'OrthographicCamera' ) {

			this._v2_1.copy( this.getCursorPosition( cursorX, cursorY, canvas ) );
			this._v3_1.set( this._v2_1.x, this._v2_1.y, 0 );

			const x2 = Math.pow( this._v2_1.x, 2 );
			const y2 = Math.pow( this._v2_1.y, 2 );
			const r2 = Math.pow( this._tbRadius, 2 );

			if ( x2 + y2 <= r2 * 0.5 ) {

				//intersection with sphere
				this._v3_1.setZ( Math.sqrt( r2 - ( x2 + y2 ) ) );

			} else {

				//intersection with hyperboloid
				this._v3_1.setZ( ( r2 * 0.5 ) / ( Math.sqrt( x2 + y2 ) ) );

			}

			return this._v3_1;

		} else if ( camera.type == 'PerspectiveCamera' ) {

			//unproject cursor on the near plane
			this._v2_1.copy( this.getCursorNDC( cursorX, cursorY, canvas ) );

			this._v3_1.set( this._v2_1.x, this._v2_1.y, - 1 );
			this._v3_1.applyMatrix4( camera.projectionMatrixInverse );

			const rayDir = this._v3_1.clone().normalize(); //unprojected ray direction
			const cameraGizmoDistance = camera.position.distanceTo( this._gizmos.position );
			const radius2 = Math.pow( tbRadius, 2 );

			//	  camera
			//		|\
			//		| \
			//		|  \
			//	h	|	\
			//		| 	 \
			//		| 	  \
			//	_ _ | _ _ _\ _ _  near plane
			//			l

			const h = this._v3_1.z;
			const l = Math.sqrt( Math.pow( this._v3_1.x, 2 ) + Math.pow( this._v3_1.y, 2 ) );

			if ( l == 0 ) {

				//ray aligned with camera
				rayDir.set( this._v3_1.x, this._v3_1.y, tbRadius );
				return rayDir;

			}

			const m = h / l;
			const q = cameraGizmoDistance;

			/*
			 * calculate intersection point between unprojected ray and trackball surface
			 *|y = m * x + q
			 *|x^2 + y^2 = r^2
			 *
			 * (m^2 + 1) * x^2 + (2 * m * q) * x + q^2 - r^2 = 0
			 */
			let a = Math.pow( m, 2 ) + 1;
			let b = 2 * m * q;
			let c = Math.pow( q, 2 ) - radius2;
			let delta = Math.pow( b, 2 ) - ( 4 * a * c );

			if ( delta >= 0 ) {

				//intersection with sphere
				this._v2_1.setX( ( - b - Math.sqrt( delta ) ) / ( 2 * a ) );
				this._v2_1.setY( m * this._v2_1.x + q );

				const angle = MathUtils.RAD2DEG * this._v2_1.angle();

				if ( angle >= 45 ) {

					//if angle between intersection point and X' axis is >= 45°, return that point
					//otherwise, calculate intersection point with hyperboloid

					const rayLength = Math.sqrt( Math.pow( this._v2_1.x, 2 ) + Math.pow( ( cameraGizmoDistance - this._v2_1.y ), 2 ) );
					rayDir.multiplyScalar( rayLength );
					rayDir.z += cameraGizmoDistance;
					return rayDir;

				}

			}

			//intersection with hyperboloid
			/*
			 *|y = m * x + q
			 *|y = (1 / x) * (r^2 / 2)
			 *
			 * m * x^2 + q * x - r^2 / 2 = 0
			 */

			a = m;
			b = q;
			c = - radius2 * 0.5;
			delta = Math.pow( b, 2 ) - ( 4 * a * c );
			this._v2_1.setX( ( - b - Math.sqrt( delta ) ) / ( 2 * a ) );
			this._v2_1.setY( m * this._v2_1.x + q );

			const rayLength = Math.sqrt( Math.pow( this._v2_1.x, 2 ) + Math.pow( ( cameraGizmoDistance - this._v2_1.y ), 2 ) );

			rayDir.multiplyScalar( rayLength );
			rayDir.z += cameraGizmoDistance;
			return rayDir;

		}

	}
unprojectOnTbPlane( camera, cursorX, cursorY, canvas, initialDistance = false ) {

		if ( camera.type == 'OrthographicCamera' ) {

			this._v2_1.copy( this.getCursorPosition( cursorX, cursorY, canvas ) );
			this._v3_1.set( this._v2_1.x, this._v2_1.y, 0 );

			return this._v3_1.clone();

		} else if ( camera.type == 'PerspectiveCamera' ) {

			this._v2_1.copy( this.getCursorNDC( cursorX, cursorY, canvas ) );

			//unproject cursor on the near plane
			this._v3_1.set( this._v2_1.x, this._v2_1.y, - 1 );
			this._v3_1.applyMatrix4( camera.projectionMatrixInverse );

			const rayDir = this._v3_1.clone().normalize(); //unprojected ray direction

			//	  camera
			//		|\
			//		| \
			//		|  \
			//	h	|	\
			//		| 	 \
			//		| 	  \
			//	_ _ | _ _ _\ _ _  near plane
			//			l

			const h = this._v3_1.z;
			const l = Math.sqrt( Math.pow( this._v3_1.x, 2 ) + Math.pow( this._v3_1.y, 2 ) );
			let cameraGizmoDistance;

			if ( initialDistance ) {

				cameraGizmoDistance = this._v3_1.setFromMatrixPosition( this._cameraMatrixState0 ).distanceTo( this._v3_2.setFromMatrixPosition( this._gizmoMatrixState0 ) );

			} else {

				cameraGizmoDistance = camera.position.distanceTo( this._gizmos.position );

			}

			/*
			 * calculate intersection point between unprojected ray and the plane
			 *|y = mx + q
			 *|y = 0
			 *
			 * x = -q/m
			*/
			if ( l == 0 ) {

				//ray aligned with camera
				rayDir.set( 0, 0, 0 );
				return rayDir;

			}

			const m = h / l;
			const q = cameraGizmoDistance;
			const x = - q / m;

			const rayLength = Math.sqrt( Math.pow( q, 2 ) + Math.pow( x, 2 ) );
			rayDir.multiplyScalar( rayLength );
			rayDir.z = 0;
			return rayDir;

		}

	}
updateMatrixState() {

		//update camera and gizmos state
		this._cameraMatrixState.copy( this.camera.matrix );
		this._gizmoMatrixState.copy( this._gizmos.matrix );

		if ( this.camera.isOrthographicCamera ) {

			this._cameraProjectionState.copy( this.camera.projectionMatrix );
			this.camera.updateProjectionMatrix();
			this._zoomState = this.camera.zoom;

		} else if ( this.camera.isPerspectiveCamera ) {

			this._fovState = this.camera.fov;

		}

	}
updateTbState( newState, updateMatrices ) {

		this._state = newState;
		if ( updateMatrices ) {

			this.updateMatrixState();

		}

	}
update() {

		const EPS = 0.000001;

		if ( this.target.equals( this._currentTarget ) === false ) {

			this._gizmos.position.copy( this.target );	//for correct radius calculation
			this._tbRadius = this.calculateTbRadius( this.camera );
			this.makeGizmos( this.target, this._tbRadius );
			this._currentTarget.copy( this.target );

		}

		//check min/max parameters
		if ( this.camera.isOrthographicCamera ) {

			//check zoom
			if ( this.camera.zoom > this.maxZoom || this.camera.zoom < this.minZoom ) {

				const newZoom = MathUtils.clamp( this.camera.zoom, this.minZoom, this.maxZoom );
				this.applyTransformMatrix( this.scale( newZoom / this.camera.zoom, this._gizmos.position, true ) );

			}

		} else if ( this.camera.isPerspectiveCamera ) {

			//check distance
			const distance = this.camera.position.distanceTo( this._gizmos.position );

			if ( distance > this.maxDistance + EPS || distance < this.minDistance - EPS ) {

				const newDistance = MathUtils.clamp( distance, this.minDistance, this.maxDistance );
				this.applyTransformMatrix( this.scale( newDistance / distance, this._gizmos.position ) );
				this.updateMatrixState();

			 }

			//check fov
			if ( this.camera.fov < this.minFov || this.camera.fov > this.maxFov ) {

				this.camera.fov = MathUtils.clamp( this.camera.fov, this.minFov, this.maxFov );
				this.camera.updateProjectionMatrix();

			}

			const oldRadius = this._tbRadius;
			this._tbRadius = this.calculateTbRadius( this.camera );

			if ( oldRadius < this._tbRadius - EPS || oldRadius > this._tbRadius + EPS ) {

				const scale = ( this._gizmos.scale.x + this._gizmos.scale.y + this._gizmos.scale.z ) / 3;
				const newRadius = this._tbRadius / scale;
				const curve = new EllipseCurve( 0, 0, newRadius, newRadius );
				const points = curve.getPoints( this._curvePts );
				const curveGeometry = new BufferGeometry().setFromPoints( points );

				for ( const gizmo in this._gizmos.children ) {

					this._gizmos.children[ gizmo ].geometry = curveGeometry;

				}

			}

		}

		this.camera.lookAt( this._gizmos.position );

	}
setStateFromJSON( json ) {

		const state = JSON.parse( json );

		if ( state.arcballState != undefined ) {

			this._cameraMatrixState.fromArray( state.arcballState.cameraMatrix.elements );
			this._cameraMatrixState.decompose( this.camera.position, this.camera.quaternion, this.camera.scale );

			this.camera.up.copy( state.arcballState.cameraUp );
			this.camera.near = state.arcballState.cameraNear;
			this.camera.far = state.arcballState.cameraFar;

			this.camera.zoom = state.arcballState.cameraZoom;

			if ( this.camera.isPerspectiveCamera ) {

				this.camera.fov = state.arcballState.cameraFov;

			}

			this._gizmoMatrixState.fromArray( state.arcballState.gizmoMatrix.elements );
			this._gizmoMatrixState.decompose( this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale );

			this.camera.updateMatrix();
			this.camera.updateProjectionMatrix();

			this._gizmos.updateMatrix();

			this._tbRadius = this.calculateTbRadius( this.camera );
			const gizmoTmp = new Matrix4().copy( this._gizmoMatrixState0 );
			this.makeGizmos( this._gizmos.position, this._tbRadius );
			this._gizmoMatrixState0.copy( gizmoTmp );

			this.camera.lookAt( this._gizmos.position );
			this.updateTbState( STATE.IDLE, false );

			this.dispatchEvent( _changeEvent );

		}

	}


}


//listeners

function onWindowResize() {

	const scale = ( this._gizmos.scale.x + this._gizmos.scale.y + this._gizmos.scale.z ) / 3;
	this._tbRadius = this.calculateTbRadius( this.camera );

	const newRadius = this._tbRadius / scale;
	const curve = new EllipseCurve( 0, 0, newRadius, newRadius );
	const points = curve.getPoints( this._curvePts );
	const curveGeometry = new BufferGeometry().setFromPoints( points );


	for ( const gizmo in this._gizmos.children ) {

		this._gizmos.children[ gizmo ].geometry = curveGeometry;

	}

	this.dispatchEvent( _changeEvent );

}

function onContextMenu( event ) {

	if ( ! this.enabled ) {

		return;

	}

	for ( let i = 0; i < this.mouseActions.length; i ++ ) {

		if ( this.mouseActions[ i ].mouse == 2 ) {

			//prevent only if button 2 is actually used
			event.preventDefault();
			break;

		}

	}

}

function onPointerCancel() {

	this._touchStart.splice( 0, this._touchStart.length );
	this._touchCurrent.splice( 0, this._touchCurrent.length );
	this._input = INPUT.NONE;

}

function onPointerDown( event ) {

	if ( event.button == 0 && event.isPrimary ) {

		this._downValid = true;
		this._downEvents.push( event );
		this._downStart = performance.now();

	} else {

		this._downValid = false;

	}

	if ( event.pointerType == 'touch' && this._input != INPUT.CURSOR ) {

		this._touchStart.push( event );
		this._touchCurrent.push( event );

		switch ( this._input ) {

			case INPUT.NONE:

				//singleStart
				this._input = INPUT.ONE_FINGER;
				this.onSinglePanStart( event, 'ROTATE' );

				window.addEventListener( 'pointermove', this._onPointerMove );
				window.addEventListener( 'pointerup', this._onPointerUp );

				break;

			case INPUT.ONE_FINGER:
			case INPUT.ONE_FINGER_SWITCHED:

				//doubleStart
				this._input = INPUT.TWO_FINGER;

				this.onRotateStart();
				this.onPinchStart();
				this.onDoublePanStart();

				break;

			case INPUT.TWO_FINGER:

				//multipleStart
				this._input = INPUT.MULT_FINGER;
				this.onTriplePanStart( event );
				break;

		}

	} else if ( event.pointerType != 'touch' && this._input == INPUT.NONE ) {

		let modifier = null;

		if ( event.ctrlKey || event.metaKey ) {

			modifier = 'CTRL';

		} else if ( event.shiftKey ) {

			modifier = 'SHIFT';

		}

		this._mouseOp = this.getOpFromAction( event.button, modifier );
		if ( this._mouseOp != null ) {

			window.addEventListener( 'pointermove', this._onPointerMove );
			window.addEventListener( 'pointerup', this._onPointerUp );

			//singleStart
			this._input = INPUT.CURSOR;
			this._button = event.button;
			this.onSinglePanStart( event, this._mouseOp );

		}

	}

}

function onPointerMove( event ) {

	if ( event.pointerType == 'touch' && this._input != INPUT.CURSOR ) {

		switch ( this._input ) {

			case INPUT.ONE_FINGER:

				//singleMove
				this.updateTouchEvent( event );

				this.onSinglePanMove( event, STATE.ROTATE );
				break;

			case INPUT.ONE_FINGER_SWITCHED:

				const movement = this.calculatePointersDistance( this._touchCurrent[ 0 ], event ) * this._devPxRatio;

				if ( movement >= this._switchSensibility ) {

					//singleMove
					this._input = INPUT.ONE_FINGER;
					this.updateTouchEvent( event );

					this.onSinglePanStart( event, 'ROTATE' );
					break;

				}

				break;

			case INPUT.TWO_FINGER:

				//rotate/pan/pinchMove
				this.updateTouchEvent( event );

				this.onRotateMove();
				this.onPinchMove();
				this.onDoublePanMove();

				break;

			case INPUT.MULT_FINGER:

				//multMove
				this.updateTouchEvent( event );

				this.onTriplePanMove( event );
				break;

		}

	} else if ( event.pointerType != 'touch' && this._input == INPUT.CURSOR ) {

		let modifier = null;

		if ( event.ctrlKey || event.metaKey ) {

			modifier = 'CTRL';

		} else if ( event.shiftKey ) {

			modifier = 'SHIFT';

		}

		const mouseOpState = this.getOpStateFromAction( this._button, modifier );

		if ( mouseOpState != null ) {

			this.onSinglePanMove( event, mouseOpState );

		}

	}

	//checkDistance
	if ( this._downValid ) {

		const movement = this.calculatePointersDistance( this._downEvents[ this._downEvents.length - 1 ], event ) * this._devPxRatio;
		if ( movement > this._movementThreshold ) {

			this._downValid = false;

		}

	}

}

function onPointerUp( event ) {

	if ( event.pointerType == 'touch' && this._input != INPUT.CURSOR ) {

		const nTouch = this._touchCurrent.length;

		for ( let i = 0; i < nTouch; i ++ ) {

			if ( this._touchCurrent[ i ].pointerId == event.pointerId ) {

				this._touchCurrent.splice( i, 1 );
				this._touchStart.splice( i, 1 );
				break;

			}

		}

		switch ( this._input ) {

			case INPUT.ONE_FINGER:
			case INPUT.ONE_FINGER_SWITCHED:

				//singleEnd
				window.removeEventListener( 'pointermove', this._onPointerMove );
				window.removeEventListener( 'pointerup', this._onPointerUp );

				this._input = INPUT.NONE;
				this.onSinglePanEnd();

				break;

			case INPUT.TWO_FINGER:

				//doubleEnd
				this.onDoublePanEnd( event );
				this.onPinchEnd( event );
				this.onRotateEnd( event );

				//switching to singleStart
				this._input = INPUT.ONE_FINGER_SWITCHED;

				break;

			case INPUT.MULT_FINGER:

				if ( this._touchCurrent.length == 0 ) {

					window.removeEventListener( 'pointermove', this._onPointerMove );
					window.removeEventListener( 'pointerup', this._onPointerUp );

					//multCancel
					this._input = INPUT.NONE;
					this.onTriplePanEnd();

				}

				break;

		}

	} else if ( event.pointerType != 'touch' && this._input == INPUT.CURSOR ) {

		window.removeEventListener( 'pointermove', this._onPointerMove );
		window.removeEventListener( 'pointerup', this._onPointerUp );

		this._input = INPUT.NONE;
		this.onSinglePanEnd();
		this._button = - 1;

	}

	if ( event.isPrimary ) {

		if ( this._downValid ) {

			const downTime = event.timeStamp - this._downEvents[ this._downEvents.length - 1 ].timeStamp;

			if ( downTime <= this._maxDownTime ) {

				if ( this._nclicks == 0 ) {

					//first valid click detected
					this._nclicks = 1;
					this._clickStart = performance.now();

				} else {

					const clickInterval = event.timeStamp - this._clickStart;
					const movement = this.calculatePointersDistance( this._downEvents[ 1 ], this._downEvents[ 0 ] ) * this._devPxRatio;

					if ( clickInterval <= this._maxInterval && movement <= this._posThreshold ) {

						//second valid click detected
						//fire double tap and reset values
						this._nclicks = 0;
						this._downEvents.splice( 0, this._downEvents.length );
						this.onDoubleTap( event );

					} else {

						//new 'first click'
						this._nclicks = 1;
						this._downEvents.shift();
						this._clickStart = performance.now();

					}

				}

			} else {

				this._downValid = false;
				this._nclicks = 0;
				this._downEvents.splice( 0, this._downEvents.length );

			}

		} else {

			this._nclicks = 0;
			this._downEvents.splice( 0, this._downEvents.length );

		}

	}

}

function onWheel( event ) {

	if ( this.enabled && this.enableZoom ) {

		let modifier = null;

		if ( event.ctrlKey || event.metaKey ) {

			modifier = 'CTRL';

		} else if ( event.shiftKey ) {

			modifier = 'SHIFT';

		}

		const mouseOp = this.getOpFromAction( 'WHEEL', modifier );

		if ( mouseOp != null ) {

			event.preventDefault();
			this.dispatchEvent( _startEvent );

			const notchDeltaY = 125; //distance of one notch of mouse wheel
			let sgn = event.deltaY / notchDeltaY;

			let size = 1;

			if ( sgn > 0 ) {

				size = 1 / this.scaleFactor;

			} else if ( sgn < 0 ) {

				size = this.scaleFactor;

			}

			switch ( mouseOp ) {

				case 'ZOOM':

					this.updateTbState( STATE.SCALE, true );

					if ( sgn > 0 ) {

						size = 1 / ( Math.pow( this.scaleFactor, sgn ) );

					} else if ( sgn < 0 ) {

						size = Math.pow( this.scaleFactor, - sgn );

					}

					if ( this.cursorZoom && this.enablePan ) {

						let scalePoint;

						if ( this.camera.isOrthographicCamera ) {

							scalePoint = this.unprojectOnTbPlane( this.camera, event.clientX, event.clientY, this.domElement ).applyQuaternion( this.camera.quaternion ).multiplyScalar( 1 / this.camera.zoom ).add( this._gizmos.position );

						} else if ( this.camera.isPerspectiveCamera ) {

							scalePoint = this.unprojectOnTbPlane( this.camera, event.clientX, event.clientY, this.domElement ).applyQuaternion( this.camera.quaternion ).add( this._gizmos.position );

						}

						this.applyTransformMatrix( this.scale( size, scalePoint ) );

					} else {

						this.applyTransformMatrix( this.scale( size, this._gizmos.position ) );

					}

					if ( this._grid != null ) {

						this.disposeGrid();
						this.drawGrid();

					}

					this.updateTbState( STATE.IDLE, false );

					this.dispatchEvent( _changeEvent );
					this.dispatchEvent( _endEvent );

					break;

				case 'FOV':

					if ( this.camera.isPerspectiveCamera ) {

						this.updateTbState( STATE.FOV, true );


						//Vertigo effect

						//	  fov / 2
						//		|\
						//		| \
						//		|  \
						//	x	|	\
						//		| 	 \
						//		| 	  \
						//		| _ _ _\
						//			y

						//check for iOs shift shortcut
						if ( event.deltaX != 0 ) {

							sgn = event.deltaX / notchDeltaY;

							size = 1;

							if ( sgn > 0 ) {

								size = 1 / ( Math.pow( this.scaleFactor, sgn ) );

							} else if ( sgn < 0 ) {

								size = Math.pow( this.scaleFactor, - sgn );

							}

						}

						this._v3_1.setFromMatrixPosition( this._cameraMatrixState );
						const x = this._v3_1.distanceTo( this._gizmos.position );
						let xNew = x / size;	//distance between camera and gizmos if scale(size, scalepoint) would be performed

						//check min and max distance
						xNew = MathUtils.clamp( xNew, this.minDistance, this.maxDistance );

						const y = x * Math.tan( MathUtils.DEG2RAD * this.camera.fov * 0.5 );

						//calculate new fov
						let newFov = MathUtils.RAD2DEG * ( Math.atan( y / xNew ) * 2 );

						//check min and max fov
						if ( newFov > this.maxFov ) {

							newFov = this.maxFov;

						} else if ( newFov < this.minFov ) {

							newFov = this.minFov;

						}

						const newDistance = y / Math.tan( MathUtils.DEG2RAD * ( newFov / 2 ) );
						size = x / newDistance;

						this.setFov( newFov );
						this.applyTransformMatrix( this.scale( size, this._gizmos.position, false ) );

					}

					if ( this._grid != null ) {

						this.disposeGrid();
						this.drawGrid();

					}

					this.updateTbState( STATE.IDLE, false );

					this.dispatchEvent( _changeEvent );
					this.dispatchEvent( _endEvent );

					break;

			}

		}

	}

}

export { ArcballControls };
