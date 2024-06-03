import three.Vector2;
import three.Vector3;

class VolumeRenderShader1 {
    public var uniforms:Map<String, Dynamic>;
    public var vertexShader:String;
    public var fragmentShader:String;

    public function new() {
        uniforms = new Map<String, Dynamic>();
        uniforms["u_size"] = { value: new Vector3( 1, 1, 1 ) };
        uniforms["u_renderstyle"] = { value: 0 };
        uniforms["u_renderthreshold"] = { value: 0.5 };
        uniforms["u_clim"] = { value: new Vector2( 1, 1 ) };
        uniforms["u_data"] = { value: null };
        uniforms["u_cmdata"] = { value: null };

        vertexShader = """
            varying vec4 v_nearpos;
            varying vec4 v_farpos;
            varying vec3 v_position;

            void main() {
                mat4 viewtransformf = modelViewMatrix;
                mat4 viewtransformi = inverse(modelViewMatrix);

                vec4 position4 = vec4(position, 1.0);
                vec4 pos_in_cam = viewtransformf * position4;

                pos_in_cam.z = -pos_in_cam.w;
                v_nearpos = viewtransformi * pos_in_cam;

                pos_in_cam.z = pos_in_cam.w;
                v_farpos = viewtransformi * pos_in_cam;

                v_position = position;
                gl_Position = projectionMatrix * viewMatrix * modelMatrix * position4;
            }
        """;

        fragmentShader = """
            precision highp float;
            precision mediump sampler3D;

            uniform vec3 u_size;
            uniform int u_renderstyle;
            uniform float u_renderthreshold;
            uniform vec2 u_clim;

            uniform sampler3D u_data;
            uniform sampler2D u_cmdata;

            varying vec3 v_position;
            varying vec4 v_nearpos;
            varying vec4 v_farpos;

            const int MAX_STEPS = 887;
            const int REFINEMENT_STEPS = 4;
            const float relative_step_size = 1.0;
            const vec4 ambient_color = vec4(0.2, 0.4, 0.2, 1.0);
            const vec4 diffuse_color = vec4(0.8, 0.2, 0.2, 1.0);
            const vec4 specular_color = vec4(1.0, 1.0, 1.0, 1.0);
            const float shininess = 40.0;

            void cast_mip(vec3 start_loc, vec3 step, int nsteps, vec3 view_ray);
            void cast_iso(vec3 start_loc, vec3 step, int nsteps, vec3 view_ray);

            float sample1(vec3 texcoords);
            vec4 apply_colormap(float val);
            vec4 add_lighting(float val, vec3 loc, vec3 step, vec3 view_ray);

            void main() {
                vec3 farpos = v_farpos.xyz / v_farpos.w;
                vec3 nearpos = v_nearpos.xyz / v_nearpos.w;

                vec3 view_ray = normalize(nearpos.xyz - farpos.xyz);

                float distance = dot(nearpos - v_position, view_ray);
                distance = max(distance, min((-0.5 - v_position.x) / view_ray.x,
                                             (u_size.x - 0.5 - v_position.x) / view_ray.x));
                distance = max(distance, min((-0.5 - v_position.y) / view_ray.y,
                                             (u_size.y - 0.5 - v_position.y) / view_ray.y));
                distance = max(distance, min((-0.5 - v_position.z) / view_ray.z,
                                             (u_size.z - 0.5 - v_position.z) / view_ray.z));

                vec3 front = v_position + view_ray * distance;

                int nsteps = int(-distance / relative_step_size + 0.5);
                if ( nsteps < 1 )
                    discard;

                vec3 step = ((v_position - front) / u_size) / float(nsteps);
                vec3 start_loc = front / u_size;

                if (u_renderstyle == 0)
                    cast_mip(start_loc, step, nsteps, view_ray);
                else if (u_renderstyle == 1)
                    cast_iso(start_loc, step, nsteps, view_ray);

                if (gl_FragColor.a < 0.05)
                    discard;
            }

            float sample1(vec3 texcoords) {
                return texture(u_data, texcoords.xyz).r;
            }

            vec4 apply_colormap(float val) {
                val = (val - u_clim[0]) / (u_clim[1] - u_clim[0]);
                return texture2D(u_cmdata, vec2(val, 0.5));
            }

            void cast_mip(vec3 start_loc, vec3 step, int nsteps, vec3 view_ray) {
                float max_val = -1e6;
                int max_i = 100;
                vec3 loc = start_loc;

                for (int iter=0; iter<MAX_STEPS; iter++) {
                    if (iter >= nsteps)
                        break;

                    float val = sample1(loc);

                    if (val > max_val) {
                        max_val = val;
                        max_i = iter;
                    }

                    loc += step;
                }

                vec3 iloc = start_loc + step * (float(max_i) - 0.5);
                vec3 istep = step / float(REFINEMENT_STEPS);
                for (int i=0; i<REFINEMENT_STEPS; i++) {
                    max_val = max(max_val, sample1(iloc));
                    iloc += istep;
                }

                gl_FragColor = apply_colormap(max_val);
            }

            void cast_iso(vec3 start_loc, vec3 step, int nsteps, vec3 view_ray) {
                gl_FragColor = vec4(0.0);
                vec4 color3 = vec4(0.0);
                vec3 dstep = 1.5 / u_size;
                vec3 loc = start_loc;

                float low_threshold = u_renderthreshold - 0.02 * (u_clim[1] - u_clim[0]);

                for (int iter=0; iter<MAX_STEPS; iter++) {
                    if (iter >= nsteps)
                        break;

                    float val = sample1(loc);

                    if (val > low_threshold) {
                        vec3 iloc = loc - 0.5 * step;
                        vec3 istep = step / float(REFINEMENT_STEPS);
                        for (int i=0; i<REFINEMENT_STEPS; i++) {
                            val = sample1(iloc);
                            if (val > u_renderthreshold) {
                                gl_FragColor = add_lighting(val, iloc, dstep, view_ray);
                                return;
                            }
                            iloc += istep;
                        }
                    }

                    loc += step;
                }
            }

            vec4 add_lighting(float val, vec3 loc, vec3 step, vec3 view_ray) {
                vec3 V = normalize(view_ray);

                vec3 N;
                float val1, val2;
                val1 = sample1(loc + vec3(-step[0], 0.0, 0.0));
                val2 = sample1(loc + vec3(+step[0], 0.0, 0.0));
                N[0] = val1 - val2;
                val = max(max(val1, val2), val);
                val1 = sample1(loc + vec3(0.0, -step[1], 0.0));
                val2 = sample1(loc + vec3(0.0, +step[1], 0.0));
                N[1] = val1 - val2;
                val = max(max(val1, val2), val);
                val1 = sample1(loc + vec3(0.0, 0.0, -step[2]));
                val2 = sample1(loc + vec3(0.0, 0.0, +step[2]));
                N[2] = val1 - val2;
                val = max(max(val1, val2), val);

                float gm = length(N);
                N = normalize(N);

                float Nselect = float(dot(N, V) > 0.0);
                N = (2.0 * Nselect - 1.0) * N;

                vec4 ambient_color = vec4(0.0, 0.0, 0.0, 0.0);
                vec4 diffuse_color = vec4(0.0, 0.0, 0.0, 0.0);
                vec4 specular_color = vec4(0.0, 0.0, 0.0, 0.0);

                for (int i=0; i<1; i++) {
                    vec3 L = normalize(view_ray);
                    float lightEnabled = float( length(L) > 0.0 );
                    L = normalize(L + (1.0 - lightEnabled));

                    float lambertTerm = clamp(dot(N, L), 0.0, 1.0);
                    vec3 H = normalize(L+V);
                    float specularTerm = pow(max(dot(H, N), 0.0), shininess);

                    float mask1 = lightEnabled;

                    ambient_color += mask1 * ambient_color;
                    diffuse_color += mask1 * lambertTerm;
                    specular_color += mask1 * specularTerm * specular_color;
                }

                vec4 final_color;
                vec4 color = apply_colormap(val);
                final_color = color * (ambient_color + diffuse_color) + specular_color;
                final_color.a = color.a;
                return final_color;
            }
        """;
    }
}