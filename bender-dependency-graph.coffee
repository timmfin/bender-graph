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

    newNode = new BenderNode { project }
    @insertNode newNode

    for depName, depVersion of project.mapOfDependencyVersions()

      # If the parent is a served project, look to see if dep is served.
      # Otherwise, only look in the dependency archive (deps of deps are not
      # retroactively modified to point to locally served projects)
      if project.isProject()
        dep = @benderContext.getProjectOrDependency depName, depVersion
      else
        dep = @benderContext.getDependency depName, depVersion

      depNode = @_insertProjectHelper dep

      @createEdgeBetween newNode, depNode

    newNode

  nodeForProject: (project) ->
    nodeIDForProject = BenderNode.idForProject project
    @getNodeByID(nodeIDForProject)

  nodesForProjects: (projects) ->
    projects.map (p) =>
      @nodeForProject p

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
