ArduinoFirmata = require 'arduino-firmata'
_ = require 'lodash'

module.exports = (linda) ->

  config = linda.config
  ts = linda.tuplespace(config.linda.space)

  arduino = new ArduinoFirmata().connect(process.env.ARDUINO)

  linda.io.on 'connect', ->

    linda.debug "watching {type: 'door', where: '#{config.where}'} in tuplespace '#{ts.name}'"
    linda.debug "=> #{config.linda.url}/#{ts.name}?type=door&where=#{config.where}&cmd=open"

    ts.watch {type: 'door', where: config.where, cmd: 'open'}, (err, tuple) ->
      return if tuple.data.response?
      where = tuple.data.where
      if err
        linda.debug err
        return
      linda.debug tuple
      door_open_throttled ->
        res = tuple.data
        res.response = 'success'
        ts.write res

  arduino.once 'connect', ->
    linda.debug "connect!! #{arduino.serialport_name}"
    linda.debug "board version: #{arduino.boardVersion}"

  door_open = (onComplete = ->) ->
    arduino.servoWrite 9, 0
    setTimeout ->
      arduino.servoWrite 9, 180
      onComplete()
    , 2000

  door_open_throttled = _.throttle door_open, 5000, trailing: false
