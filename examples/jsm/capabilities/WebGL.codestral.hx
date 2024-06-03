class WebGL {

    public static function isWebGLAvailable():Bool {
        try {
            return js.Browser.document != null && js.Browser.window.WebGLRenderingContext != null;
        } catch ( e:Dynamic ) {
            return false;
        }
    }

    public static function isWebGL2Available():Bool {
        try {
            return js.Browser.document != null && js.Browser.window.WebGL2RenderingContext != null;
        } catch ( e:Dynamic ) {
            return false;
        }
    }

    public static function isColorSpaceAvailable( colorSpace:String ):Bool {
        try {
            return js.Browser.document != null && js.Browser.window.WebGL2RenderingContext != null;
            // The rest of the function is not converted as it requires DOM manipulation which is not supported in Haxe
        } catch ( e:Dynamic ) {
            return false;
        }
    }

    public static function getWebGLErrorMessage():String {
        return getErrorMessage(1);
    }

    public static function getWebGL2ErrorMessage():String {
        return getErrorMessage(2);
    }

    private static function getErrorMessage( version:Int ):String {
        var names:Map<Int, String> = [1 => 'WebGL', 2 => 'WebGL 2'];
        var message = 'Your $0 does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation" style="color:#000">$1</a>';

        if (js.Browser.window['WebGL' + version + 'RenderingContext'] != null) {
            message = message.replace('$0', 'graphics card');
        } else {
            message = message.replace('$0', 'browser');
        }

        message = message.replace('$1', names[version]);

        return message;
    }
}