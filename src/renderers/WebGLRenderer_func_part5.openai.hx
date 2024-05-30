package three;

import js.html.webgl.GL;
import js.html.webgl.RenderingContext;
import js.Browser;
import js.html.webgl.Framebuffer;
import js.html.webgl.Texture;
import js.html.webgl.Buffer;

class WebGLRenderer {
    // Properties
    public var _gl:GL;
    public var _currentRenderTarget:RenderTarget;
    public var _currentActiveCubeFace:Int;
    public var _currentActiveMipmapLevel:Int;
    public var _viewport:Viewport;
    public var _scissor:Scissor;
    public var _scissorTest:Bool;
    public var _pixelRatio:Float;
    public var _height:Int;
    public var bindingStates:BindingStates;

    // Constructors
    public function new() {
        _gl = Browser.window.webgl;
        _currentRenderTarget = null;
        _currentActiveCubeFace = 0;
        _currentActiveMipmapLevel = 0;
        _viewport = new Viewport();
        _scissor = new Scissor();
        _scissorTest = false;
        _pixelRatio = Browser.window.devicePixelRatio;
        _height = Browser.window.innerHeight;
        bindingStates = new BindingStates();
    }

    // ...
}

class Viewport {
    public var x:Int;
    public var y:Int;
    public var width:Int;
    public var height:Int;

    public function new() {
        x = 0;
        y = 0;
        width = Browser.window.innerWidth;
        height = Browser.window.innerHeight;
    }
}

class Scissor {
    public var x:Int;
    public var y:Int;
    public var width:Int;
    public var height:Int;

    public function new() {
        x = 0;
        y = 0;
        width = Browser.window.innerWidth;
        height = Browser.window.innerHeight;
    }
}

class BindingStates {
    public function reset() {
        // implementation
    }
}

// ...