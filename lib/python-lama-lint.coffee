{BufferedProcess} = require 'atom'
path = require 'path'

# People seem to be using `module.exports` (`this`) as a place to put module
#  scope variables.
# That is horrific, exports is for things that you want to explicitly expose.
# Other people seem to be wrapping all thier code in an object so they can use
#  the object via `this` for thier wider scoped vars.
# I suppose using `this` (@) clearly indicates a wider scope is in use.
# However it lacks any consistency. Strict mode JS makes more sense.

# Module level vars make sense, this is node-based not browser-based.
aliveCommand = null

# Name for debug.
moduleName = 'python-lama-lint'

activate = (state) ->
  # Output to the console, handy to know that the plugin is activating.
  console.log 'activated: ' + moduleName
  aliveCommand = atom.commands.add 'atom-workspace', 'python-lama-lint:alive': -> console.log('alive')

deactivate = ->
  aliveCommand.dispose()
  console.log moduleName + ': disposed aliveCommand.'

processline = (line, results, filepath)->
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
  results.push {
    type: msgcode,
    text: msgtext,
    range:msgrange,
    filePath: filepath
  }

lintFile = (filePath) ->
  lintExecutor = (resolve, reject) ->
    ret = []
    filedir = path.dirname filePath
    lamapath = 'pylama'
    proc = new BufferedProcess(
      command: lamapath
      args: [filePath]
      options: {
        cwd: filedir
      }
      stdout: (data) ->
        ret.push(data)
      exit: (code) ->
        lintdata = ret.join('')
        lintlines = lintdata.split('\n')
        results = []
        processline line, results, filePath for line in lintlines
        resolve(results)
    )
  return new Promise (lintExecutor)

# Lint API function.
provideLinter = ->
  provider =
    # Short name saves screen space.
    name: 'P',
    grammarScopes: ['source.python'],
    scope: 'file',
    lintOnFly: false,
    lint: (textEditor) ->
      filePath = textEditor.getPath()
      console.log('Linting:' + filePath)
      lintFile filePath

# CoffeSctipt lacks function declarations so we can't enjoy function hoisting.
module.exports.activate = activate
module.exports.deactivate = deactivate
module.exports.provideLinter = provideLinter
