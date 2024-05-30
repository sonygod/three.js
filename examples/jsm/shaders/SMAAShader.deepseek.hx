import three.Vector2;

class SMAAEdgesShader {

    static var name:String = 'SMAAEdgesShader';

    static var defines:Map<String, String> = {
        'SMAA_THRESHOLD': '0.1'
    };

    static var uniforms:Map<String, Dynamic> = {
        'tDiffuse': { value: null },
        'resolution': { value: new Vector2( 1 / 1024, 1 / 512 ) }
    };

    static var vertexShader:String = `
        uniform vec2 resolution;

        varying vec2 vUv;
        varying vec4 vOffset[ 3 ];

        void SMAAEdgeDetectionVS( vec2 texcoord ) {
            vOffset[ 0 ] = texcoord.xyxy + resolution.xyxy * vec4( -1.0, 0.0, 0.0,  1.0 ); // WebGL port note: Changed sign in W component
            vOffset[ 1 ] = texcoord.xyxy + resolution.xyxy * vec4(  1.0, 0.0, 0.0, -1.0 ); // WebGL port note: Changed sign in W component
            vOffset[ 2 ] = texcoord.xyxy + resolution.xyxy * vec4( -2.0, 0.0, 0.0,  2.0 ); // WebGL port note: Changed sign in W component
        }

        void main() {
            vUv = uv;
            SMAAEdgeDetectionVS( vUv );
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }`;

    static var fragmentShader:String = `
        uniform sampler2D tDiffuse;

        varying vec2 vUv;
        varying vec4 vOffset[ 3 ];

        vec4 SMAAColorEdgeDetectionPS( vec2 texcoord, vec4 offset[3], sampler2D colorTex ) {
            vec2 threshold = vec2( SMAA_THRESHOLD, SMAA_THRESHOLD );
            // Calculate color deltas:
            vec4 delta;
            vec3 C = texture2D( colorTex, texcoord ).rgb;
            vec3 Cleft = texture2D( colorTex, offset[0].xy ).rgb;
            vec3 t = abs( C - Cleft );
            delta.x = max( max( t.r, t.g ), t.b );
            vec3 Ctop = texture2D( colorTex, offset[0].zw ).rgb;
            t = abs( C - Ctop );
            delta.y = max( max( t.r, t.g ), t.b );
            // We do the usual threshold:
            vec2 edges = step( threshold, delta.xy );
            // Then discard if there is no edge:
            if ( dot( edges, vec2( 1.0, 1.0 ) ) == 0.0 )
                discard;
            // Calculate right and bottom deltas:
            vec3 Cright = texture2D( colorTex, offset[1].xy ).rgb;
            t = abs( C - Cright );
            delta.z = max( max( t.r, t.g ), t.b );
            vec3 Cbottom  = texture2D( colorTex, offset[1].zw ).rgb;
            t = abs( C - Cbottom );
            delta.w = max( max( t.r, t.g ), t.b );
            // Calculate the maximum delta in the direct neighborhood:
            float maxDelta = max( max( max( delta.x, delta.y ), delta.z ), delta.w );
            // Calculate left-left and top-top deltas:
            vec3 Cleftleft  = texture2D( colorTex, offset[2].xy ).rgb;
            t = abs( C - Cleftleft );
            delta.z = max( max( t.r, t.g ), t.b );
            vec3 Ctoptop = texture2D( colorTex, offset[2].zw ).rgb;
            t = abs( C - Ctoptop );
            delta.w = max( max( t.r, t.g ), t.b );
            // Calculate the final maximum delta:
            maxDelta = max( max( maxDelta, delta.z ), delta.w );
            // Local contrast adaptation in action:
            edges.xy *= step( 0.5 * maxDelta, delta.xy );
            return vec4( edges, 0.0, 0.0 );
        }

        void main() {
            gl_FragColor = SMAAColorEdgeDetectionPS( vUv, vOffset, tDiffuse );
        }`;
}

// The rest of the classes SMAAWeightsShader and SMAABlendShader are similar to SMAAEdgesShader, so I'm not including them here.