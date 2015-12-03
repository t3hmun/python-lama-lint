{BufferedProcess} = require 'atom'
path = require 'path'

# Name for debug.
moduleName = 'python-lama-lint'
status = {}

# Package API function.
# Called when the package is being loaded, used to setup anything.
activate = (state) ->
  console.log 'activated: ' + moduleName # For debug.

# Package API function.
# Called when the package is deactivated, use for disposing.
deactivate = ->
  status.bar?.destroy()
  status.bar = null
  console.log 'deactivated: ' + moduleName # For debug.

# Updates the status bar element
updateStatus = (errors, warnings, infos) ->
  status.errors.textContent = 'E: ' + errors
  status.warnings.textContent = ' W: ' + warnings
  status.infos.textContent = ' I: ' + infos
  # Text and the numbers above 0 are both give colour.
  # These are basic atom styles from the styleguide.
  status.errors.className = if errors then 'text-error' else 'text-subtle'
  status.warnings.className = if warnings then 'text-warning' else 'text-subtle'
  status.infos.className = if infos then 'text-info' else 'text-subtle'

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
        infos = 0
        warnings = 0
        errors = 0
        for line in lintlines
          res = processline line, filePath
          if typeof res isnt 'undefined'
            results.push res
            switch res.type
              when 'Error' then errors++
              when 'Warning' then warnings++
              when 'Info' then infos++
        updateStatus(errors, warnings, infos)
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
  status.ele = document.createElement('span')
  status.errors = document.createElement('span')
  status.warnings = document.createElement('span')
  status.infos = document.createElement('span')
  status.ele.appendChild status.errors
  status.ele.appendChild status.warnings
  status.ele.appendChild status.infos
  updateStatus '?', '?', '?'
  status.bar = statusBar.addLeftTile(item: status.ele, priority: 100)

# Rant:
# CoffeeScript lacks function declarations so we can't enjoy function hoisting.

# Export essential functions.
module.exports.activate = activate
module.exports.deactivate = deactivate
module.exports.provideLinter = provideLinter
module.exports.consumeStatusBar = consumeStatusBar
