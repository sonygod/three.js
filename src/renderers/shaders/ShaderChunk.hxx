import js.Lib;

class ShaderChunk {
    static var alphahash_fragment:String = Lib.alphahash_fragment;
    static var alphahash_pars_fragment:String = Lib.alphahash_pars_fragment;
    // ... 其他变量和方法

    static function background_vert():String {
        return Lib.background.vertex;
    }

    static function background_frag():String {
        return Lib.background.fragment;
    }

    // ... 其他方法
}