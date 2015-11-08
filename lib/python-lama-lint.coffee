module.exports = PythonLamaLint =

  activate: (state) ->
    # Output to the console, handy to know that the plugin is activating.
    console.log 'activated'
    @aliveCommand = atom.commands.add 'atom-workspace', 'python-lama-lint:alive': -> console.log('alive')

  deactivate: ->
    @aliveCommand.dispose()

  provideLinter: ->
    provider =
      name: 'pll',
      grammarScopes: ['source.python'],
      scope: 'file',
      lintOnFly: false,
      lint: (textEditor) =>
        console.log('Linting.' + textEditor.getPath())
        return  [{
            type: 'Error',
            text: 'Good morning.',
            range:[[0,0], [0,1]],
            filePath: textEditor.getPath()
          }]
