{BufferedProcess} = require 'atom'
path = require 'path'

# Name for debug.
moduleName = 'python-lama-lint'
status = null
statusEle = null

# Package API function.
# Called when the package is being loaded, used to setup anything.
activate = (state) ->
  console.log 'activated: ' + moduleName # For debug.

# Package API function.
# Called when the package is deactivated, use for disposing.
deactivate = ->
  status?.destroy()
  status = null
  console.log 'deactivated: ' + moduleName # For debug.

# Converts line of LamaLint output into Linter package message.
processline = (line, filepath)->
  codeindex = line.indexOf(': ')
  if codeindex == -1
    # This line does not make sense so skip it.
    if line isnt '' then console.log('bad line:' + line)
    return undefined
  codeletter = line.charAt(codeindex + 2)
  if codeletter == 'E'
    msgcode = 'Error'
  else if codeletter == 'W'
    msgcode = 'Warning'
  else
    msgcode = "Info"
  firstcolon = line.indexOf(':')
  secondcolon = line.indexOf(':', firstcolon + 1)
  lineno = parseInt(line.substring(firstcolon + 1, secondcolon), 10) - 1
  msgrange = [[lineno, 0],[lineno, 1]]
  msgtext = line.substring(codeindex + 2)
  return lintEntry =
    type: msgcode,
    text: msgtext,
    range:msgrange,
    filePath: filepath

# Creates a promise to lint file.
lintFile = (filePath) ->
  # The executor function returns quickly, the resolve method is captured in
  #  in the ansyc buffered process exit function.
  lintExecutor = (resolve, reject) ->
    ret = []
    filedir = path.dirname filePath
    lamapath = 'pylama'
    proc = new BufferedProcess(
      command: lamapath
      args: [filePath]
      options:
        cwd: filedir
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

# Linter API function.
# Provides a the config and a function for performing the linting.
provideLinter = ->
  provider =
    # Short name saves screen space.
    name: 'P',
    grammarScopes: ['source.python'],
    scope: 'file',
    lintOnFly: false,
    lint: (textEditor) ->
      filePath = textEditor.getPath()
      console.log('Linting:' + filePath) # For debug.
      lintFile filePath

# Status bar API function
consumeStatusBar = (statusBar) ->
  statusEle = document.createElement('span')
  statusEle.textContent = 'E:? W:? I:?'
  status = statusBar.addLeftTile(item: statusEle, priority: 100)

# Rant:
# CoffeeScript lacks function declarations so we can't enjoy function hoisting.

# Export essential functions.
module.exports.activate = activate
module.exports.deactivate = deactivate
module.exports.provideLinter = provideLinter
module.exports.consumeStatusBar = consumeStatusBar
