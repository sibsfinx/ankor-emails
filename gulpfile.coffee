gulp = require("gulp")
$ = require('gulp-load-plugins')()
# non-gulp
pngcrush = require('imagemin-pngcrush')
send = require("./mailer")
addMediaQueries = require("./addMediaQueries")
runSequence  = require 'run-sequence'
args  = require('yargs').argv
#sass = require('gulp-sass')
#slim = require("gulp-slim")
sourcemaps = require('gulp-sourcemaps')
browserSync = require('browser-sync')
reload = browserSync.reload

# --------------------------------------------------------
# Path Configurations
# --------------------------------------------------------
options = {}

options.sass =
  errLogToConsole: true
  sourceComments: 'normal'
  outputStyle: 'compact'

paths =
  jade: "./jade/**/**/*.jade"
  jadeTemplates: "./jade/templates/*.jade"
  #slim: "./slim/**/**/*.slim"
  #slimTemplates: "./slim/templates/*.slim"
  html: "./*.html"
  stylus: "styles/**/*.styl"
  stylusIndex: ["./styles/styles.styl", "./styles/_fonts.styl"]
  #sass: 'styles/**/*.sass'
  #sassIndex: "./styles/styles.sass"
  css: "styles/css/"
  images: "images/*"
  build: "./build"


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

gulp.task "sass", ->
  gulp.src paths.sassIndex
    .pipe handleError()
    .pipe $.sass options.sass
    .pipe $.autoprefixer()
    .pipe $.combineMediaQueries()
    .pipe gulp.dest path.cs
    .pipe $.livereload()
  return


#--------------------------------------------------------
# Compile Jade
#--------------------------------------------------------
gulp.task "jade", ->
  gulp.src paths.jadeTemplates
    .pipe $.jade(pretty:true)
    .pipe gulp.dest './'
    .pipe $.livereload()
    .pipe reload({stream: true})

gulp.task 'slim', ->
  gulp.src paths.slimTemplates
    .pipe handleError()
    .pipe slim pretty: true
    .pipe gulp.dest './'
    .pipe $.connect.reload()

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

  gulp.watch paths.stylus, ["stylus"]
  gulp.watch paths.jade, ["jade"]
  #gulp.watch paths.sass, ["sass"]
  #gulp.watch paths.slim, ["slim"]

  gulp.watch [
    paths.html
    paths.css
  ], ["reload", "browser-sync-reload", "build"]

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

