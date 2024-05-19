finishRender( renderContext ) {

		const renderContextData = this.get( renderContext );
		const occlusionQueryCount = renderContext.occlusionQueryCount;

		if ( occlusionQueryCount > renderContextData.occlusionQueryIndex ) {

			renderContextData.currentPass.endOcclusionQuery();

		}

		renderContextData.currentPass.end();

		if ( occlusionQueryCount > 0 ) {

			const bufferSize = occlusionQueryCount * 8; // 8 byte entries for query results

			//

			let queryResolveBuffer = this.occludedResolveCache.get( bufferSize );

			if ( queryResolveBuffer === undefined ) {

				queryResolveBuffer = this.device.createBuffer(
					{
						size: bufferSize,
						usage: GPUBufferUsage.QUERY_RESOLVE | GPUBufferUsage.COPY_SRC
					}
				);

				this.occludedResolveCache.set( bufferSize, queryResolveBuffer );

			}

			//

			const readBuffer = this.device.createBuffer(
				{
					size: bufferSize,
					usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
				}
			);

			// two buffers required here - WebGPU doesn't allow usage of QUERY_RESOLVE & MAP_READ to be combined
			renderContextData.encoder.resolveQuerySet( renderContextData.occlusionQuerySet, 0, occlusionQueryCount, queryResolveBuffer, 0 );
			renderContextData.encoder.copyBufferToBuffer( queryResolveBuffer, 0, readBuffer, 0, bufferSize );

			renderContextData.occlusionQueryBuffer = readBuffer;

			//

			this.resolveOccludedAsync( renderContext );

		}

		this.prepareTimestampBuffer( renderContext, renderContextData.encoder );

		this.device.queue.submit( [ renderContextData.encoder.finish() ] );


		//

		if ( renderContext.textures !== null ) {

			const textures = renderContext.textures;

			for ( let i = 0; i < textures.length; i ++ ) {

				const texture = textures[ i ];

				if ( texture.generateMipmaps === true ) {

					this.textureUtils.generateMipmaps( texture );

				}

			}

		}

	}
isOccluded( renderContext, object ) {

		const renderContextData = this.get( renderContext );

		return renderContextData.occluded && renderContextData.occluded.has( object );

	}
async resolveOccludedAsync( renderContext ) {

		const renderContextData = this.get( renderContext );

		// handle occlusion query results

		const { currentOcclusionQueryBuffer, currentOcclusionQueryObjects } = renderContextData;

		if ( currentOcclusionQueryBuffer && currentOcclusionQueryObjects ) {

			const occluded = new WeakSet();

			renderContextData.currentOcclusionQueryObjects = null;
			renderContextData.currentOcclusionQueryBuffer = null;

			await currentOcclusionQueryBuffer.mapAsync( GPUMapMode.READ );

			const buffer = currentOcclusionQueryBuffer.getMappedRange();
			const results = new BigUint64Array( buffer );

			for ( let i = 0; i < currentOcclusionQueryObjects.length; i ++ ) {

				if ( results[ i ] !== 0n ) {

					occluded.add( currentOcclusionQueryObjects[ i ] );

				}

			}

			currentOcclusionQueryBuffer.destroy();

			renderContextData.occluded = occluded;

		}

	}
updateViewport( renderContext ) {

		const { currentPass } = this.get( renderContext );
		const { x, y, width, height, minDepth, maxDepth } = renderContext.viewportValue;

		currentPass.setViewport( x, renderContext.height - height - y, width, height, minDepth, maxDepth );

	}
