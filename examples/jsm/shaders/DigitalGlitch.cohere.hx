package;

class DigitalGlitch {
    public static var uniforms: { [s: String]: Dynamic; } = {
        'tDiffuse': { value: null },
        'tDisp': { value: null },
        'byp': { value: 0 },
        'amount': { value: 0.08 },
        'angle': { value: 0.02 },
        'seed': { value: 0.02 },
        'seed_x': { value: 0.02 },
        'seed_y': { value: 0.02 },
        'distortion_x': { value: 0.5 },
        'distortion_y': { value: 0.6 },
        'col_s': { value: 0.05 }
    };

    public static var vertexShader: String = """
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    public static var fragmentShader: String = """
        uniform int byp;
        uniform sampler2D tDiffuse;
        uniform sampler2D tDisp;
        uniform float amount;
        uniform float angle;
        uniform float seed;
        uniform float seed_x;
        uniform float seed_y;
        uniform float distortion_x;
        uniform float distortion_y;
        uniform float col_s;
        varying vec2 vUv;

        float rand(vec2 co) {
            return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
        }

        void main() {
            if (byp < 1) {
                vec2 p = vUv;
                float xs = floor(gl_FragCoord.x / 0.5);
                float ys = floor(gl_FragCoord.y / 0.5);
                float disp = texture2D(tDisp, p * seed * seed).r;
                if (p.y < distortion_x + col_s && p.y > distortion_x - col_s * seed) {
                    if (seed_x > 0.) {
                        p.y = 1. - (p.y + distortion_y);
                    } else {
                        p.y = distortion_y;
                    }
                }
                if (p.x < distortion_y + col_s && p.x > distortion_y - col_s * seed) {
                    if (seed_y > 0.) {
                        p.x = distortion_x;
                    } else {
                        p.x = 1. - (p.x + distortion_x);
                    }
                }
                p.x += disp * seed_x * (seed / 5.);
                p.y += disp * seed_y * (seed / 5.);
                vec2 offset = amount * vec2(cos(angle), sin(angle));
                vec4 cr = texture2D(tDiffuse, p + offset);
                vec4 cga = texture2D(tDiffuse, p);
                vec4 cb = texture2D(tDiffuse, p - offset);
                gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);
                vec4 snow = 200. * amount * vec4(rand(vec2(xs * seed, ys * seed * 50.)) * 0.2);
                gl_FragColor = gl_FragColor + snow;
            } else {
                gl_FragColor = texture2D(tDiffuse, vUv);
            }
        }
    """;
}

class Main {
    static public function main() {
        // 您的代码在这里
    }
}