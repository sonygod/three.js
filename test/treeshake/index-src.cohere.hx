import js.THREE.*;

var camera:PerspectiveCamera;
var scene:Scene;
var renderer:WebGLRenderer;

function init() {
    camera = new PerspectiveCamera(70, Std.int(window.innerWidth) / Std.int(window.innerHeight), 0.01, 10);
    scene = new Scene();
    renderer = new WebGLRenderer({antialias: true});
    renderer.setSize(Std.int(window.innerWidth), Std.int(window.innerHeight));
    renderer.setAnimationLoop(animation);
    document.body.appendChild(renderer.domElement);
}

function animation() {
    renderer.render(scene, camera);
}

init();