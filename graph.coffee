class Graph
  constructor: () ->
    @nodesByID = {}

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
    console.log "  Creating edge from #{fromNode.id()} -> #{toNode.id()}"
    if not fromNode.hasEdge 'outgoing', toNode.id()
      fromNode['outgoing'].push toNode

    if not toNode.hasEdge 'incoming', fromNode.id()
      toNode['incoming'].push fromNode


  # Traversal

  depthFirstSearch: (currentNode, onNodeVisit, depth = 0, nodesVisited = {}) ->
    currentID = currentNode.id()
    throw new Error "Cycle in graph, already visited: #{currentID}" if nodesVisited[currentID]
    nodesVisited[currentID] = true

    # Break early if visit callback returns false
    return if onNodeVisit(currentNode, depth) is false

    # Visit rest of graph
    for outgoingNode in currentNode.outgoing
      @depthFirstSearch(outgoingNode, onNodeVisit, depth + 1, nodesVisited)

  # Alias depthFirstSearch as traverse
  @::depthFirstSearch = @::traverse

  collectAllLeavesStartingFrom: (startingNode, onNodeVisit) ->
    leaves = []
    onNodeVisit ?= ->

    @depthFirstSearch startingNode, (currentNode, depth) ->
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
