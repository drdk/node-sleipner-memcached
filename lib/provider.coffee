Memcached = require("mc").Client
Pool      = require("generic-pool").Pool

module.exports = exports = class
  constructor: (hosts...) ->
    hosts ||= ["127.0.0.1"]

    for host, i in hosts
      host = "#{host}:11211" unless host.indexOf(":") isnt -1
      hosts[i] = host

    @pool = Pool
      name: "memcached"
      max:  100
      idleTimeoutMillis: 600000
      log: no

      create: (cb) ->
        client = new Memcached(hosts)
        client.connect (error) ->
          cb(error, client)

      destroy: (client) ->
        client.disconnect()

  get: (key, cb) ->
    pool = @pool
    pool.acquire (error, client) ->
      if error or not client
        console.error "!! Memcached provider: Failed to acquire client during GET (#{error})"
      else
        client.get key, (error, data) ->
          pool.release(client)
          cb(error, data[key] if not error)

  set: (key, value, expires = 0) ->
    expires = expires - Date.now() if expires isnt 0
    pool = @pool
    pool.acquire (error, client) ->
      if error
        console.error "!! Memcached provider: Failed to acquire client during SET (#{error})"
      else
        client.set key, value, flags: 0, exptime: expires, (error, status) ->
          pool.release(client)
          console.error "!! Memcached provider SET failed: #{error.toString()}" if error