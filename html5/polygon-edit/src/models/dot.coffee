'use strict'
root = exports ? this

EventEmitter2 = require('eventemitter2').EventEmitter2
EventEmitter2 ?= @EventEmitter2

class Dot extends EventEmitter2
  @id = 1

  constructor: (@x, @y) ->
    @id = Dot.id++
    @isSelected = false

  del: ->
    @emit('exit', this)


root.Dot = Dot