clear( color, depth, stencil, renderTargetData = null ) {

		const device = this.device;
		const renderer = this.renderer;

		let colorAttachments = [];

		let depthStencilAttachment;
		let clearValue;

		let supportsDepth;
		let supportsStencil;

		if ( color ) {

			const clearColor = this.getClearColor();

			clearValue = { r: clearColor.r, g: clearColor.g, b: clearColor.b, a: clearColor.a };

		}

		if ( renderTargetData === null ) {

			supportsDepth = renderer.depth;
			supportsStencil = renderer.stencil;

			const descriptor = this._getDefaultRenderPassDescriptor();

			if ( color ) {

				colorAttachments = descriptor.colorAttachments;

				const colorAttachment = colorAttachments[ 0 ];

				colorAttachment.clearValue = clearValue;
				colorAttachment.loadOp = GPULoadOp.Clear;
				colorAttachment.storeOp = GPUStoreOp.Store;

			}

			if ( supportsDepth || supportsStencil ) {

				depthStencilAttachment = descriptor.depthStencilAttachment;

			}

		} else {

			supportsDepth = renderTargetData.depth;
			supportsStencil = renderTargetData.stencil;

			if ( color ) {

				for ( const texture of renderTargetData.textures ) {

					const textureData = this.get( texture );
					const textureView = textureData.texture.createView();

					let view, resolveTarget;

					if ( textureData.msaaTexture !== undefined ) {

						view = textureData.msaaTexture.createView();
						resolveTarget = textureView;

					} else {

						view = textureView;
						resolveTarget = undefined;

					}

					colorAttachments.push( {
						view,
						resolveTarget,
						clearValue,
						loadOp: GPULoadOp.Clear,
						storeOp: GPUStoreOp.Store
					} );

				}

			}

			if ( supportsDepth || supportsStencil ) {

				const depthTextureData = this.get( renderTargetData.depthTexture );

				depthStencilAttachment = {
					view: depthTextureData.texture.createView()
				};

			}

		}

		//

		if ( supportsDepth ) {

			if ( depth ) {

				depthStencilAttachment.depthLoadOp = GPULoadOp.Clear;
				depthStencilAttachment.depthClearValue = renderer.getClearDepth();
				depthStencilAttachment.depthStoreOp = GPUStoreOp.Store;

			} else {

				depthStencilAttachment.depthLoadOp = GPULoadOp.Load;
				depthStencilAttachment.depthStoreOp = GPUStoreOp.Store;

			}

		}

		//

		if ( supportsStencil ) {

			if ( stencil ) {

				depthStencilAttachment.stencilLoadOp = GPULoadOp.Clear;
				depthStencilAttachment.stencilClearValue = renderer.getClearStencil();
				depthStencilAttachment.stencilStoreOp = GPUStoreOp.Store;

			} else {

				depthStencilAttachment.stencilLoadOp = GPULoadOp.Load;
				depthStencilAttachment.stencilStoreOp = GPUStoreOp.Store;

			}

		}

		//

		const encoder = device.createCommandEncoder( {} );
		const currentPass = encoder.beginRenderPass( {
			colorAttachments,
			depthStencilAttachment
		} );

		currentPass.end();

		device.queue.submit( [ encoder.finish() ] );

	}
beginCompute( computeGroup ) {

		const groupGPU = this.get( computeGroup );


		const descriptor = {};

		this.initTimestampQuery( computeGroup, descriptor );

		groupGPU.cmdEncoderGPU = this.device.createCommandEncoder();

		groupGPU.passEncoderGPU = groupGPU.cmdEncoderGPU.beginComputePass( descriptor );

	}
compute( computeGroup, computeNode, bindings, pipeline ) {

		const { passEncoderGPU } = this.get( computeGroup );

		// pipeline

		const pipelineGPU = this.get( pipeline ).pipeline;
		passEncoderGPU.setPipeline( pipelineGPU );

		// bind group

		const bindGroupGPU = this.get( bindings ).group;
		passEncoderGPU.setBindGroup( 0, bindGroupGPU );

		passEncoderGPU.dispatchWorkgroups( computeNode.dispatchCount );

	}
finishCompute( computeGroup ) {

		const groupData = this.get( computeGroup );

		groupData.passEncoderGPU.end();

		this.prepareTimestampBuffer( computeGroup, groupData.cmdEncoderGPU );

		this.device.queue.submit( [ groupData.cmdEncoderGPU.finish() ] );

	}
