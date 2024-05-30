import js.Browser;
import js.html.CanvasElement;
import js.html.Document;
import js.html.Window;
import js.Node;
import js.d3.d3;

class Main {
    static function main() {
        var d3 = js.d3.d3;
        var width = 960;
        var height = 500;
        var canvas = CanvasElement({ width: width, height: height });
        var svg = d3.select(canvas).append("svg")
            .attr("width", width)
            .attr("height", height);
        var g = svg.append("g");
        var simulation = d3.forceSimulation()
            .force("link", d3.forceLink().id(function (d) { return d.id; }))
            .force("charge", d3.forceManyBody())
            .force("center", d3.forceCenter(width / 2, height / 2));
        d3.json("miserables.json", function (error, graph) {
            if (error) throw error;
            var link = g.append("g")
                .attr("class", "links")
                .selectAll("line")
                .data(graph.links)
                .enter().append("line")
                .attr("stroke-width", function (d) { return Math.sqrt(d.value); });
            var node = g.append("g")
                .attr("class", "nodes")
                .selectAll("circle")
                .data(graph.nodes)
                .enter().append("circle")
                .attr("r", 5)
                .call(d3.drag()
                    .on("start", dragstarted)
                    .on("drag", dragged)
                    .on("end", dragended));
            node.append("title")
                .text(function (d) { return d.id; });
            simulation
                .nodes(graph.nodes)
                .on("tick", ticked);
            simulation.force("link")
                .links(graph.links);
            function ticked() {
                link
                    .attr("x1", function (d) { return d.source.x; })
                    .attr("y1", function (d) { return d.source.y; })
                    .attr("x2", function (d) { return d.target.x; })
                    .attr("y2", function (d) { return d.target.y; });
                node
                    .attr("cx", function (d) { return d.x; })
                    .attr("cy", function (d) { return d.y; });
            }
            function dragstarted(d) {
                if (!d3.event.active) simulation.alphaTarget(0.3).restart();
                d.fx = d.x;
                d.fy = d.y;
            }
            function dragged(d) {
                d.fx = d3.event.x;
                d.fy = d3.event.y;
            }
            function dragended(d) {
                if (!d3.event.active) simulation.alphaTarget(0);
                d.fx = null;
                d.fy = null;
            }
        });
        var body = cast Document(Window.window).body;
        body.appendChild(canvas);
    }
}

