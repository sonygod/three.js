class LWOLoader extends Loader {

	constructor( manager, parameters = {} ) {

		super( manager );

		this.resourcePath = ( parameters.resourcePath !== undefined ) ? parameters.resourcePath : '';

	}

	load( url, onLoad, onProgress, onError ) {

		const scope = this;

		const path = ( scope.path === '' ) ? extractParentUrl( url, 'Objects' ) : scope.path;

		// give the mesh a default name based on the filename
		const modelName = url.split( path ).pop().split( '.' )[ 0 ];

		const loader = new FileLoader( this.manager );
		loader.setPath( scope.path );
		loader.setResponseType( 'arraybuffer' );

		loader.load( url, function ( buffer ) {

			// console.time( 'Total parsing: ' );

			try {

				onLoad( scope.parse( buffer, path, modelName ) );

			} catch ( e ) {

				if ( onError ) {

					onError( e );

				} else {

					console.error( e );

				}

				scope.manager.itemError( url );

			}

			// console.timeEnd( 'Total parsing: ' );

		}, onProgress, onError );

	}

	parse( iffBuffer, path, modelName ) {

		_lwoTree = new IFFParser().parse( iffBuffer );

		// console.log( 'lwoTree', lwoTree );

		const textureLoader = new TextureLoader( this.manager ).setPath( this.resourcePath || path ).setCrossOrigin( this.crossOrigin );

		return new LWOTreeParser( textureLoader ).parse( modelName );

	}

}