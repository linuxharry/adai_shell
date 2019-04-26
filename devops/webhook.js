var http = require('http')
var createHandler = require('node-github-webhook')
//var createHandler = require('github-webhook-handler')
var handler = createHandler([ // 多个仓库
  {
    path: '/devops_docs',
    secret: 'adai_devops'
  },
  {
    path: '/life_docs',
    secret: 'adai_life'
  },
  {
    path: '/other_docs',
    secret: 'adai_other'
  }
])
// var handler = createHandler({ path: '/webhook1', secret: 'secret1' }) // 单个仓库

http.createServer(function (req, res) {
  handler(req, res, function (err) {
    res.statusCode = 404
    res.end('no such location')
  })
}).listen(10080)

handler.on('error', function (err) {
  console.error('Error:', err.message)
})

handler.on('push', function (event) {
  console.log(
    'Received a push event for %s to %s',
    event.payload.repository.name,
    event.payload.ref
  )
  switch (event.path) {
    case '/devops_docs':
      runCmd('sh', ['./devops_docs_deploy.sh', event.payload.repository.name], function (text) { console.log(text) })
      break
    case '/life_docs':
      runCmd('sh', ['./life_docs_deploy.sh', event.payload.repository.name], function (text) { console.log(text) })
      break
    case '/other_docs':
      runCmd('sh', ['./other_docs_deploy.sh', event.payload.repository.name], function (text) { console.log(text) })
      break
    default:
      // 处理其他
      break
  }
})

function runCmd (cmd, args, callback) {
  var spawn = require('child_process').spawn
  var child = spawn(cmd, args)
  var resp = ''
  child.stdout.on('data', function (buffer) {
    resp += buffer.toString()
  })
  child.stdout.on('end', function () {
    callback(resp)
  })
}
