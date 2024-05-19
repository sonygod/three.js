import { WebGLRenderTarget } from './renderers/WebGLRenderTarget.js';

@Deprecated("Use THREE.WebGLRenderTarget and set the \"count\" parameter to enable MRT.",162)
export class WebGLMultipleRenderTargets extends WebGLRenderTarget {
	constructor(width: Number = 1, height: Number = 1, count: Number = 1, options: {} = {}) {
		super(width, height, { ...options, count: options.count ?? 1 });
		this.isWebGLMultipleRenderTargets = true;
	}

	public get texture(): Texture {
		return this.textures;
	}
}