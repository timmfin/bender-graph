Node = require('./node')
{ convertToSimpleVersionString }  = require('bender-broccoli-utils/static-version-utils')

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
      "#{project.name}-v#{convertToSimpleVersionString(project.version)}"


module.exports = BenderProjectNode
