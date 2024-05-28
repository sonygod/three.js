script
import { WebGLRenderTarget } from './renderers/WebGLRenderTarget.js';

export class WebGLMultipleRenderTargets extends WebGLRenderTarget { // @deprecated, r162

	constructor( width: number = 1, height: number = 1, count: number = 1, options: any = {} ) {

		console.warn( 'THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the "count" parameter to enable MRT.' );

		super( width, height, { ...options, count } );

		this.isWebGLMultipleRenderTargets = true;

	}

	get texture(): any {

		return this.textures;

	}

}