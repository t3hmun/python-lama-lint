{CompositeDisposable} = require 'atom'
module.exports = PythonLamaLint =

  activate: (state) ->
    # Output to the console, handy to know that the plugin is activating.
    console.log 'activated'
    # CompositeDisposable is atom's event subscription API.
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'python-lama-lint:alive': => @alive()

  alive: ->
    console.log 'is alive'
