getMaxAnisotropy() {

		return this.backend.getMaxAnisotropy();

	}
getActiveCubeFace() {

		return this._activeCubeFace;

	}
getActiveMipmapLevel() {

		return this._activeMipmapLevel;

	}
async setAnimationLoop( callback ) {

		if ( this._initialized === false ) await this.init();

		this._animation.setAnimationLoop( callback );

	}
getArrayBuffer( attribute ) { // @deprecated, r155

		console.warn( 'THREE.Renderer: getArrayBuffer() is deprecated. Use getArrayBufferAsync() instead.' );

		return this.getArrayBufferAsync( attribute );

	}
async getArrayBufferAsync( attribute ) {

		return await this.backend.getArrayBufferAsync( attribute );

	}
getContext() {

		return this.backend.getContext();

	}
getPixelRatio() {

		return this._pixelRatio;

	}
getDrawingBufferSize( target ) {

		return target.set( this._width * this._pixelRatio, this._height * this._pixelRatio ).floor();

	}
getSize( target ) {

		return target.set( this._width, this._height );

	}
setPixelRatio( value = 1 ) {

		this._pixelRatio = value;

		this.setSize( this._width, this._height, false );

	}
setDrawingBufferSize( width, height, pixelRatio ) {

		this._width = width;
		this._height = height;

		this._pixelRatio = pixelRatio;

		this.domElement.width = Math.floor( width * pixelRatio );
		this.domElement.height = Math.floor( height * pixelRatio );

		this.setViewport( 0, 0, width, height );

		if ( this._initialized ) this.backend.updateSize();

	}
setSize( width, height, updateStyle = true ) {

		this._width = width;
		this._height = height;

		this.domElement.width = Math.floor( width * this._pixelRatio );
		this.domElement.height = Math.floor( height * this._pixelRatio );

		if ( updateStyle === true ) {

			this.domElement.style.width = width + 'px';
			this.domElement.style.height = height + 'px';

		}

		this.setViewport( 0, 0, width, height );

		if ( this._initialized ) this.backend.updateSize();

	}
setOpaqueSort( method ) {

		this._opaqueSort = method;

	}
setTransparentSort( method ) {

		this._transparentSort = method;

	}
getScissor( target ) {

		const scissor = this._scissor;

		target.x = scissor.x;
		target.y = scissor.y;
		target.width = scissor.width;
		target.height = scissor.height;

		return target;

	}
setScissor( x, y, width, height ) {

		const scissor = this._scissor;

		if ( x.isVector4 ) {

			scissor.copy( x );

		} else {

			scissor.set( x, y, width, height );

		}

	}
getScissorTest() {

		return this._scissorTest;

	}
setScissorTest( boolean ) {

		this._scissorTest = boolean;

		this.backend.setScissorTest( boolean );

	}
getViewport( target ) {

		return target.copy( this._viewport );

	}
setViewport( x, y, width, height, minDepth = 0, maxDepth = 1 ) {

		const viewport = this._viewport;

		if ( x.isVector4 ) {

			viewport.copy( x );

		} else {

			viewport.set( x, y, width, height );

		}

		viewport.minDepth = minDepth;
		viewport.maxDepth = maxDepth;

	}
getClearColor( target ) {

		return target.copy( this._clearColor );

	}
setClearColor( color, alpha = 1 ) {

		this._clearColor.set( color );
		this._clearColor.a = alpha;

	}
getClearAlpha() {

		return this._clearColor.a;

	}
setClearAlpha( alpha ) {

		this._clearColor.a = alpha;

	}
getClearDepth() {

		return this._clearDepth;

	}
setClearDepth( depth ) {

		this._clearDepth = depth;

	}
getClearStencil() {

		return this._clearStencil;

	}
setClearStencil( stencil ) {

		this._clearStencil = stencil;

	}
isOccluded( object ) {

		const renderContext = this._currentRenderContext;

		return renderContext && this.backend.isOccluded( renderContext, object );

	}
clear( color = true, depth = true, stencil = true ) {

		if ( this._initialized === false ) {

			console.warn( 'THREE.Renderer: .clear() called before the backend is initialized. Try using .clearAsync() instead.' );

			return this.clearAsync( color, depth, stencil );

		}

		const renderTarget = this._renderTarget || this._getFrameBufferTarget();

		let renderTargetData = null;

		if ( renderTarget !== null ) {

			this._textures.updateRenderTarget( renderTarget );

			renderTargetData = this._textures.get( renderTarget );

		}

		this.backend.clear( color, depth, stencil, renderTargetData );

	}
