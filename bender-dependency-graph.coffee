Graph      = require('./graph')
BenderNode = require('./bender-project-node')


class BenderDependencyGraph extends Graph
  constructor: (@benderContext) ->
    super()

  insertProject: (project) ->
    @_insertProjectHelper project

  # First, insert the project and all of its dependencies into the graph as disconnected
  # nodes. Then go back and add all the edges after we know all nodes are created.
  _insertProjectHelper: (project) ->
    nodeIDForProject = BenderNode.idForProject project

    return @getNodeByID(nodeIDForProject) if @hasID nodeIDForProject
    console.log "inserting project", nodeIDForProject

    newNode = new BenderNode project
    @insertNode newNode

    for depName, depVersion of project.mapOfDependencyVersions()
      dep = @benderContext.getProjectOrDependency depName, depVersion
      depNode = @_insertProjectHelper dep

      @createEdgeBetween newNode, depNode

    newNode

  renderToImage: (imagePath) ->
    graphviz = require('graphviz')
    graph = graphviz.digraph()

    for id, node of @nodesByID
      graphVizNode = graph.addNode node.id()

      for outgoingNode in node.outgoing
        graph.addEdge graphVizNode, outgoingNode.id()

    graph.output 'png', imagePath, ->
      console.log 'post graph output', arguments


module.exports = BenderDependencyGraph