draw( renderObject, info ) {

		const { object, geometry, context, pipeline } = renderObject;

		const bindingsData = this.get( renderObject.getBindings() );
		const contextData = this.get( context );
		const pipelineGPU = this.get( pipeline ).pipeline;
		const currentSets = contextData.currentSets;

		// pipeline

		const passEncoderGPU = contextData.currentPass;

		if ( currentSets.pipeline !== pipelineGPU ) {

			passEncoderGPU.setPipeline( pipelineGPU );

			currentSets.pipeline = pipelineGPU;

		}

		// bind group

		const bindGroupGPU = bindingsData.group;
		passEncoderGPU.setBindGroup( 0, bindGroupGPU );

		// attributes

		const index = renderObject.getIndex();

		const hasIndex = ( index !== null );

		// index

		if ( hasIndex === true ) {

			if ( currentSets.index !== index ) {

				const buffer = this.get( index ).buffer;
				const indexFormat = ( index.array instanceof Uint16Array ) ? GPUIndexFormat.Uint16 : GPUIndexFormat.Uint32;

				passEncoderGPU.setIndexBuffer( buffer, indexFormat );

				currentSets.index = index;

			}

		}

		// vertex buffers

		const vertexBuffers = renderObject.getVertexBuffers();

		for ( let i = 0, l = vertexBuffers.length; i < l; i ++ ) {

			const vertexBuffer = vertexBuffers[ i ];

			if ( currentSets.attributes[ i ] !== vertexBuffer ) {

				const buffer = this.get( vertexBuffer ).buffer;
				passEncoderGPU.setVertexBuffer( i, buffer );

				currentSets.attributes[ i ] = vertexBuffer;

			}

		}

		// occlusion queries - handle multiple consecutive draw calls for an object

		if ( contextData.occlusionQuerySet !== undefined ) {

			const lastObject = contextData.lastOcclusionObject;

			if ( lastObject !== object ) {

				if ( lastObject !== null && lastObject.occlusionTest === true ) {

					passEncoderGPU.endOcclusionQuery();
					contextData.occlusionQueryIndex ++;

				}

				if ( object.occlusionTest === true ) {

					passEncoderGPU.beginOcclusionQuery( contextData.occlusionQueryIndex );
					contextData.occlusionQueryObjects[ contextData.occlusionQueryIndex ] = object;

				}

				contextData.lastOcclusionObject = object;

			}

		}

		// draw

		const drawRange = renderObject.drawRange;
		const firstVertex = drawRange.start;

		const instanceCount = this.getInstanceCount( renderObject );
		if ( instanceCount === 0 ) return;

		if ( hasIndex === true ) {

			const indexCount = ( drawRange.count !== Infinity ) ? drawRange.count : index.count;

			passEncoderGPU.drawIndexed( indexCount, instanceCount, firstVertex, 0, 0 );

			info.update( object, indexCount, instanceCount );

		} else {

			const positionAttribute = geometry.attributes.position;
			const vertexCount = ( drawRange.count !== Infinity ) ? drawRange.count : positionAttribute.count;

			passEncoderGPU.draw( vertexCount, instanceCount, firstVertex, 0 );

			info.update( object, vertexCount, instanceCount );

		}

	}
