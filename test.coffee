require('coffee-script/register')

BenderGraph = require('./bender-dependency-graph')

# Oh yeah, hardcoding fun! (for now)
infoFilepath = '/Users/timmfin/dev/src/hubspot_static_daemon/app/assets/global/current_hs_static_info.json'
benderContext = require('/Users/timmfin/dev/src/ExampleStaticApp/broccoli/bender-context.coffee').initFromFile infoFilepath

graph = new BenderGraph benderContext

for projectName, project of benderContext.servedProjectsByName()
  graph.insertProject project

# console.log "graph", graph

graph.renderToImage "bender-graph.png"
