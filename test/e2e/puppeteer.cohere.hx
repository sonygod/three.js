import haxe.io.Path;
import js.Browser.window;
import js.node.Fs;
import js.node.express.Application;
import js.node.express.Request;
import js.node.express.Response;
import js.node.express.Server;
import js.node.express.static;
import js.node.net.Server as NodeServer;

class PromiseQueue {
    var func: Dynamic;
    var args: Array<Dynamic>;
    var promises: Array<Future>;

    public function new(f: Function, ?args: Array<Dynamic>) {
        func = f;
        if (args != null) {
            this.args = args;
        }
        promises = [];
    }

    public function add(?args: Array<Dynamic>) {
        var promise = func(...(args ?? this.args));
        promises.push(promise);
        promise.then(function () {
            promises.remove(promise);
        });
    }

    public function waitForAll(): Future {
        while (promises.length > 0) {
            Promise.all(promises);
        }
    }
}

class Main {
    static var idleTime = 9; // 9 seconds - for how long there should be no network requests
    static var parseTime = 6; // 6 seconds per megabyte

    static var exceptionList = [
        // video tag isn't deterministic enough?
        "css3d_youtube",
        "webgl_materials_video",
        "webgl_video_kinect",
        "webgl_video_panorama_equirectangular",

        // audio can't be analyzed without proper audio hook
        "webaudio_visualizer",

        // WebXR also isn't determinstic enough?
        "webxr_ar_lighting",
        "webxr_vr_sandbox",
        "webxr_vr_video",
        "webxr_xr_ballshooter",

        // in a worker, not robust
        "webgl_worker_offscreencanvas",

        // Windows-Linux text rendering differences
        // TODO: Fix these by e.g. disabling text rendering altogether -- this can also fix a bunch of 0.1%-0.2% examples
        "css3d_periodictable",
        "misc_controls_pointerlock",
        "misc_uv_tests",
        "webgl_camera_logarithmicdepthbuffer",
        "webgl_effects_ascii",
        "webgl_geometry_extrude_shapes",
        "webgl_interactive_lines",
        "webgl_loader_collada_kinematics",
        "webgl_loader_ldraw",
        "webgl_loader_pdb",
        "webgl_modifier_simplifier",
        "webgl_multiple_canvases_circle",
        "webgl_multiple_elements_text",

        // Unknown
        // TODO: most of these can be fixed just by increasing idleTime and parseTime
        "webgl_animation_skinning_blending",
        "webgl_animation_skinning_additive_blending",
        "webgl_buffergeometry_glbufferattribute",
        "webgl_interactive_cubes_gpu",
        "webgl_clipping_advanced",
        "webgl_lensflares",
        "webgl_lights_spotlights",
        "webgl_loader_imagebitmap",
        "webgl_loader_texture_ktx",
        "webgl_loader_texture_lottie",
        "webgl_loader_texture_pvrtc",
        "webgl_materials_alphahash",
        "webgl_materials_blending",
        "webgl_mirror",
        "webgl_morphtargets_face",
        "webgl_postprocessing_transition",
        "webgl_postprocessing_glitch",
        "webgl_postprocessing_dof2",
        "webgl_raymarching_reflect",
        "webgl_renderer_pathtracer",
        "webgl_shadowmap",
        "webgl_shadowmap_progressive",
        "webgl_test_memory2",
        "webgl_tiled_forward",
        "webgl2_volume_instancing",
        "webgl2_multisampled_renderbuffers",
        "webgl_points_dynamic",
        "webgpu_multisampled_renderbuffers",

        // TODO: implement determinism for setTimeout and setInterval
        // could it fix some examples from above?
        "physics_rapier_instancing",
        "physics_jolt_instancing",

        // Awaiting for WebGL backend support
        "webgpu_clearcoat",
        "webgpu_compute_audio",
        "webgpu_compute_texture",
        "webgpu_compute_texture_pingpong",
        "webgpu_materials",
        "webgpu_sandbox",
        "webgpu_sprites",
        "webgpu_video_panorama",

        // Awaiting for WebGPU Backend support in Puppeteer
        "webgpu_storage_buffer",

        // WebGPURenderer: Unknown problem
        "webgpu_postprocessing_afterimage",
        "webgpu_backdrop_water",
        "webgpu_camera_logarithmicdepthbuffer",
        "webgpu_clipping",
        "webgpu_instance_points",
        "webgpu_loader_materialx",
        "webgpu_materials_displacementmap",
        "webgpu_materials_video",
        "webgpu_materialx_noise",
        "webgpu_morphtargets_face",
        "webgpu_occlusion",
        "webgpu_particles",
        "webgpu_shadertoy",
        "webgpu_shadowmap",
        "webgpu_tsl_editor",
        "webgpu_tsl_transpiler",
        "webgpu_portal",
        "webgpu_custom_fog",
        "webgpu_instancing_morph",
        "webgpu_mesh_batch",
        "webgpu_texturegrad",

        // WebGPU idleTime and parseTime too low
        "webgpu_compute_particles",
        "webgpu_compute_particles_rain",
        "webgpu_compute_particles_snow",
        "webgpu_compute_points",
        "webgpu_materials_texture_anisotropy"
    ];

