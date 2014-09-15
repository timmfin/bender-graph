class Node
  constructor: (@data, options = {}) ->
    @data ?= {}
    @incoming = options.incoming ? []
    @outgoing = options.outgoing ? []

  id: ->
    @data.id

  isLeaf: ->
    @outgoing.length is 0

  isRoot: ->
    @incoming.length is 0

  hasOutgoingEdgeTo: (idToCheck) ->
    for outgoingNode in @outgoing
      return true if outgoingNode.id() is idToCheck

    false

  hasIncomingEdgeTo: (idToCheck) ->
    for incomingNode in @incoming
      return true if incomingNode.id() is idToCheck

    false

  hasEdge: (direction, idToCheck) ->
    if direction is 'incoming'
      @hasIncomingEdgeTo idToCheck
    else if direction is 'outgoing'
      @hasOutgoingEdgeTo idToCheck


module.exports = Node