clearColor() {

		return this.clear( true, false, false );

	}
clearDepth() {

		return this.clear( false, true, false );

	}
clearStencil() {

		return this.clear( false, false, true );

	}
async clearAsync( color = true, depth = true, stencil = true ) {

		if ( this._initialized === false ) await this.init();

		this.clear( color, depth, stencil );

	}
clearColorAsync() {

		return this.clearAsync( true, false, false );

	}
clearDepthAsync() {

		return this.clearAsync( false, true, false );

	}
clearStencilAsync() {

		return this.clearAsync( false, false, true );

	}
get currentColorSpace() {

		const renderTarget = this._renderTarget;

		if ( renderTarget !== null ) {

			const texture = renderTarget.texture;

			return ( Array.isArray( texture ) ? texture[ 0 ] : texture ).colorSpace;

		}

		return this.outputColorSpace;

	}
dispose() {

		this.info.dispose();

		this._animation.dispose();
		this._objects.dispose();
		this._pipelines.dispose();
		this._nodes.dispose();
		this._bindings.dispose();
		this._renderLists.dispose();
		this._renderContexts.dispose();
		this._textures.dispose();

		this.setRenderTarget( null );
		this.setAnimationLoop( null );

	}
setRenderTarget( renderTarget, activeCubeFace = 0, activeMipmapLevel = 0 ) {

		this._renderTarget = renderTarget;
		this._activeCubeFace = activeCubeFace;
		this._activeMipmapLevel = activeMipmapLevel;

	}
getRenderTarget() {

		return this._renderTarget;

	}
setRenderObjectFunction( renderObjectFunction ) {

		this._renderObjectFunction = renderObjectFunction;

	}
getRenderObjectFunction() {

		return this._renderObjectFunction;

	}
async computeAsync( computeNodes ) {

		if ( this._initialized === false ) await this.init();

		const nodeFrame = this._nodes.nodeFrame;

		const previousRenderId = nodeFrame.renderId;

		//

		this.info.calls ++;
		this.info.compute.calls ++;
		this.info.compute.computeCalls ++;

		nodeFrame.renderId = this.info.calls;

		//

		const backend = this.backend;
		const pipelines = this._pipelines;
		const bindings = this._bindings;
		const nodes = this._nodes;
		const computeList = Array.isArray( computeNodes ) ? computeNodes : [ computeNodes ];

		if ( computeList[ 0 ] === undefined || computeList[ 0 ].isComputeNode !== true ) {

			throw new Error( 'THREE.Renderer: .compute() expects a ComputeNode.' );

		}

		backend.beginCompute( computeNodes );

		for ( const computeNode of computeList ) {

			// onInit

			if ( pipelines.has( computeNode ) === false ) {

				const dispose = () => {

					computeNode.removeEventListener( 'dispose', dispose );

					pipelines.delete( computeNode );
					bindings.delete( computeNode );
					nodes.delete( computeNode );

				};

				computeNode.addEventListener( 'dispose', dispose );

				//

				computeNode.onInit( { renderer: this } );

			}

			nodes.updateForCompute( computeNode );
			bindings.updateForCompute( computeNode );

			const computeBindings = bindings.getForCompute( computeNode );
			const computePipeline = pipelines.getForCompute( computeNode, computeBindings );

			backend.compute( computeNodes, computeNode, computeBindings, computePipeline );

		}

		backend.finishCompute( computeNodes );

		await this.backend.resolveTimestampAsync( computeNodes, 'compute' );

		//

		nodeFrame.renderId = previousRenderId;

	}
async hasFeatureAsync( name ) {

		if ( this._initialized === false ) await this.init();

		return this.backend.hasFeature( name );

	}
hasFeature( name ) {

		if ( this._initialized === false ) {

			console.warn( 'THREE.Renderer: .hasFeature() called before the backend is initialized. Try using .hasFeatureAsync() instead.' );

			return false;

		}

		return this.backend.hasFeature( name );

	}
copyFramebufferToTexture( framebufferTexture ) {

		const renderContext = this._currentRenderContext;

		this._textures.updateTexture( framebufferTexture );

		this.backend.copyFramebufferToTexture( framebufferTexture, renderContext );

	}
