const gulp = require('gulp')
const del = require('del')
const ts = require('gulp-typescript')
const elm = require('gulp-elm')
const sass = require('gulp-sass')
const series = require('run-sequence')

const tsProject = ts.createProject('tsconfig.json')
const paths = {
  del: {
    folders: [ 'dist' ]
  },
  assets: {
    src: 'web/assets/**/*',
    dest: 'dist/public',
  },
  pug: {
    src: 'web/**/*.pug',
    dest: 'dist'
  },
  elm: {
    src: 'web/elm/**/*.elm',
    out: 'bundle.js',
    dest: 'dist/public'
  },
  sass: {
    src: 'web/styles/**/*.scss',
    dest: 'dist/public'
  },
  typescript: {
    src: 'web/**/*.ts',
    dest: 'dist'
  }
}

// ASSETS
gulp.task('assets', () =>
  gulp.src(paths.assets.src)
    .pipe(gulp.dest(paths.assets.dest))
)

gulp.task('assets:watch', ['assets'], () =>
  gulp.watch(paths.assets.src, ['assets'])
)

// PUG
gulp.task('pug', () =>
  gulp.src(paths.pug.src)
    .pipe(gulp.dest(paths.pug.dest))
)

gulp.task('pug:watch', ['pug'], () =>
  gulp.watch(paths.pug.src, ['pug'])
)

// ELM
gulp.task('elm:init', elm.init)

gulp.task('elm', ['elm:init'], () =>
  gulp.src(paths.elm.src)
    .pipe(elm.bundle(paths.elm.out, {
      debug: process.env.NODE_ENV !== 'production'
    }))
    .on('error', () => {})
    .pipe(gulp.dest(paths.elm.dest))
)

gulp.task('elm:watch', ['elm'], () =>
  gulp.watch(paths.elm.src, ['elm'])
)

// SASS
gulp.task('sass', () =>
  gulp.src(paths.sass.src)
    .pipe(sass().on('error', sass.logError))
    .pipe(gulp.dest(paths.sass.dest))
)

gulp.task('sass:watch', ['sass'], () =>
  gulp.watch(paths.sass.src, ['sass'])
)

// TYPESCRIPT
gulp.task('typescript', () => gulp
  .src(paths.typescript.src)
  .pipe(tsProject())
  .js
  .pipe(gulp.dest(paths.typescript.dest))
)

gulp.task('typescript:watch', ['typescript'], () => {
  gulp.watch(paths.typescript.src, ['typescript'])
})

// DEFAULT COMMANDS
gulp.task('clean', () => del(paths.del.folders))
gulp.task('build', ['elm', 'assets', 'pug', 'sass', 'typescript'])
gulp.task('watch', ['elm:watch', 'assets:watch', 'pug:watch', 'sass:watch', 'typescript:watch'])

gulp.task('dev', (done) => series('clean', 'watch', done))
gulp.task('default', (done) => series('clean', 'build', done))