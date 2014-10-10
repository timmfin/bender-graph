Node = require('./node')


class BenderProjectNode extends Node
  constructor: (args...) ->
    super args...
    @project = @data.project

  id: ->
    @constructor.idForProject @project

  @idForProject: (project) ->
    if project.version is 'static'
      "#{project.name}-local"
    else
      "#{project.name}-v#{project.version.replace('static-', '')}"


module.exports = BenderProjectNode