class js__$d3_ForceSimulation {
    var _hx_fields = ["_hx_node", "_hx_simulation"];
    var _hx_node;
    var _hx_simulation;
    function new(node) {
        this._hx_node = node;
        this._hx_simulation = d3.forceSimulation(node);
        return this;
    }
    function force(name, force) {
        this._hx_simulation.force(name, force);
        return this;
    }
    function nodes(nodes) {
        this._hx_simulation.nodes(nodes);
        return this;
    }
    function on(type, listener) {
        this._hx_simulation.on(type, listener);
        return this;
    }
    function alpha(value) {
        this._hx_simulation.alpha(value);
        return this;
    }
    function alphaTarget(value) {
        this._hx_simulation.alphaTarget(value);
        return this;
    }
    function alphaMin(value) {
        this._hx_simulation.alphaMin(value);
        return this;
    }
    function alphaDecay(value) {
        this._hx_simulation.alphaDecay(value);
        return this;
    }
    function restart() {
        this._hx_simulation.restart();
    }
    function stop() {
        this._hx_simulation.stop();
    }
    function tick() {
        this._hx_simulation.tick();
    }
    function find(x, y) {
        return this._hx_simulation.find(x, y);
    }
    function static init() {
        return new js__$d3_ForceSimulation(null);
    }
}
class js__$d3_Force {
    var _hx_fields = ["_hx_force"];
    var _hx_force;
    function new(force) {
        this._hx_force = force;
        return this;
    }
    function id(x) {
        this._hx_force.id(x);
        return this;
    }
    function strength(x) {
        this._hx_force.strength(x);
        return this;
    }
    function distanceMin(x) {
        this._hx_force.distanceMin(x);
        return this;
    }
    function distanceMax(x) {
        this._hx_force.distanceMax(x);
        return this;
    }
    function iterations(x) {
        this._hx_force.iterations(x);
        return this;
    }
    function static init() {
        return new js__$d3_Force(null);
    }
}
class js__$d3_ForceLink {
    var _hx_fields = ["_hx_force"];
    var _hx_force;
    function new(force) {
        this._hx_force = force;
        return this;
    }
    function id(x) {
        this._hx_force.id(x);
        return this;
    }
    function links(x) {
        this._hx_force.links(x);
        return this;
    }
    function static init() {
        return new js__$d3_ForceLink(null);
    }
}
class js__$d3_ForceManyBody {
    var _hx_fields = ["_hx_force"];
    var _hx_force;
    function new(force) {
        this._hx_force = force;
        return this;
    }
    function strength(x) {
        this._hx_force.strength(x);
        return this;
    }
    function theta(x) {
        this._hx_force.theta(x);
        return this;
    }
    function distanceMin(x) {
        this._hx_force.distanceMin(x);
        return this;
    }
    function distanceMax(x) {
        this._hx_force.distanceMax(x);
        return this;
    }
    function static init() {
        return new js__$d3_ForceManyBody(null);
    }
}
class js__$d3_ForceCenter {
    var _hx_fields = ["_hx_force"];
    var _hx_force;
    function new(force) {
        this._hx_force = force;
        return this;
    }
    function x(x) {
        this._hx_force.x(x);
        return this;
    }
    function y(x) {
        this._hx_force.y(x);
        return this;
    }
    function static init() {
        return new js__$d3_ForceCenter(null);
    }
}
class js__$d3_Selection {
    var _hx_fields = ["_hx_selection"];
    var _hx_selection;
    function new(selection) {
        this._hx_selection = selection;
        return this;
    }
    function append(name) {
        return new js__$d3_Selection(this._hx_selection.append(name));
    }
    function attr(name, value) {
        this._hx_selection.attr(name, value);
        return this;
    }
    function call(func) {
        this._hx_selection.call(func);
        return this;
    }
    function data(data) {
        this._hx_selection.data(data);
        return this;
    }
    function enter() {
        return new js__$d3_SelectionEnter(this._hx_selection.enter());
    }
    function on(name, listener) {
        this._hx_selection.on(name, listener);
        return this;
    }
    function select(selector) {
        return new js__$d3_Selection(this._hx_selection.select(selector));
    }
    function static init() {
        return new js__$d3_Selection(null);
    }
}
class js__$d3_SelectionEnter {
    var _hx_fields = ["_hx_enter"];
    var _hx_enter;
    function new(enter) {
        this._hx_enter = enter;
        return this;
    }
    function append(name) {
        return new js__$d3_Selection(this._hx_enter.append(name));
    }
    function attr(name, value) {
        this._hx_enter.attr(name, value);
        return this;
    }
    function select(selector) {
        return new js__$d3_Selection(this._hx_enter.select(selector));
    }
    function static init() {
        return new js__$d3_SelectionEnter(null);
    }
}
class js__$html_CanvasElement {
    var _hx_fields = ["_hx_node"];
    var _hx_node;
    function new(node) {
        this._hx_node = node;
        return this;
    }
    function static init(width, height) {
        return new js__$html_CanvasElement(js.Browser.document.createElement("canvas"));
    }
}
class js__$html_Document {
    var _hx_fields = ["_hx_node"];
    var _hx_node;
    function new(node) {
        this._hx_node = node;
        return this;
    }
    function static init() {
        return new js__$html_Document(js.Browser.document);
    }
}
class js__$html_Element {
    var _hx_fields = ["_hx_node"];
    var _hx_node;
    function new(node) {
        this._hx_node = node;
        return this;
    }
    function appendChild(node) {
        this._hx_node.appendChild(cast js.Node(node)._hx_node);
    }
    function static init() {
        return new js__$html_Element(null);
    }
}
class js__$html_Window {
    var _hx_fields = ["_hx_node"];
    var _hx_node;
    function new(node) {
        this._hx_node = node;
        return this;
    }
    function static init() {
        return new js__$html_Window(js.Browser.window);
    }
}
class js_html__$CanvasElement_Canvas2DContext {
    var _hx_fields = ["_hx_object"];
    var _hx_object;
    function new(o) {
        this._hx_object = o;
        return this;
    }
    function fillRect(x, y, width, height) {
        this._hx_object.fillRect(x, y, width, height);
    }
    function static init(o) {
        return new js_html__$CanvasElement_Canvas2DContext(o);
    }
}
class js_html_CanvasElement {
    var _hx_fields = ["_hx_node"];
    var _hx_node;
    function new(node) {
        this._hx_node = node;
        return this;
    }
    function getContext2D() {
        return new js_html__$CanvasElement_Canvas2DContext(this._hx_node.getContext("2d"));
    }
    function static init(width, height) {
        return new js_html_CanvasElement(js.Browser.document.createElement("canvas"));
    }
}
class js_Node {
    var _hx_fields = ["_hx_node"];
    var _hx_node;
    function new(node) {
        this._hx_node = node;
        return this;
    }
    function static init() {
        return new js_Node(null);
    }
}
class Main {
}
Main.main();