{BufferedProcess} = require 'atom'
path = require 'path'
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
      lint: (textEditor) ->
        console.log('Linting.' + textEditor.getPath())
        new Promise ((resolve, reject) ->
          filepath = textEditor.getPath()
          ret = []
          filedir = path.dirname textEditor.getPath()
          lamapath = 'pylama'
          proc = new BufferedProcess(
            command: lamapath
            args: [filepath]
            options: {
              cwd: filedir
            }
            stdout: (data) ->
              ret.push(data)
            exit: (code) ->
              lintdata = ret.join('')
              # Spam to log for now, we'll write processing code after
              console.log(lintdata + 'With code: ' + code)
              resolve([{
                type: 'Error',
                text: 'Good afternoon.',
                range:[[0,0], [0,1]],
                filePath: textEditor.getPath()
              }])
          )
        )
