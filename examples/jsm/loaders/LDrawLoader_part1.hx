package three.js.examples.jsm.loaders;

import haxe.ds.ObjectMap;
import three.js.renderers.ShaderMaterial;
import three.js.renderers.shaders.UniformsLib;
import three.js.math.Color;

class LDrawConditionalLineMaterial extends ShaderMaterial {
    public var isLDrawConditionalLineMaterial:Bool = true;

    public function new(parameters:Dynamic) {
        super({
            uniforms: UniformsLib.merge([
                UniformsLib.fog,
                {
                    diffuse: { value: new Color() },
                    opacity: { value: 1.0 }
                }
            ]),
            vertexShader: '
                attribute vec3 control0;
                attribute vec3 control1;
                attribute vec3 direction;
                varying float discardFlag;

                #include <common>
                #include <color_pars_vertex>
                #include <fog_pars_vertex>
                #include <logdepthbuf_pars_vertex>
                #include <clipping_planes_pars_vertex>
                void main() {
                    #include <color_vertex>

                    vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );
                    gl_Position = projectionMatrix * mvPosition;

                    // Transform the line segment ends and control points into camera clip space
                    vec4 c0 = projectionMatrix * modelViewMatrix * vec4( control0, 1.0 );
                    vec4 c1 = projectionMatrix * modelViewMatrix * vec4( control1, 1.0 );
                    vec4 p0 = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                    vec4 p1 = projectionMatrix * modelViewMatrix * vec4( position + direction, 1.0 );

                    c0.xy /= c0.w;
                    c1.xy /= c1.w;
                    p0.xy /= p0.w;
                    p1.xy /= p1.w;

                    // Get the direction of the segment and an orthogonal vector
                    vec2 dir = p1.xy - p0.xy;
                    vec2 norm = vec2( -dir.y, dir.x );

                    // Get control point directions from the line
                    vec2 c0dir = c0.xy - p1.xy;
                    vec2 c1dir = c1.xy - p1.xy;

                    // If the vectors to the controls points are pointed in different directions away
                    // from the line segment then the line should not be drawn.
                    float d0 = dot( normalize( norm ), normalize( c0dir ) );
                    float d1 = dot( normalize( norm ), normalize( c1dir ) );
                    discardFlag = float( sign( d0 ) != sign( d1 ) );

                    #include <logdepthbuf_vertex>
                    #include <clipping_planes_vertex>
                    #include <fog_vertex>
                }
            ',
            fragmentShader: '
                uniform vec3 diffuse;
                uniform float opacity;
                varying float discardFlag;

                #include <common>
                #include <color_pars_fragment>
                #include <fog_pars_fragment>
                #include <logdepthbuf_pars_fragment>
                #include <clipping_planes_pars_fragment>
                void main() {

                    if ( discardFlag > 0.5 ) discard;

                    #include <clipping_planes_fragment>
                    vec3 outgoingLight = vec3( 0.0 );
                    vec4 diffuseColor = vec4( diffuse, opacity );
                    #include <logdepthbuf_fragment>
                    #include <color_fragment>
                    outgoingLight = diffuseColor.rgb; // simple shader
                    gl_FragColor = vec4( outgoingLight, diffuseColor.a );
                    #include <tonemapping_fragment>
                    #include <colorspace_fragment>
                    #include <fog_fragment>
                    #include <premultiplied_alpha_fragment>
                }
            '
        });

        this.setValues(parameters);

        this.addEventListener("opacity", function(value:Float) {
            this.uniforms.opacity.value = value;
        });

        this.addEventListener("color", function(value:Color) {
            this.uniforms.diffuse.value = value;
        });
    }

    public function get_opacity():Float {
        return this.uniforms.opacity.value;
    }

    public function set_opacity(value:Float):Void {
        this.uniforms.opacity.value = value;
    }

    public function get_color():Color {
        return this.uniforms.diffuse.value;
    }
}