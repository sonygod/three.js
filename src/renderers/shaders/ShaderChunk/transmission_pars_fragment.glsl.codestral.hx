// Transmission code is based on glTF-Sampler-Viewer
// https://github.com/KhronosGroup/glTF-Sample-Viewer

class TransmissionFragment {
    // Mipped Bicubic Texture Filtering by N8
    // https://www.shadertoy.com/view/Dl2SDW

    static function w0(a:Float):Float {
        return (1.0 / 6.0) * (a * (a * (-a + 3.0) - 3.0) + 1.0);
    }

    static function w1(a:Float):Float {
        return (1.0 / 6.0) * (a * a * (3.0 * a - 6.0) + 4.0);
    }

    static function w2(a:Float):Float {
        return (1.0 / 6.0) * (a * (a * (-3.0 * a + 3.0) + 3.0) + 1.0);
    }

    static function w3(a:Float):Float {
        return (1.0 / 6.0) * (a * a * a);
    }

    // g0 and g1 are the two amplitude functions
    static function g0(a:Float):Float {
        return w0(a) + w1(a);
    }

    static function g1(a:Float):Float {
        return w2(a) + w3(a);
    }

    // h0 and h1 are the two offset functions
    static function h0(a:Float):Float {
        return -1.0 + w1(a) / (w0(a) + w1(a));
    }

    static function h1(a:Float):Float {
        return 1.0 + w3(a) / (w2(a) + w3(a));
    }

    // Rest of the functions...
}