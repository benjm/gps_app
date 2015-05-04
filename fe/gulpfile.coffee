#!/usr/bin/env coffee
gulp = require 'gulp'
jade = require 'gulp-jade'
copy = require 'gulp-copy'
styl = require 'gulp-stylus'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
runSequence = require 'run-sequence'
del = require 'del'

jadeopts = {}
coffeeopts = {}
stylopts = {}

coffeesrc =
  'bustracker.js': [
    'src/main/coffee/channels.coffee'
    'src/main/coffee/bustracker.coffee'
  ]
  'backdoor.js': [
    'src/main/coffee/channels.coffee'
    'src/main/coffee/backdoor.coffee'
  ]

gulp.task 'clean-js', (cb) ->
  del ['../public/**/*.js'], force: true, cb

gulp.task 'clean-css', (cb) ->
  del ['../public/**/*.css'], force: true, cb

gulp.task 'clean-html', (cb) ->
  del ['../public/**/*.html'], force: true, cb

gulp.task 'jade', ->
  gulp.src 'src/main/jade/**/*.jade'
    .pipe jade jadeopts
    .pipe gulp.dest '../public/html'

buildCoffee = ->
  for k, v of coffeesrc
    gulp.src v
      .pipe coffee coffeeopts
      .pipe concat k
      .pipe gulp.dest '../public/js'


gulp.task 'styl', ->
  gulp.src 'src/main/styl/**/*.styl'
    .pipe styl stylopts
    .pipe gulp.dest '../public/css'

gulp.task 'copy', ->
  gulp.src 'src/main/resources/**/*.png'
    .pipe copy '../public/png'

gulp.task 'watch', ->
  gulp.watch 'src/main/coffee/**/*.coffee', ['coffee']
  gulp.watch 'src/main/jade/**/*.jade', ['jade']
  gulp.watch 'src/main/styl/**/*.styl', ['styl']
  gulp.watch 'src/main/resources/**/*.png', ['copy']
  
gulp.task 'coffee', buildCoffee

gulp.task 'build', ['jade', 'styl', 'coffee', 'copy']
gulp.task 'clean', ['clean-html', 'clean-css', 'clean-js']
gulp.task 'cleanbuild', -> runSequence 'clean', 'build'
gulp.task 'default', ['cleanbuild', 'watch']
