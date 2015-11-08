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
              lintlines = lintdata.split('\n')
              res = []

              processline = (line)->
                codeindex = line.indexOf(': ')
                if codeindex == -1
                  # This line does not make sense so skip it.
                  console.log('bad line:' + line)
                  return
                codeletter = line.charAt(codeindex + 2)
                if codeletter == 'E'
                  msgcode = 'Error'
                else if codeletter == 'W'
                  msgcode = 'Warning'
                else
                  msgcode = "Trace" # Gah we need a third type.
                firstcolon = line.indexOf(':')
                secondcolon = line.indexOf(':', firstcolon + 1)
                lineno = parseInt(line.substring(firstcolon + 1, secondcolon), 10) - 1
                msgrange = [[lineno, 0],[lineno, 1]]
                msgtext = line.substring(codeindex + 2)
                res.push {
                  type: msgcode,
                  text: msgtext,
                  range:msgrange,
                  filePath: filepath
                }

              processline line for line in lintlines

              resolve(res)
          )
        )