needsRenderUpdate( renderObject ) {

		const data = this.get( renderObject );

		const { object, material } = renderObject;

		const utils = this.utils;

		const sampleCount = utils.getSampleCount( renderObject.context );
		const colorSpace = utils.getCurrentColorSpace( renderObject.context );
		const colorFormat = utils.getCurrentColorFormat( renderObject.context );
		const depthStencilFormat = utils.getCurrentDepthStencilFormat( renderObject.context );
		const primitiveTopology = utils.getPrimitiveTopology( object, material );

		let needsUpdate = false;

		if ( data.material !== material || data.materialVersion !== material.version ||
			data.transparent !== material.transparent || data.blending !== material.blending || data.premultipliedAlpha !== material.premultipliedAlpha ||
			data.blendSrc !== material.blendSrc || data.blendDst !== material.blendDst || data.blendEquation !== material.blendEquation ||
			data.blendSrcAlpha !== material.blendSrcAlpha || data.blendDstAlpha !== material.blendDstAlpha || data.blendEquationAlpha !== material.blendEquationAlpha ||
			data.colorWrite !== material.colorWrite || data.depthWrite !== material.depthWrite || data.depthTest !== material.depthTest || data.depthFunc !== material.depthFunc ||
			data.stencilWrite !== material.stencilWrite || data.stencilFunc !== material.stencilFunc ||
			data.stencilFail !== material.stencilFail || data.stencilZFail !== material.stencilZFail || data.stencilZPass !== material.stencilZPass ||
			data.stencilFuncMask !== material.stencilFuncMask || data.stencilWriteMask !== material.stencilWriteMask ||
			data.side !== material.side || data.alphaToCoverage !== material.alphaToCoverage ||
			data.sampleCount !== sampleCount || data.colorSpace !== colorSpace ||
			data.colorFormat !== colorFormat || data.depthStencilFormat !== depthStencilFormat ||
			data.primitiveTopology !== primitiveTopology ||
			data.clippingContextVersion !== renderObject.clippingContextVersion
		) {

			data.material = material; data.materialVersion = material.version;
			data.transparent = material.transparent; data.blending = material.blending; data.premultipliedAlpha = material.premultipliedAlpha;
			data.blendSrc = material.blendSrc; data.blendDst = material.blendDst; data.blendEquation = material.blendEquation;
			data.blendSrcAlpha = material.blendSrcAlpha; data.blendDstAlpha = material.blendDstAlpha; data.blendEquationAlpha = material.blendEquationAlpha;
			data.colorWrite = material.colorWrite;
			data.depthWrite = material.depthWrite; data.depthTest = material.depthTest; data.depthFunc = material.depthFunc;
			data.stencilWrite = material.stencilWrite; data.stencilFunc = material.stencilFunc;
			data.stencilFail = material.stencilFail; data.stencilZFail = material.stencilZFail; data.stencilZPass = material.stencilZPass;
			data.stencilFuncMask = material.stencilFuncMask; data.stencilWriteMask = material.stencilWriteMask;
			data.side = material.side; data.alphaToCoverage = material.alphaToCoverage;
			data.sampleCount = sampleCount;
			data.colorSpace = colorSpace;
			data.colorFormat = colorFormat;
			data.depthStencilFormat = depthStencilFormat;
			data.primitiveTopology = primitiveTopology;
			data.clippingContextVersion = renderObject.clippingContextVersion;

			needsUpdate = true;

		}

		return needsUpdate;

	}
getRenderCacheKey( renderObject ) {

		const { object, material } = renderObject;

		const utils = this.utils;
		const renderContext = renderObject.context;

		return [
			material.transparent, material.blending, material.premultipliedAlpha,
			material.blendSrc, material.blendDst, material.blendEquation,
			material.blendSrcAlpha, material.blendDstAlpha, material.blendEquationAlpha,
			material.colorWrite,
			material.depthWrite, material.depthTest, material.depthFunc,
			material.stencilWrite, material.stencilFunc,
			material.stencilFail, material.stencilZFail, material.stencilZPass,
			material.stencilFuncMask, material.stencilWriteMask,
			material.side,
			utils.getSampleCount( renderContext ),
			utils.getCurrentColorSpace( renderContext ), utils.getCurrentColorFormat( renderContext ), utils.getCurrentDepthStencilFormat( renderContext ),
			utils.getPrimitiveTopology( object, material ),
			renderObject.clippingContextVersion
		].join();

	}
createSampler( texture ) {

		this.textureUtils.createSampler( texture );

	}
destroySampler( texture ) {

		this.textureUtils.destroySampler( texture );

	}
createDefaultTexture( texture ) {

		this.textureUtils.createDefaultTexture( texture );

	}
createTexture( texture, options ) {

		this.textureUtils.createTexture( texture, options );

	}
