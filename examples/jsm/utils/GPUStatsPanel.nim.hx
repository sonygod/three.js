import Stats.Panel;

// https://www.khronos.org/registry/webgl/extensions/EXT_disjoint_timer_query_webgl2/
class GPUStatsPanel extends Panel {

	var context:Dynamic;
	var extension:Dynamic;
	var maxTime:Float = 30;
	var activeQueries:Int = 0;

	public function new(context:Dynamic, name:String = 'GPU MS') {

		super(name, '#f90', '#210');

		extension = context.getExtension('EXT_disjoint_timer_query_webgl2');

		if (extension == null) {

			trace('GPUStatsPanel: disjoint_time_query extension not available.');

		}

		this.context = context;
		this.extension = extension;

		this.startQuery = function () {

			var gl = this.context;
			var ext = this.extension;

			if (ext == null) {

				return;

			}

			// create the query object
			var query = gl.createQuery();
			gl.beginQuery(ext.TIME_ELAPSED_EXT, query);

			this.activeQueries++;

			var checkQuery = function () {

				// check if the query is available and valid

				var available = gl.getQueryParameter(query, gl.QUERY_RESULT_AVAILABLE);
				var disjoint = gl.getParameter(ext.GPU_DISJOINT_EXT);
				var ns = gl.getQueryParameter(query, gl.QUERY_RESULT);

				var ms = ns * 1e-6;

				if (available) {

					// update the display if it is valid
					if (!disjoint) {

						this.update(ms, this.maxTime);

					}

					this.activeQueries--;

				} else if (gl.isContextLost() == false) {

					// otherwise try again the next frame
					requestAnimationFrame(checkQuery);

				}

			};

			requestAnimationFrame(checkQuery);

		};

		this.endQuery = function () {

			// finish the query measurement
			var ext = this.extension;
			var gl = this.context;

			if (ext == null) {

				return;

			}

			gl.endQuery(ext.TIME_ELAPSED_EXT);

		};

	}

}