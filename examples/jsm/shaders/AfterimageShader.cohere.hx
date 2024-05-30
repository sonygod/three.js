package;

import haxe.io.Bytes;

class AfterimageShader {
    public var name: String = "AfterimageShader";
    public var uniforms: { [key: String]: { value: Dynamic } } = {
        "damp": { value: 0.96 },
        "tOld": { value: null },
        "tNew": { value: null }
    };
    public var vertexShader: Bytes = #if js '#["varying vec2 vUv;void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}"].join("\n")'# else null #end;
    public var fragmentShader: Bytes = #if js '#["uniform float damp;uniform sampler2D tOld;uniform sampler2D tNew;varying vec2 vUv;vec4 when_gt(vec4 x,float y){return max(sign(x-y),0.0);}void main(){vec4 texelOld=texture2D(tOld,vUv);vec4 texelNew=texture2D(tNew,vUv);texelOld*=damp*when_gt(texelOld,0.1);gl_FragColor=max(texelNew,texelOld);}"].join("\n")'# else null #end;

    public function new() {

    }
}