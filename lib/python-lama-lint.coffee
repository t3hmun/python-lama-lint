module.exports = PythonLamaLint =

  activate: (state) ->
    # Output to the console, handy to know that the plugin is activating.
    console.log 'activated'
    @aliveCommand = atom.commands.add 'atom-workspace', 'python-lama-lint:alive': -> console.log('alive')

  deactivate: ->
    @aliveCommand.dispose()
