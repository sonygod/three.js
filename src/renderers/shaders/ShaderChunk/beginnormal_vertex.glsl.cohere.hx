var normalMaterial = {
	normalShader: {
		params: {
			normalMap: { type: "sampler2D", value: null },
			objectNormal: { type: "vec3", value: new openfl.Vector3(0.0, 0.0, 1.0) }
		},
		fragmentSrc: [
			"varying vec2 vUv;",
			"uniform sampler2D normalMap;",
			"uniform vec3 objectNormal;",
			"void main() {",
			"	vec3 normal = texture2D(normalMap, vUv).xyz * 2.0 - 1.0;",
			"	normal = normalize(normal * vec3(1.0, -1.0, 1.0));",
			"	normal = normalize(objectNormal + normal);",
			"	gl_FragColor = vec4(0.5 * normal + 0.5, 1.0);",
			"}"
		].join("\n")
	}
};