copyTextureToTexture( srcTexture, dstTexture, srcRegion = null, dstPosition = null, level = 0 ) {

		this._textures.updateTexture( srcTexture );
		this._textures.updateTexture( dstTexture );

		this.backend.copyTextureToTexture( srcTexture, dstTexture, srcRegion, dstPosition, level );

	}
readRenderTargetPixelsAsync( renderTarget, x, y, width, height, index = 0 ) {

		return this.backend.copyTextureToBuffer( renderTarget.textures[ index ], x, y, width, height );

	}
_projectObject( object, camera, groupOrder, renderList ) {

		if ( object.visible === false ) return;

		const visible = object.layers.test( camera.layers );

		if ( visible ) {

			if ( object.isGroup ) {

				groupOrder = object.renderOrder;

			} else if ( object.isLOD ) {

				if ( object.autoUpdate === true ) object.update( camera );

			} else if ( object.isLight ) {

				renderList.pushLight( object );

			} else if ( object.isSprite ) {

				if ( ! object.frustumCulled || _frustum.intersectsSprite( object ) ) {

					if ( this.sortObjects === true ) {

						_vector3.setFromMatrixPosition( object.matrixWorld ).applyMatrix4( _projScreenMatrix );

					}

					const geometry = object.geometry;
					const material = object.material;

					if ( material.visible ) {

						renderList.push( object, geometry, material, groupOrder, _vector3.z, null );

					}

				}

			} else if ( object.isLineLoop ) {

				console.error( 'THREE.Renderer: Objects of type THREE.LineLoop are not supported. Please use THREE.Line or THREE.LineSegments.' );

			} else if ( object.isMesh || object.isLine || object.isPoints ) {

				if ( ! object.frustumCulled || _frustum.intersectsObject( object ) ) {

					const geometry = object.geometry;
					const material = object.material;

					if ( this.sortObjects === true ) {

						if ( geometry.boundingSphere === null ) geometry.computeBoundingSphere();

						_vector3
							.copy( geometry.boundingSphere.center )
							.applyMatrix4( object.matrixWorld )
							.applyMatrix4( _projScreenMatrix );

					}

					if ( Array.isArray( material ) ) {

						const groups = geometry.groups;

						for ( let i = 0, l = groups.length; i < l; i ++ ) {

							const group = groups[ i ];
							const groupMaterial = material[ group.materialIndex ];

							if ( groupMaterial && groupMaterial.visible ) {

								renderList.push( object, geometry, groupMaterial, groupOrder, _vector3.z, group );

							}

						}

					} else if ( material.visible ) {

						renderList.push( object, geometry, material, groupOrder, _vector3.z, null );

					}

				}

			}

		}

		const children = object.children;

		for ( let i = 0, l = children.length; i < l; i ++ ) {

			this._projectObject( children[ i ], camera, groupOrder, renderList );

		}

	}
_renderObjects( renderList, camera, scene, lightsNode ) {

		// process renderable objects

		for ( let i = 0, il = renderList.length; i < il; i ++ ) {

			const renderItem = renderList[ i ];

			// @TODO: Add support for multiple materials per object. This will require to extract
			// the material from the renderItem object and pass it with its group data to renderObject().

			const { object, geometry, material, group } = renderItem;

			if ( camera.isArrayCamera ) {

				const cameras = camera.cameras;

				for ( let j = 0, jl = cameras.length; j < jl; j ++ ) {

					const camera2 = cameras[ j ];

					if ( object.layers.test( camera2.layers ) ) {

						const vp = camera2.viewport;
						const minDepth = ( vp.minDepth === undefined ) ? 0 : vp.minDepth;
						const maxDepth = ( vp.maxDepth === undefined ) ? 1 : vp.maxDepth;

						const viewportValue = this._currentRenderContext.viewportValue;
						viewportValue.copy( vp ).multiplyScalar( this._pixelRatio ).floor();
						viewportValue.minDepth = minDepth;
						viewportValue.maxDepth = maxDepth;

						this.backend.updateViewport( this._currentRenderContext );

						this._currentRenderObjectFunction( object, scene, camera2, geometry, material, group, lightsNode );

					}

				}

			} else {

				this._currentRenderObjectFunction( object, scene, camera, geometry, material, group, lightsNode );

			}

		}

	}
