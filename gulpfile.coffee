gulp = require("gulp")
$ = require('gulp-load-plugins')()
# non-gulp
pngcrush = require('imagemin-pngcrush')
send = require("./mailer")
addMediaQueries = require("./addMediaQueries")
runSequence  = require 'run-sequence'
args  = require('yargs').argv
#sourcemaps = require('gulp-sourcemaps')
browserSync = require('browser-sync')
reload = browserSync.reload
parallelize = require('concurrent-transform')


# --------------------------------------------------------
# Path Configurations
# --------------------------------------------------------
options = {}

options =
  parallelize:
    threads: 10

paths =
  jade: "./jade/**/**/*.jade"
  jadeTemplates: "./jade/templates/*.jade"
  html: "./*.html"
  stylus: "styles/**/*.styl"
  stylusIndex: ["./styles/styles.styl", "./styles/_fonts.styl"]
  css: "styles/css/"
  images: "images/*"
  build: "./build"
  dist: "./dist"

# Direct errors to notification center
handleError = ->
   $.plumber errorHandler: $.notify.onError ->
      $.util.beep()
      "Error: <%= error.message %>"

#--------------------------------------------------------
# BUILD Tasks
#--------------------------------------------------------


gulp.task "inline", ->
  gulp.src(paths.html)
    .pipe($.inlineCss(preserveMediaQueries: true))
    .pipe gulp.dest(paths.build)



gulp.task "plaintext", ->
  gulp.src(paths.html)
    .pipe($.html2txt())
    .pipe gulp.dest(paths.build + "/plaintext")
  return


gulp.task 'browser-sync', ->
  browserSync proxy: 'localhost:8080'
  return


#--------------------------------------------------------
# Compile Stylus
#--------------------------------------------------------
gulp.task "stylus", ->
  gulp.src paths.stylusIndex
    .pipe handleError()
    .pipe $.stylus()
    .pipe $.autoprefixer()
    .pipe $.combineMediaQueries()
    .pipe gulp.dest paths.css
    .pipe $.livereload()
    .pipe reload({stream: true})

gulp.task "stylus:build", ->
  gulp.src paths.stylusIndex
    .pipe $.stylus()
    .pipe $.autoprefixer()
    .pipe $.combineMediaQueries()
    .pipe gulp.dest paths.css


gulp.task 'sourcemaps-inline', ->
  gulp.src paths.stylusIndex
    .pipe $.sourcemaps.init()
    .pipe $.stylus()
    .pipe $.sourcemaps.write()
    .pipe gulp.dest paths.css

gulp.task 'sourcemaps-external', ->
  gulp.src paths.stylusIndex
    .pipe $.sourcemaps.init()
    .pipe $.stylus()
    .pipe $.sourcemaps.write('.')
    .pipe gulp.dest paths.css

#--------------------------------------------------------
# Compile Jade
#--------------------------------------------------------
gulp.task "jade", ->
  gulp.src paths.jadeTemplates
    .pipe $.jade(pretty:true)
    .pipe handleError()
    .pipe gulp.dest './'
    .pipe $.livereload()
    .pipe reload({stream: true})

gulp.task "jade:build", ->
  gulp.src paths.jadeTemplates
    .pipe $.jade(pretty:true)
    .pipe gulp.dest './'

gulp.task "clean:dist", ->
  gulp.src paths.dist
    .pipe $.clean()

gulp.task "html2hbs", ["clean:dist"], ->
  gulp.src "#{paths.build}/*.html"
    .pipe $.rename
      extname: ".hbs"
    .pipe gulp.dest paths.dist

# --------------------------------------------------------
# Connect to server
# --------------------------------------------------------
gulp.task "connect", ->
  $.connect.server
    root: __dirname

#--------------------------------------------------------
# Watch for changes and reload page
#--------------------------------------------------------
gulp.task "reload", ->
  gulp.src(paths.html).pipe $.livereload()
  return

gulp.task "browser-sync-reload", ->
  gulp.src(paths.html).pipe reload({stream: true})
  return


gulp.task "watch", ->
  server = $.livereload()
  $.livereload.listen()

  gulp.watch paths.stylus, ["stylus", "sourcemaps-external"]
  gulp.watch paths.jade, ["jade"]

  gulp.watch [
    paths.html
    paths.css
  ], ["reload", "browser-sync-reload", "build", "sourcemaps-external"]

  return




gulp.task "clean", require("del").bind(null, [paths.build])

# --------------------------------------------------------
# BUILD
# --------------------------------------------------------

gulp.task "build", ->

  runSequence [
    "inline"
    "addMediaQueries"
  ]

gulp.task "dist", ->
  runSequence [
    "build"
    "html2hbs"
  ]

# --------------------------------------------------------
# SEND EMAIL (configure in ./mailer.coffee)
# --------------------------------------------------------

# Files to email
files = [
  "index.html"
]

filename = args.file
gulp.task "send", ->
  send(filename)

gulp.task "sendAll", ->
  i = 0
  while i < files.length
    file = files[i].split(".")
    send(file[0])
    i++


# --------------------------------------------------------
# Add Media Queries to Head (configure in ./addMediaQueries.coffee)
# --------------------------------------------------------
gulp.task "addMediaQueries", ->
  addMediaQueries(files)


# --------------------------------------------------------
# Connect to server
# --------------------------------------------------------

gulp.task "default", [
  "connect"
  "watch"
  "browser-sync"
]