    static var port = 1234;
    static var pixelThreshold = 0.1; // threshold error in one pixel
    static var maxDifferentPixels = 0.3; // at most 0.3% different pixels

    static var networkTimeout = 5; // 5 minutes, set to 0 to disable
    static var renderTimeout = 5; // 5 seconds, set to 0 to disable

    static var numAttempts = 2; // perform 2 attempts before failing

    static var numPages = 8; // use 8 browser pages

    static var numCIJobs = 4; // GitHub Actions run the script in 4 threads

    static var width = 400;
    static var height = 250;
    static var viewScale = 2;
    static var jpgQuality = 95;

    static function main() {
        // Launch server
        var app = Application.new();
        app.use(static(Path.resolve(".")));
        var server = Server.listen(port, main_);

        window.on("SIGINT", close);
    }

    static function main_() {
        // Create output directory
        try {
            Fs.rm("test/e2e/output-screenshots", { recursive: true, force: true });
        } catch (_) {}
        try {
            Fs.mkdir("test/e2e/output-screenshots");
        } catch (_) {}

        // Find files
        var isMakeScreenshot = Sys.args.indexOf("--make") != -1;

        var exactList = Sys.args.slice(isMakeScreenshot ? 3 : 2, Sys.args.length).map($s -> $s.replace(".html", ""));

        var isExactList = exactList.length != 0;

        var files = Fs.readdirSync("examples").filter($s -> $s.endsWith(".html") && $s != "index.html").map($s -> $s.replace(".html", "")).filter($f -> isExactList ? exactList.contains($f) : !exceptionList.contains($f));

        if (isExactList) {
            for (file in exactList) {
                if (!files.contains(file)) {
                    trace("Warning! Unrecognised example name: $file");
                }
            }
        }

        // CI parallelism
        if (Sys.env.exists("CI")) {
            var CI = Std.parseInt(Sys.env("CI"));

            files = files.slice(
                Std.int(CI * files.length / numCIJobs),
                Std.int((CI + 1) * files.length / numCIJobs)
            );
        }

        // Launch browser
        var flags = ["--hide-scrollbars", "--enable-gpu"];
        // flags.push('--enable-unsafe-webgpu', '--enable-features=Vulkan', '--use-gl=swiftshader', '--use-angle=swiftshader', '--use-vulkan=swiftshader', '--use-webgpu-adapter=swiftshader' );
        // if (process.platform === 'linux') flags.push('--enable-features=Vulkan,UseSkiaRenderer', '--use-vulkan=native', '--disable-vulkan-surface', '--disable-features=VaapiVideoDecoder', '--ignore-gpu-blocklist', '--use-angle=vulkan' );

        var viewport = { width: width * viewScale, height: height * viewScale };

        var browser = js.Browser.puppeteer.launch({
            headless: Sys.env.exists("VISIBLE") ? false : "new",
            args: flags,
            defaultViewport: viewport,
            handleSIGINT: false,
            protocolTimeout: 0
        });

        // Prepare injections
        var cleanPage = Fs.readFileSync("test/e2e/clean-page.js", "utf8");
        var injection = Fs.readFileSync("test/e2e/deterministic-injection.js", "utf8");
        var build = Fs.readFileSync("build/three.module.js", "utf8").replace(/#Math\.random\(\)\*0xffffffff/g, "Math._random() * 0xffffffff");

        // Prepare pages
        var errorMessagesCache = [];

        var pages = browser.pages();
        while (pages.length < numPages && pages.length < files.length) {
            pages.push(browser.newPage());
        }

        for (page in pages) {
            preparePage(page, injection, build, errorMessagesCache);
        }

        // Loop for each file
        var failedScreenshots = [];

        var queue = PromiseQueue.new(makeAttempt, pages, failedScreenshots, cleanPage, isMakeScreenshot);
        for (file in files) {
            queue.add([file]);
        }
        queue.waitForAll();

        // Finish
        failedScreenshots.sort();
        var list = failedScreenshots.join(" ");

        if (isMakeScreenshot && failedScreenshots.length > 0) {
            trace("List of failed screenshots: $list");
            trace("If you are sure that everything is correct, try to run \"npm run make-screenshot $list\". If this does not help, try increasing idleTime and parseTime variables in /test/e2e/puppeteer.js file. If this also does not help, add remaining screenshots to the exception list.");
            trace("$failedScreenshots.length from ${files.length} screenshots have not generated succesfully.");
        } else if (isMakeScreenshot && failedScreenshots.length == 0) {
            trace("${files.length} screenshots succesfully generated.");
        } else if (failedScreenshots.length > 0) {
            trace("List of failed screenshots: $list");
            trace("If you are sure that everything is correct, try to run \"npm run make-screenshot $list\". If this does not help, try increasing idleTime and parseTime variables in /test/e2e/puppeteer.js file. If this also does not help, add remaining screenshots to the exception list.");
            trace("TEST FAILED! ${failedScreenshots.length} from ${files.length} screenshots have not rendered correctly.");
        } else {
            trace("TEST PASSED! ${files.length} screenshots rendered correctly.");
        }

        Sys.setTimeout(close, 300, failedScreenshots.length);
    }

    static function preparePage(page, injection, build, errorMessages) {
        // let page.file, page.pageSize, page.error

        page.evaluateOnNewDocument(injection);
        page.setRequestInterception(true);

        page.on("console", function (msg) {
            var type = msg.type();

            if (type != "warning" && type != "error") {
                return;
            }

            var file = page.file;

            if (file == null) {
                return;
            }

            var args = msg.args().map($arg -> $arg.executionContext().evaluate(function (arg) {
                if (js.Boot.instanceof(arg, js.html.Error)) {
                    return arg.message;
                } else {
                    return arg;
                }
            }, arg));

            var text = args.join(" "); // https://github.com/puppeteer/puppeteer/issues/3397#issuecomment-434970058

            text = text.trim();
            if (text == "") {
                return;
            }

            text = "$file: $text".replace(/\[\.WebGL\-(.+?)\] /g, "");

            if (text == "$file: JSHandle@error") {
                text = "$file: Unknown error";
            }

            if (text.includes("Unable to access the camera/webcam")) {
                return;
            }

            if (errorMessages.contains(text)) {
                return;
            }

            errorMessages.push(text);

            if (type == "warning") {
                trace(text);
            } else {
                page.error = text;
            }
        });

        page.on("response", function (response) {
            if (response.status() == 200) {
                response.buffer().then(function (buffer) {
                    page.pageSize += buffer.length;
                });
            }
        });

        page.on("request", function (request) {
            if (request.url() == `http://localhost:${port}/build/three.module.js`) {
                request.respond({
                    status: 200,
                    contentType: "application/javascript; charset=utf-8",
                    body: build
                });
            } else {
                request.continue();
            }
        });
    }

    static function makeAttempt(pages, failedScreenshots, cleanPage, isMakeScreenshot, file, attemptID = 0) {
        var page = null;

        var interval = Sys.setInterval(function () {
            for (page_ in pages) {
                var page = page_;

                if (page.file == null) {
                    page.file = file; // acquire lock
                    Sys.clearInterval(interval);
                    return;
                }
            }
        }, 100);

        try {
            page.pageSize = 0;
            page.error = null;

            // Load target page
            try {
                page.goto(`http://localhost:${port}/examples/$file.html`, {
                    waitUntil: "networkidle0",
                    timeout: networkTimeout * 60000
                });
            } catch (e) {
                throw "Error happened while loading file $file: ${e}";
            }

            try {
                // Render page
                page.evaluate(cleanPage);

                page.waitForNetworkIdle({
                    timeout: networkTimeout * 60000,
                    idleTime: idleTime * 1000
                });

                page.evaluate(function (renderTimeout, parseTime) {
                    Sys.setTimeout(function () {
                        // Resolve render promise
                        window._renderStarted = true;

                        var renderStart = performance._now();

                        var waitingLoop = Sys.setInterval(function () {
                            var renderTimeoutExceeded = (renderTimeout > 0) && (performance._now() - renderStart > 1000 * renderTimeout);

                            if (renderTimeoutExceeded) {
                                Sys.clearInterval(waitingLoop);
                                throw "Render timeout exceeded";
                            } else if (window._renderFinished) {
                                Sys.clearInterval(waitingLoop);
                            }
                        }, 10);
                    }, parseTime * page.pageSize / 1024 / 1024 * 1000);
                }, renderTimeout, page.pageSize / 1024 / 1024 * parseTime * 1000);
            } catch (e) {
                if (e.includes("Render timeout exceeded") == false) {
                    throw "Error happened while rendering file $file: ${e}";
                }
            }

            var screenshot = page.screenshot().scale(1 / viewScale).quality(jpgQuality);

            if (page.error != null) {
                throw page.error;
            }

            if (isMakeScreenshot) {
                // Make screenshots
                screenshot.writeAsync(`examples/screenshots/$file.jpg`);

                trace("Screenshot generated for file $file");
            } else {
                // Diff screenshots
                var expected = null;

                try {
                    expected = jimp.read(`examples/screenshots/$file.jpg`).quality(jpgQuality);
                } catch (_) {
                    screenshot.writeAsync(`test/e2e/output-screenshots/$file-actual.jpg`);
                    throw "Screenshot does not exist: $file";
                }

                var actual = screenshot.bitmap;
                var diff = screenshot.clone();

                var numDifferentPixels = 0;

                try {
                    numDifferentPixels = pixelmatch(expected.bitmap.data, actual.data, diff.bitmap.data, actual.width, actual.height, {
                        threshold: pixelThreshold,
                        alpha: 0.2
                    });
                } catch (_) {
                    screenshot.writeAsync(`test/e2e/output-screenshots/$file-actual.jpg`);
                    expected.writeAsync(`test/e2e/output-screenshots/$file-expected.jpg`);
                    throw "Image sizes does not match in file: $file";
                }

                // Print results
                var differentPixels = numDifferentPixels / (actual.width * actual.height) * 100;

                if (differentPixels < maxDifferentPixels) {
                    trace("Diff ${differentPixels.toFixed(1)}% in file: $file");
                } else {
                    screenshot.writeAsync(`test/e2e/output-screenshots/$file-
                    actual.jpg`);
                    expected.writeAsync(`test/e2e/output-screenshots/$file-expected.jpg`);
                    diff.writeAsync(`test/e2e/output-screenshots/$file-diff.jpg`);
                    throw "Diff wrong in ${differentPixels.toFixed(1)}% of pixels in file: $file";
                }
            }
        } catch (e) {
            if (attemptID == numAttempts - 1) {
                trace(e);
                failedScreenshots.push(file);
            } else {
                trace("$e, another attempt...");
                makeAttempt(pages, failedScreenshots, cleanPage, isMakeScreenshot, file, attemptID + 1);
            }
        }

        page.file = null; // release lock
    }

    static function close(exitCode = 1) {
        trace("Closing...");

        browser.close();
        server.close();
        Sys.exit(exitCode);
    }
}