updateTexture( texture, options ) {

		this.textureUtils.updateTexture( texture, options );

	}
generateMipmaps( texture ) {

		this.textureUtils.generateMipmaps( texture );

	}
destroyTexture( texture ) {

		this.textureUtils.destroyTexture( texture );

	}
copyTextureToBuffer( texture, x, y, width, height ) {

		return this.textureUtils.copyTextureToBuffer( texture, x, y, width, height );

	}
initTimestampQuery( renderContext, descriptor ) {

		if ( ! this.hasFeature( GPUFeatureName.TimestampQuery ) || ! this.trackTimestamp ) return;

		const renderContextData = this.get( renderContext );

		if ( ! renderContextData.timeStampQuerySet ) {

			// Create a GPUQuerySet which holds 2 timestamp query results: one for the
			// beginning and one for the end of compute pass execution.
			const timeStampQuerySet = this.device.createQuerySet( { type: 'timestamp', count: 2 } );

			const timestampWrites = {
				querySet: timeStampQuerySet,
				beginningOfPassWriteIndex: 0, // Write timestamp in index 0 when pass begins.
				endOfPassWriteIndex: 1, // Write timestamp in index 1 when pass ends.
			};

			Object.assign( descriptor, {
				timestampWrites,
			} );

			renderContextData.timeStampQuerySet = timeStampQuerySet;

		}

	}
prepareTimestampBuffer( renderContext, encoder ) {

		if ( ! this.hasFeature( GPUFeatureName.TimestampQuery ) || ! this.trackTimestamp ) return;

		const renderContextData = this.get( renderContext );

		const size = 2 * BigInt64Array.BYTES_PER_ELEMENT;
		const resolveBuffer = this.device.createBuffer( {
			size,
			usage: GPUBufferUsage.QUERY_RESOLVE | GPUBufferUsage.COPY_SRC,
		} );

		const resultBuffer = this.device.createBuffer( {
			size,
			usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ,
		} );

		encoder.resolveQuerySet( renderContextData.timeStampQuerySet, 0, 2, resolveBuffer, 0 );
		encoder.copyBufferToBuffer( resolveBuffer, 0, resultBuffer, 0, size );

		renderContextData.currentTimestampQueryBuffer = resultBuffer;

	}
async resolveTimestampAsync(renderContext, type = 'render') {
		if (!this.hasFeature(GPUFeatureName.TimestampQuery) || !this.trackTimestamp) return;
	
		const renderContextData = this.get(renderContext);
		const { currentTimestampQueryBuffer } = renderContextData;
	
		if (currentTimestampQueryBuffer === undefined) return;

		const buffer = currentTimestampQueryBuffer;

		try {
			await buffer.mapAsync(GPUMapMode.READ);
			const times = new BigUint64Array(buffer.getMappedRange());
			const duration = Number(times[1] - times[0]) / 1000000;
			this.renderer.info.updateTimestamp(type, duration);
		} catch (error) {
			console.error(`Error mapping buffer: ${error}`);
			// Optionally handle the error, e.g., re-queue the buffer or skip it
		} finally {
			buffer.unmap(); 
		}
	}
createNodeBuilder( object, renderer, scene = null ) {

		return new WGSLNodeBuilder( object, renderer, scene );

	}
createProgram( program ) {

		const programGPU = this.get( program );

		programGPU.module = {
			module: this.device.createShaderModule( { code: program.code, label: program.stage } ),
			entryPoint: 'main'
		};

	}
destroyProgram( program ) {

		this.delete( program );

	}
createRenderPipeline( renderObject, promises ) {

		this.pipelineUtils.createRenderPipeline( renderObject, promises );

	}
createComputePipeline( computePipeline, bindings ) {

		this.pipelineUtils.createComputePipeline( computePipeline, bindings );

	}
createBindings( bindings ) {

		this.bindingUtils.createBindings( bindings );

	}
updateBindings( bindings ) {

		this.bindingUtils.createBindings( bindings );

	}
