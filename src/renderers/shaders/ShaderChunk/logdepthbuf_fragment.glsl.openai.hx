package three.renderers.shaders.ShaderChunk;

#if (js && (USE_LOGDEPTHBUF && !display))

	override function main() {
		if (vIsPerspective == 0.0) {
			gl_FragDepth = gl_FragCoord.z;
		} else {
			gl_FragDepth = Math.log(vFragDepth) * logDepthBufFC * 0.5;
		}
	}

#end