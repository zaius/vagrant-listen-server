var net = require('net');


// Assuming the existence of some `build` method that returns a promise.
var sequence = build();


// gathers rapid changes as one build
var timeout = null;
var scheduleBuild = function() {
  if (timeout) { return; }

  // we want the timeout to start now before we wait for the current build
  var timeoutPromise = new Promise(function(resolve) {
    timeout = setTimeout(resolve, 100);
  });

  var timeoutThenBuild = function() {
    timeoutPromise.then(function() {
      timeout = null
      return build();
    });
  };

  // we want the current promise to be waiting for the current build
  // regardless if it fails or not.
  sequence = sequence.then(timeoutThenBuild, timeoutThenBuild);
};


var port = 4000;
var host = '172.16.172.1';
var client = new net.Socket();

client.connect(port, host, function() {
  console.log('Connected to listen server: ', host, port);
});

client.on('data', function(data) {
  // Can't find any doc on the message format, but it looks like the first
  // 4 bytes are always the header, which includes the message length, and
  // the result is always a json array.
  //  * https://github.com/guard/listen/blob/master/lib/listen/tcp/message.rb
  var header = data.slice(0, 4);
  var message = JSON.parse(data.slice(4).toString());
  // message is [type, operation, dir, file, unknown]
  console.log('Change detected in:', message[3])
  scheduleBuild();
});

client.on('close', function() {
  console.log('Connection closed');
});
