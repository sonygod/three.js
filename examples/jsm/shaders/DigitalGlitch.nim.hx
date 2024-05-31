package three.examples.jsm.shaders;

import js.Lib;
import three.UniformsLib;
import three.UniformsUtils;
import three.WebGLRenderer;
import three.WebGLRenderTarget;
import three.WebGLShader;

class DigitalGlitch {

    public static var uniforms: js.Dynamic;

    public static var vertexShader: String;
    public static var fragmentShader: String;

    static {
        uniforms = {
            'tDiffuse': { value: null }, //diffuse texture
            'tDisp': { value: null }, //displacement texture for digital glitch squares
            'byp': { value: 0 }, //apply the glitch ?
            'amount': { value: 0.08 },
            'angle': { value: 0.02 },
            'seed': { value: 0.02 },
            'seed_x': { value: 0.02 }, //-1,1
            'seed_y': { value: 0.02 }, //-1,1
            'distortion_x': { value: 0.5 },
            'distortion_y': { value: 0.6 },
            'col_s': { value: 0.05 }
        };

        vertexShader =
            "varying vec2 vUv;\n" +
            "void main() {\n" +
            "	vUv = uv;\n" +
            "	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
            "}\n";

        fragmentShader =
            "uniform int byp; //should we apply the glitch ?\n" +
            "uniform sampler2D tDiffuse;\n" +
            "uniform sampler2D tDisp;\n" +
            "uniform float amount;\n" +
            "uniform float angle;\n" +
            "uniform float seed;\n" +
            "uniform float seed_x;\n" +
            "uniform float seed_y;\n" +
            "uniform float distortion_x;\n" +
            "uniform float distortion_y;\n" +
            "uniform float col_s;\n" +
            "\n" +
            "varying vec2 vUv;\n" +
            "\n" +
            "float rand(vec2 co){\n" +
            "	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);\n" +
            "}\n" +
            "\n" +
            "void main() {\n" +
            "	if(byp<1) {\n" +
            "		vec2 p = vUv;\n" +
            "		float xs = floor(gl_FragCoord.x / 0.5);\n" +
            "		float ys = floor(gl_FragCoord.y / 0.5);\n" +
            "		//based on staffantans glitch shader for unity https://github.com/staffantan/unityglitch\n" +
            "		float disp = texture2D(tDisp, p*seed*seed).r;\n" +
            "		if(p.y<distortion_x+col_s && p.y>distortion_x-col_s*seed) {\n" +
            "			if(seed_x>0.){\n" +
            "				p.y = 1. - (p.y + distortion_y);\n" +
            "			} else {\n" +
            "				p.y = distortion_y;\n" +
            "			}\n" +
            "		}\n" +
            "		if(p.x<distortion_y+col_s && p.x>distortion_y-col_s*seed) {\n" +
            "			if(seed_y>0.){\n" +
            "				p.x=distortion_x;\n" +
            "			} else {\n" +
            "				p.x = 1. - (p.x + distortion_x);\n" +
            "			}\n" +
            "		}\n" +
            "		p.x+=disp*seed_x*(seed/5.);\n" +
            "		p.y+=disp*seed_y*(seed/5.);\n" +
            "		//base from RGB shift shader\n" +
            "		vec2 offset = amount * vec2( cos(angle), sin(angle));\n" +
            "		vec4 cr = texture2D(tDiffuse, p + offset);\n" +
            "		vec4 cga = texture2D(tDiffuse, p);\n" +
            "		vec4 cb = texture2D(tDiffuse, p - offset);\n" +
            "		gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);\n" +
            "		//add noise\n" +
            "		vec4 snow = 200.*amount*vec4(rand(vec2(xs * seed,ys * seed*50.))*0.2);\n" +
            "		gl_FragColor = gl_FragColor+ snow;\n" +
            "	} else {\n" +
            "		gl_FragColor=texture2D (tDiffuse, vUv);\n" +
            "	}\n" +
            "}\n";
    }

}