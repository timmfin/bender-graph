class Graph
  constructor: () ->
    @nodesByID = {}

  size: ->
    Object.keys(@nodesByID).length

  hasID: (id) ->
    @nodesByID[id]?

  getNodeByID: (id) ->
    @_ensureNodeExists(id)
    @nodesByID[id]

  insertNodes: (nodes...) ->
    for node in nodes
      @_insertNodeHelper node

  # Alias insertNodes as insertNode
  @::insertNode = @::insertNodes

  createEdgeBetween: (fromNode, toNode) ->
    if not fromNode.hasEdge 'outgoing', toNode.id()
      fromNode['outgoing'].push toNode

    if not toNode.hasEdge 'incoming', fromNode.id()
      toNode['incoming'].push fromNode


  # Traversal

  depthFirstSearch: (startingNodes, onNodeVisit, edgeTypeToFollow = 'outgoing', depth = 0, nodesVisited = {}) ->
    startingNodes = [startingNodes] unless Array.isArray startingNodes

    for startingNode in startingNodes
      @_depthFirstSearchHelper startingNode, onNodeVisit, edgeTypeToFollow, 0, nodesVisited

  ancestorDepthFirstSearch: (startingNodes, onNodeVisit) ->
    @depthFirstSearch(startingNodes, onNodeVisit, 'incoming')

  _depthFirstSearchHelper: (currentNode, onNodeVisit, edgeTypeToFollow, depth, nodesVisited) ->
    currentID = currentNode.id()

    if not nodesVisited[currentID]
      nodesVisited[currentID] = true

      # Visit rest of graph unless the callback returned false
      if onNodeVisit(currentNode, depth) isnt false
        for otherNode in currentNode[edgeTypeToFollow]
          @_depthFirstSearchHelper(otherNode, onNodeVisit, edgeTypeToFollow, depth + 1, nodesVisited)


  # Alias depthFirstSearch as traverseFrom
  @::traverseFrom = @::depthFirstSearch

  collectAllLeavesStartingFrom: (startingNodes, onNodeVisit) ->
    leaves = []
    onNodeVisit ?= ->

    startingNodes = [startingNodes] unless Array.isArray startingNodes

    @depthFirstSearch startingNodes, (currentNode, depth) ->
      leaves.push(currentNode) if currentNode.isLeaf()
      return onNodeVisit(currentNode, depth)

    leaves

  collectAllRootsStartingFrom: (startingNodes, onNodeVisit) ->
    leaves = []
    onNodeVisit ?= ->

    startingNodes = [startingNodes] unless Array.isArray startingNodes

    @depthFirstSearch startingNodes, (currentNode, depth) ->
      leaves.push(currentNode) if currentNode.isRoot()
      return onNodeVisit(currentNode, depth)
    , 'incoming'

    leaves

  # Walks the dependency tree backwards, starting from all the leaves, creating a
  # array that is ordered where all dependencies show up before their parents.
  #
  # This ordering allows us to incrementally build every dep/project separately
  # while still ensuring that we build all of a projects's deps before trying to
  # build the project itself.

  # QUESTION, still need this if we only need the served projects in reverse dep order???

  allNodesInReverseDependencyOrder: (startingNodes, onNodeVisit) ->
    alreadyInResults = {}
    results = []
    stack = {}

    # Grab all the leaves and use them as the initial places to start traversing
    for leaf in @collectAllLeavesStartingFrom startingNodes, onNodeVisit
      stack[leaf.id()] = leaf

    # While there are still nodes to process...
    while Object.keys(stack).length > 0
      itemsRemovedInThisPass = 0

      # Do a pass on our current set of nodes. If we've already encountered all of its
      # outgoing edges (or it has none), then:
      #
      #  - Add it to the results
      #  - Remove it from the current set
      #  - Add all of its incoming nodes to the current set
      for nodeToCheckID, nodeToCheck of stack

        # All of the outgoing edges that point to nodes not already pushed to
        # the results array
        outgoingNodesStillAround = nodeToCheck.outgoing.filter (dest) ->
          not alreadyInResults[dest.id()]?

        if outgoingNodesStillAround.length is 0
          itemsRemovedInThisPass++
          delete stack[nodeToCheckID]
          alreadyInResults[nodeToCheckID] = true
          results.push nodeToCheck

          # Add incoming nodes to the current set
          for incomingNode in nodeToCheck.incoming
            if not stack[incomingNode.id()]
              stack[incomingNode.id()] = incomingNode

      if itemsRemovedInThisPass is 0
        throw new Error "Graph traversal error when building reverse dependecies array (was there a cycle or disconnected node(s)?)"

    results


  # Helpers

  _ensureNodeExists: (id) ->
    throw new Error "No such node in graph with id: #{id}" unless @nodesByID[id]?

  _insertNodeHelper: (node, failIfAlreadyExists = true) ->
    if @nodesByID[node.id()] and failIfAlreadyExists is true
      throw new Error "Node already exists in the graph: #{node.id()}"

    @nodesByID[node.id()] = node

    actualIncomingNodes = []
    actualOutgoingNodes = []

    for incomingNodeOrString in node.incoming
      incomingNode = @_convertToNodeFromStringIfNeeded incomingNodeOrString
      actualIncomingNodes.push incomingNode

      @createEdgeBetween node, incomingNode
      @_insertNodeHelper incomingNode, false

    for outgoingNodeOrString in node.outgoing
      outgoingNode = @_convertToNodeFromStringIfNeeded outgoingNodeOrString
      actualOutgoingNodes.push outgoingNode

      @createEdgeBetween node, outgoingNode
      @_insertNodeHelper outgoingNode, false

    node.incoming = actualIncomingNodes
    node.outgoing = actualOutgoingNodes

  _convertToNodeFromStringIfNeeded: (nodeOrString) ->
    if typeof nodeOrString is 'string'
      @getNodeByID nodeOrString
    else
      nodeOrString


module.exports = Graph
