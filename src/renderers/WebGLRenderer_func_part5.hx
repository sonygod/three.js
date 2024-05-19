package three;

import haxe.ds.StringMap;
import haxe.ds.IntMap;
import js.html.webgl.GL;
import js.html.webgl.RenderingContext;
import js.html.Texture;
import js.html.Uint8Array;
import js.html.WebGLBuffer;
import js.html.WebGLFramebuffer;
import js.html.WebGLProgram;
import js.html.WebGLRenderbuffer;
import js.html.WebGLTexture;

class WebGLRenderer {
    var gl:GL;
    var properties:StringMap<Dynamic>;
    var capabilities:Capabilities;
    var state:WebGLState;
    var textures:Texture;
    var bindingStates:BindingStates;
    var _currentRenderTarget:RenderTarget;
    var _currentActiveCubeFace:Int;
    var _currentActiveMipmapLevel:Int;
    var _pixelRatio:Float;
    var _height:Int;
    var _scissor:Rectangle;
    var _scissorTest:Bool;
    var _viewport:Rectangle;
    var _currentMaterialId:Int;
    var _outputColorSpace:String;
    var _useLegacyLights:Bool;

    public function new(gl:GL, canvas:js.html.CanvasElement, options:Dynamic) {
        this.gl = gl;
        this.properties = new StringMap<Dynamic>();
        this.capabilities = new Capabilities(gl);
        this.state = new WebGLState(gl);
        this.textures = new Texture(gl);
        this.bindingStates = new BindingStates();
        this._currentRenderTarget = null;
        this._currentActiveCubeFace = 0;
        this._currentActiveMipmapLevel = 0;
        this._pixelRatio = 1;
        this._height = 0;
        this._scissor = new Rectangle(0, 0, 0, 0);
        this._scissorTest = false;
        this._viewport = new Rectangle(0, 0, 0, 0);
        this._currentMaterialId = -1;
        this._outputColorSpace = 'srgb';
        this._useLegacyLights = false;
    }

    // ... rest of the code ...

    public function markUniformsLightsNeedsUpdate(uniforms:Uniforms, refreshLights:Bool) {
        uniforms.ambientLightColor.needsUpdate = refreshLights;
        uniforms.lightProbe.needsUpdate = refreshLights;
        uniforms.directionalLights.needsUpdate = refreshLights;
        uniforms.directionalLightShadows.needsUpdate = refreshLights;
        uniforms.pointLights.needsUpdate = refreshLights;
        uniforms.pointLightShadows.needsUpdate = refreshLights;
        uniforms.spotLights.needsUpdate = refreshLights;
        uniforms.spotLightShadows.needsUpdate = refreshLights;
        uniforms.rectAreaLights.needsUpdate = refreshLights;
        uniforms.hemisphereLights.needsUpdate = refreshLights;
    }

    // ... rest of the code ...
}