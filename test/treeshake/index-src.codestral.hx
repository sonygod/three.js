import three.THREE;

var camera:THREE.PerspectiveCamera;
var scene:THREE.Scene;
var renderer:THREE.WebGLRenderer;

function init() {

	camera = new THREE.PerspectiveCamera( 70, window.innerWidth / window.innerHeight, 0.01, 10 );

	scene = new THREE.Scene();

	renderer = new THREE.WebGLRenderer( { antialias: true } );
	renderer.setSize( window.innerWidth, window.innerHeight );
	renderer.setAnimationLoop( animation );
	js.Browser.document.body.appendChild( renderer.domElement );

}

function animation() {

	renderer.render( scene, camera );

}

init();