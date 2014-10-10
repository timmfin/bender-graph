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

  depthFirstSearch: (startingNodes, onNodeVisit, depth = 0, nodesVisited = {}) ->
    startingNodes = [startingNodes] unless Array.isArray startingNodes

    for startingNode in startingNodes
      @_depthFirstSearchHelper startingNode, onNodeVisit, 0, nodesVisited

  _depthFirstSearchHelper: (currentNode, onNodeVisit, depth, nodesVisited) ->
    currentID = currentNode.id()

    if not nodesVisited[currentID]
      nodesVisited[currentID] = true

      # Visit rest of graph unless the callback returned false
      if onNodeVisit(currentNode, depth) isnt false
        for outgoingNode in currentNode.outgoing
          @_depthFirstSearchHelper(outgoingNode, onNodeVisit, depth + 1, nodesVisited)

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
