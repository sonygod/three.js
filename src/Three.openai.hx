package Three;

import com.threejs.constants.REVISION;

export { WebGLArrayRenderTarget } from 'renderers/WebGLArrayRenderTarget';
export { WebGL3DRenderTarget } from 'renderers/WebGL3DRenderTarget';
export { WebGLCubeRenderTarget } from 'renderers/WebGLCubeRenderTarget';
export { WebGLRenderTarget } from 'renderers/WebGLRenderTarget';
export { WebGLRenderer } from 'renderers/WebGLRenderer';
export { ShaderLib } from 'renderers/shaders/ShaderLib';
export { UniformsLib } from 'renderers/shaders/UniformsLib';
export { UniformsUtils } from 'renderers/shaders/UniformsUtils';
export { ShaderChunk } from 'renderers/shaders/ShaderChunk';
export { FogExp2 } from 'scenes/FogExp2';
export { Fog } from 'scenes/Fog';
export { Scene } from 'scenes/Scene';
// Add other exports accordingly

class Three {
    public static function main() {
        #if js
        if (typeof __THREE_DEVTOOLS__ !== 'undefined') {
            __THREE_DEVTOOLS__.dispatchEvent(new js.html.CustomEvent('register', { detail: {
                revision: REVISION
            }}));
        }

        if (js.Lib.window != null) {
            if (js.Lib.window.__THREE__ != null) {
                js.Lib.console.warn('WARNING: Multiple instances of Three.js being imported.');
            } else {
                js.Lib.window.__THREE__ = REVISION;
            }
        }
        #end
    }
}