var net = require('net');

// Assuming the existence of some `build` method that returns a promise.
var sequence = build();

var port = 4000;
var host = '172.16.172.1';
var client = new net.Socket();
var interval = null;

client.connect(port, host, function() {
  console.log('Connected to listen server: ', host, port);

  interval = setInterval(function() {
    message = JSON.stringify({type: 'ping', message: 'listen-watcher'});
    client.write(message + '\n');
  , 1000);
});

client.on('data', function(data) {
  // message is [modified, added, removed]
  console.log('Data received', data)
  var message = JSON.parse(data.toString().trim())

  if (message.type === 'pong') { return; }
  if (message.type !== 'listen') { throw Error('Unknown message type'); }

  // We want the current promise to be waiting for the current build
  // regardless if it fails or not.
  sequence = sequence.then(build, build);
});

client.on('close', function() {
  console.log('Connection closed');
  interval && clearInterval(interval);
});