renderObject( object, scene, camera, geometry, material, group, lightsNode ) {

		let overridePositionNode;
		let overrideFragmentNode;
		let overrideDepthNode;

		//

		object.onBeforeRender( this, scene, camera, geometry, material, group );

		material.onBeforeRender( this, scene, camera, geometry, material, group );

		//

		if ( scene.overrideMaterial !== null ) {

			const overrideMaterial = scene.overrideMaterial;

			if ( material.positionNode && material.positionNode.isNode ) {

				overridePositionNode = overrideMaterial.positionNode;
				overrideMaterial.positionNode = material.positionNode;

			}

			if ( overrideMaterial.isShadowNodeMaterial ) {

				overrideMaterial.side = material.shadowSide === null ? material.side : material.shadowSide;

				if ( material.depthNode && material.depthNode.isNode ) {

					overrideDepthNode = overrideMaterial.depthNode;
					overrideMaterial.depthNode = material.depthNode;

				}


				if ( material.shadowNode && material.shadowNode.isNode ) {

					overrideFragmentNode = overrideMaterial.fragmentNode;
					overrideMaterial.fragmentNode = material.shadowNode;

				}

				if ( this.localClippingEnabled ) {

					if ( material.clipShadows ) {

						if ( overrideMaterial.clippingPlanes !== material.clippingPlanes ) {

							overrideMaterial.clippingPlanes = material.clippingPlanes;
							overrideMaterial.needsUpdate = true;

						}

						if ( overrideMaterial.clipIntersection !== material.clipIntersection ) {

							overrideMaterial.clipIntersection = material.clipIntersection;

						}

					} else if ( Array.isArray( overrideMaterial.clippingPlanes ) ) {

						overrideMaterial.clippingPlanes = null;
						overrideMaterial.needsUpdate = true;

					}

				}

			}

			material = overrideMaterial;

		}

		//

		if ( material.transparent === true && material.side === DoubleSide && material.forceSinglePass === false ) {

			material.side = BackSide;
			this._handleObjectFunction( object, material, scene, camera, lightsNode, group, 'backSide' ); // create backSide pass id

			material.side = FrontSide;
			this._handleObjectFunction( object, material, scene, camera, lightsNode, group ); // use default pass id

			material.side = DoubleSide;

		} else {

			this._handleObjectFunction( object, material, scene, camera, lightsNode, group );

		}

		//

		if ( overridePositionNode !== undefined ) {

			scene.overrideMaterial.positionNode = overridePositionNode;

		}

		if ( overrideDepthNode !== undefined ) {

			scene.overrideMaterial.depthNode = overrideDepthNode;

		}

		if ( overrideFragmentNode !== undefined ) {

			scene.overrideMaterial.fragmentNode = overrideFragmentNode;

		}

		//

		object.onAfterRender( this, scene, camera, geometry, material, group );

	}
_renderObjectDirect( object, material, scene, camera, lightsNode, group, passId ) {

		const renderObject = this._objects.get( object, material, scene, camera, lightsNode, this._currentRenderContext, passId );
		renderObject.drawRange = group || object.geometry.drawRange;

		//

		this._nodes.updateBefore( renderObject );

		//

		object.modelViewMatrix.multiplyMatrices( camera.matrixWorldInverse, object.matrixWorld );
		object.normalMatrix.getNormalMatrix( object.modelViewMatrix );

		//

		this._nodes.updateForRender( renderObject );
		this._geometries.updateForRender( renderObject );
		this._bindings.updateForRender( renderObject );
		this._pipelines.updateForRender( renderObject );

		//

		this.backend.draw( renderObject, this.info );

	}
_createObjectPipeline( object, material, scene, camera, lightsNode, passId ) {

		const renderObject = this._objects.get( object, material, scene, camera, lightsNode, this._currentRenderContext, passId );

		//

		this._nodes.updateBefore( renderObject );

		//

		this._nodes.updateForRender( renderObject );
		this._geometries.updateForRender( renderObject );
		this._bindings.updateForRender( renderObject );

		this._pipelines.getForRender( renderObject, this._compilationPromises );

	}
get compute() {

		return this.computeAsync;

	}
get compile() {

		return this.compileAsync;

	}


}


export default Renderer;
