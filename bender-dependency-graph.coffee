treeify    = require('treeify')

Graph      = require('./graph')
BenderNode = require('./bender-project-node')


class BenderDependencyGraph extends Graph
  constructor: (@benderContext) ->
    super()

  insertProject: (project, options) ->
    @_insertProjectHelper project, options

  # First, insert the project and all of its dependencies into the graph as disconnected
  # nodes. Then go back and add all the edges after we know all nodes are created.
  _insertProjectHelper: (project, options = {}) ->
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

      if dep.isDependency() and options.skipDependencies
        # console.log "Skipping adding deps to the graph for", project.prettyName()
      else
        depNode = @_insertProjectHelper dep, options

        @createEdgeBetween newNode, depNode

    newNode

  nodeForProject: (project) ->
    nodeIDForProject = BenderNode.idForProject project
    @getNodeByID(nodeIDForProject)

  nodesForProjects: (projects) ->
    projects.map (p) =>
      @nodeForProject p

  renderToAsciiTree: (startingNodes) ->
    treeObject = {}
    stack = [treeObject]

    @depthFirstSearch startingNodes, (currentNode, depth) ->
      endOfStack = stack[stack.length - 1]

      if currentNode.isLeaf()
        endOfStack[currentNode.project.prettyName()] = ""
      else
        endOfStack[currentNode.project.prettyName()] = {}
        stack.push endOfStack[currentNode.project.prettyName()]

    , (currentNode, depth) ->
      stack.pop() unless stack.length is 1

    treeify.asTree(treeObject)

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