updateBinding( binding ) {

		this.bindingUtils.updateBinding( binding );

	}
createIndexAttribute( attribute ) {

		this.attributeUtils.createAttribute( attribute, GPUBufferUsage.INDEX | GPUBufferUsage.COPY_SRC | GPUBufferUsage.COPY_DST );

	}
createAttribute( attribute ) {

		this.attributeUtils.createAttribute( attribute, GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_SRC | GPUBufferUsage.COPY_DST );

	}
createStorageAttribute( attribute ) {

		this.attributeUtils.createAttribute( attribute, GPUBufferUsage.STORAGE | GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_SRC | GPUBufferUsage.COPY_DST );

	}
updateAttribute( attribute ) {

		this.attributeUtils.updateAttribute( attribute );

	}
destroyAttribute( attribute ) {

		this.attributeUtils.destroyAttribute( attribute );

	}
updateSize() {

		this.colorBuffer = this.textureUtils.getColorBuffer();
		this.defaultRenderPassdescriptor = null;

	}
getMaxAnisotropy() {

		return 16;

	}
hasFeature( name ) {

		return this.device.features.has( name );

	}
copyTextureToTexture( srcTexture, dstTexture, srcRegion = null, dstPosition = null, level = 0 ) {

		let dstX = 0;
		let dstY = 0;

		if ( dstPosition !== null ) {

			dstX = dstPosition.x;
			dstY = dstPosition.y;

		}
		
		const encoder = this.device.createCommandEncoder( { label: 'copyTextureToTexture_' + srcTexture.id + '_' + dstTexture.id } );

		const sourceGPU = this.get( srcTexture ).texture;
		const destinationGPU = this.get( dstTexture ).texture;

		encoder.copyTextureToTexture(
			{
				texture: sourceGPU,
				mipLevel: level,
				origin: { x: 0, y: 0, z: 0 }
			},
			{
				texture: destinationGPU,
				mipLevel: level,
				origin: { x: dstX, y: dstY, z: 0 }
			},
			[
				srcTexture.image.width,
				srcTexture.image.height
			]
		);

		this.device.queue.submit( [ encoder.finish() ] );

	}
copyFramebufferToTexture( texture, renderContext ) {

		const renderContextData = this.get( renderContext );

		const { encoder, descriptor } = renderContextData;

		let sourceGPU = null;

		if ( renderContext.renderTarget ) {

			if ( texture.isDepthTexture ) {

				sourceGPU = this.get( renderContext.depthTexture ).texture;

			} else {

				sourceGPU = this.get( renderContext.textures[ 0 ] ).texture;

			}

		} else {

			if ( texture.isDepthTexture ) {

				sourceGPU = this.textureUtils.getDepthBuffer( renderContext.depth, renderContext.stencil );

			} else {

				sourceGPU = this.context.getCurrentTexture();

			}

		}

		const destinationGPU = this.get( texture ).texture;

		if ( sourceGPU.format !== destinationGPU.format ) {

			console.error( 'WebGPUBackend: copyFramebufferToTexture: Source and destination formats do not match.', sourceGPU.format, destinationGPU.format );

			return;

		}

		renderContextData.currentPass.end();

		encoder.copyTextureToTexture(
			{
				texture: sourceGPU,
				origin: { x: 0, y: 0, z: 0 }
			},
			{
				texture: destinationGPU
			},
			[
				texture.image.width,
				texture.image.height
			]
		);

		if ( texture.generateMipmaps ) this.textureUtils.generateMipmaps( texture );

		descriptor.colorAttachments[ 0 ].loadOp = GPULoadOp.Load;
		if ( renderContext.depth ) descriptor.depthStencilAttachment.depthLoadOp = GPULoadOp.Load;
		if ( renderContext.stencil ) descriptor.depthStencilAttachment.stencilLoadOp = GPULoadOp.Load;

		renderContextData.currentPass = encoder.beginRenderPass( descriptor );
		renderContextData.currentSets = { attributes: {} };

	}


}


export default WebGPUBackend;
