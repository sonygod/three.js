class GLTFExporter {

	constructor() {

		this.pluginCallbacks = [];

		this.register( function ( writer ) {

			return new GLTFLightExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsUnlitExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsTransmissionExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsVolumeExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsIorExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsSpecularExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsClearcoatExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsDispersionExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsIridescenceExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsSheenExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsAnisotropyExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsEmissiveStrengthExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMaterialsBumpExtension( writer );

		} );

		this.register( function ( writer ) {

			return new GLTFMeshGpuInstancing( writer );

		} );

	}

	register( callback ) {

		if ( this.pluginCallbacks.indexOf( callback ) === - 1 ) {

			this.pluginCallbacks.push( callback );

		}

		return this;

	}

	unregister( callback ) {

		if ( this.pluginCallbacks.indexOf( callback ) !== - 1 ) {

			this.pluginCallbacks.splice( this.pluginCallbacks.indexOf( callback ), 1 );

		}

		return this;

	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Function} onError  Callback on errors
	 * @param  {Object} options options
	 */
	parse( input, onDone, onError, options ) {

		const writer = new GLTFWriter();
		const plugins = [];

		for ( let i = 0, il = this.pluginCallbacks.length; i < il; i ++ ) {

			plugins.push( this.pluginCallbacks[ i ]( writer ) );

		}

		writer.setPlugins( plugins );
		writer.write( input, onDone, options ).catch( onError );

	}

	parseAsync( input, options ) {

		const scope = this;

		return new Promise( function ( resolve, reject ) {

			scope.parse( input, resolve, reject, options );

		} );

	}

}