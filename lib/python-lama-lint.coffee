{BufferedProcess} = require 'atom'
path = require 'path'

# Name for debug.
moduleName = 'python-lama-lint'

# Package API function.
activate = (state) ->
  # Output to the console, handy to know that the plugin is activating.
  console.log 'activated: ' + moduleName

# Package API function.
deactivate = ->
  console.log 'deactivated: ' + moduleName

# Converts line of LamaLint output into Linter package message.
processline = (line, filepath)->
  codeindex = line.indexOf(': ')
  if codeindex == -1
    # This line does not make sense so skip it.
    console.log('bad line:' + line)
    return undefined
  codeletter = line.charAt(codeindex + 2)
  if codeletter == 'E'
    msgcode = 'Error'
  else if codeletter == 'W'
    msgcode = 'Warning'
  else
    msgcode = "Warning" # Gah we need a third type.
  firstcolon = line.indexOf(':')
  secondcolon = line.indexOf(':', firstcolon + 1)
  lineno = parseInt(line.substring(firstcolon + 1, secondcolon), 10) - 1
  msgrange = [[lineno, 0],[lineno, 1]]
  msgtext = line.substring(codeindex + 2)
  return lintEntry = {
    type: msgcode,
    text: msgtext,
    range:msgrange,
    filePath: filepath
  }

# Creates a promise to lint file.
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
        for line in lintlines
          res = processline line, filePath
          if typeof res isnt 'undefined' then results.push res
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
