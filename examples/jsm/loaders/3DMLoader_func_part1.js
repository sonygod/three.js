import {
	BufferGeometryLoader,
	CanvasTexture,
	ClampToEdgeWrapping,
	Color,
	DirectionalLight,
	DoubleSide,
	FileLoader,
	LinearFilter,
	Line,
	LineBasicMaterial,
	Loader,
	Matrix4,
	Mesh,
	MeshPhysicalMaterial,
	MeshStandardMaterial,
	Object3D,
	PointLight,
	Points,
	PointsMaterial,
	RectAreaLight,
	RepeatWrapping,
	SpotLight,
	Sprite,
	SpriteMaterial,
	TextureLoader
} from 'three';

import { EXRLoader } from '../loaders/EXRLoader.js';

const _taskCache = new WeakMap();


class Rhino3dmLoader extends Loader {

	constructor( manager ) {

		super( manager );

		this.libraryPath = '';
		this.libraryPending = null;
		this.libraryBinary = null;
		this.libraryConfig = {};

		this.url = '';

		this.workerLimit = 4;
		this.workerPool = [];
		this.workerNextTaskID = 1;
		this.workerSourceURL = '';
		this.workerConfig = {};

		this.materials = [];
		this.warnings = [];

	}
setLibraryPath( path ) {

		this.libraryPath = path;

		return this;

	}
setWorkerLimit( workerLimit ) {

		this.workerLimit = workerLimit;

		return this;

	}
load( url, onLoad, onProgress, onError ) {

		const loader = new FileLoader( this.manager );

		loader.setPath( this.path );
		loader.setResponseType( 'arraybuffer' );
		loader.setRequestHeader( this.requestHeader );

		this.url = url;

		loader.load( url, ( buffer ) => {

			// Check for an existing task using this buffer. A transferred buffer cannot be transferred
			// again from this thread.
			if ( _taskCache.has( buffer ) ) {

				const cachedTask = _taskCache.get( buffer );

				return cachedTask.promise.then( onLoad ).catch( onError );

			}

			this.decodeObjects( buffer, url )
				.then( result => {

					result.userData.warnings = this.warnings;
					onLoad( result );

				 } )
				.catch( e => onError( e ) );

		}, onProgress, onError );

	}
debug() {

		console.log( 'Task load: ', this.workerPool.map( ( worker ) => worker._taskLoad ) );

	}
decodeObjects( buffer, url ) {

		let worker;
		let taskID;

		const taskCost = buffer.byteLength;

		const objectPending = this._getWorker( taskCost )
			.then( ( _worker ) => {

				worker = _worker;
				taskID = this.workerNextTaskID ++;

				return new Promise( ( resolve, reject ) => {

					worker._callbacks[ taskID ] = { resolve, reject };

					worker.postMessage( { type: 'decode', id: taskID, buffer }, [ buffer ] );

					// this.debug();

				} );

			} )
			.then( ( message ) => this._createGeometry( message.data ) )
			.catch( e => {

				throw e;

			} );

		// Remove task from the task list.
		// Note: replaced '.finally()' with '.catch().then()' block - iOS 11 support (#19416)
		objectPending
			.catch( () => true )
			.then( () => {

				if ( worker && taskID ) {

					this._releaseTask( worker, taskID );

					//this.debug();

				}

			} );

		// Cache the task result.
		_taskCache.set( buffer, {

			url: url,
			promise: objectPending

		} );

		return objectPending;

	}
parse( data, onLoad, onError ) {

		this.decodeObjects( data, '' )
			.then( result => {

				result.userData.warnings = this.warnings;
				onLoad( result );

			} )
			.catch( e => onError( e ) );

	}
_compareMaterials( material ) {

		const mat = {};
		mat.name = material.name;
		mat.color = {};
		mat.color.r = material.color.r;
		mat.color.g = material.color.g;
		mat.color.b = material.color.b;
		mat.type = material.type;
		mat.vertexColors = material.vertexColors;

		const json = JSON.stringify( mat );

		for ( let i = 0; i < this.materials.length; i ++ ) {

			const m = this.materials[ i ];
			const _mat = {};
			_mat.name = m.name;
			_mat.color = {};
			_mat.color.r = m.color.r;
			_mat.color.g = m.color.g;
			_mat.color.b = m.color.b;
			_mat.type = m.type;
			_mat.vertexColors = m.vertexColors;

			if ( JSON.stringify( _mat ) === json ) {

				return m;

			}

		}

		this.materials.push( material );

		return material;

	}
_createMaterial( material, renderEnvironment ) {

		if ( material === undefined ) {

			return new MeshStandardMaterial( {
				color: new Color( 1, 1, 1 ),
				metalness: 0.8,
				name: Loader.DEFAULT_MATERIAL_NAME,
				side: DoubleSide
			} );

		}

		//console.log(material)

		const mat = new MeshPhysicalMaterial( {

			color: new Color( material.diffuseColor.r / 255.0, material.diffuseColor.g / 255.0, material.diffuseColor.b / 255.0 ),
			emissive: new Color( material.emissionColor.r, material.emissionColor.g, material.emissionColor.b ),
			flatShading: material.disableLighting,
			ior: material.indexOfRefraction,
			name: material.name,
			reflectivity: material.reflectivity,
			opacity: 1.0 - material.transparency,
			side: DoubleSide,
			specularColor: material.specularColor,
			transparent: material.transparency > 0 ? true : false

		} );

		mat.userData.id = material.id;

		if ( material.pbrSupported ) {

			const pbr = material.pbr;

			mat.anisotropy = pbr.anisotropic;
			mat.anisotropyRotation = pbr.anisotropicRotation;
			mat.color = new Color( pbr.baseColor.r, pbr.baseColor.g, pbr.baseColor.b );
			mat.clearcoat = pbr.clearcoat;
			mat.clearcoatRoughness = pbr.clearcoatRoughness;
			mat.metalness = pbr.metallic;
			mat.transmission = 1 - pbr.opacity;
			mat.roughness = pbr.roughness;
			mat.sheen = pbr.sheen;
			mat.specularIntensity = pbr.specular;
			mat.thickness = pbr.subsurface;

		}

		if ( material.pbrSupported && material.pbr.opacity === 0 && material.transparency === 1 ) {

			//some compromises

			mat.opacity = 0.2;
			mat.transmission = 1.00;

		}

		const textureLoader = new TextureLoader();

		for ( let i = 0; i < material.textures.length; i ++ ) {

			const texture = material.textures[ i ];

			if ( texture.image !== null ) {

				const map = textureLoader.load( texture.image );

				//console.log(texture.type )

				switch ( texture.type ) {

					case 'Bump':

						mat.bumpMap = map;

						break;

					case 'Diffuse':

						mat.map = map;

						break;

					case 'Emap':

						mat.envMap = map;

						break;

					case 'Opacity':

						mat.transmissionMap = map;

						break;

					case 'Transparency':

						mat.alphaMap = map;
						mat.transparent = true;

						break;

					case 'PBR_Alpha':

						mat.alphaMap = map;
						mat.transparent = true;

						break;

					case 'PBR_AmbientOcclusion':

						mat.aoMap = map;

						break;

					case 'PBR_Anisotropic':

						mat.anisotropyMap = map;

						break;

					case 'PBR_BaseColor':

						mat.map = map;

						break;

					case 'PBR_Clearcoat':

						mat.clearcoatMap = map;

						break;

					case 'PBR_ClearcoatBump':

						mat.clearcoatNormalMap = map;

						break;

					case 'PBR_ClearcoatRoughness':

						mat.clearcoatRoughnessMap = map;

						break;

					case 'PBR_Displacement':

						mat.displacementMap = map;

						break;

					case 'PBR_Emission':

						mat.emissiveMap = map;

						break;

					case 'PBR_Metallic':

						mat.metalnessMap = map;

						break;

					case 'PBR_Roughness':

						mat.roughnessMap = map;

						break;

					case 'PBR_Sheen':

						mat.sheenColorMap = map;

						break;

					case 'PBR_Specular':

						mat.specularColorMap = map;

						break;

					case 'PBR_Subsurface':

						mat.thicknessMap = map;

						break;

					default:

						this.warnings.push( {
							message: `THREE.3DMLoader: No conversion exists for 3dm ${texture.type}.`,
							type: 'no conversion'
						} );

						break;

				}

				map.wrapS = texture.wrapU === 0 ? RepeatWrapping : ClampToEdgeWrapping;
				map.wrapT = texture.wrapV === 0 ? RepeatWrapping : ClampToEdgeWrapping;

				if ( texture.repeat ) {

					map.repeat.set( texture.repeat[ 0 ], texture.repeat[ 1 ] );

				}

			}

		}

		if ( renderEnvironment ) {

			new EXRLoader().load( renderEnvironment.image, function ( texture ) {

				texture.mapping = THREE.EquirectangularReflectionMapping;
				mat.envMap = texture;

			} );

		}

		return mat;

	}