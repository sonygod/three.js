class Main {
	public static function main():Void {
		// Haxe doesn't have a direct equivalent of glsl preprocessors.
		// You would typically manage these definitions in your Haxe code
		// and conditionally build the shader string.
		var useTangent:Bool = false; // Replace with your actual logic
		var useBatching:Bool = false;
		var useInstancing:Bool = false;
		var flipSided:Bool = false;

		var glsl:String = 
			"vec3 transformedNormal = objectNormal;\n" +
			(useTangent ? 
				"vec3 transformedTangent = objectTangent;\n" 
				: "") + 
			(useBatching ? 
				"mat3 bm = mat3( batchingMatrix );\n" +
				"transformedNormal /= vec3( dot( bm[ 0 ], bm[ 0 ] ), dot( bm[ 1 ], bm[ 1 ] ), dot( bm[ 2 ], bm[ 2 ] ) );\n" +
				"transformedNormal = bm * transformedNormal;\n" +
				(useTangent ?
					"transformedTangent = bm * transformedTangent;\n"
					: "")
				: "") +
			(useInstancing ?
				"mat3 im = mat3( instanceMatrix );\n" +
				"transformedNormal /= vec3( dot( im[ 0 ], im[ 0 ] ), dot( im[ 1 ], im[ 1 ] ), dot( im[ 2 ], im[ 2 ] ) );\n" +
				"transformedNormal = im * transformedNormal;\n" +
				(useTangent ?
					"transformedTangent = im * transformedTangent;\n"
					: "")
				: "") +
			"transformedNormal = normalMatrix * transformedNormal;\n" +
			(flipSided ?
				"transformedNormal = - transformedNormal;\n"
				: "") +
			(useTangent ? 
				"transformedTangent = ( modelViewMatrix * vec4( transformedTangent, 0.0 ) ).xyz;\n" +
				(flipSided ?
					"transformedTangent = - transformedTangent;\n"
					: "")
				: "");
        
        // Use the generated glsl string
        trace(glsl);
	}
}