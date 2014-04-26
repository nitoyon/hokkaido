module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    watch: {
      src: {
        files: ['src/*.js', 'Gruntfile.js'],
        tasks: ['jshint', 'concat']
      }
    },

    jshint: {
      all: ['Gruntfile.js', 'src/*.js']
    },

    concat: {
      options: {
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
      },
      dist: {
        options: {
          process: function(src, file) {
            return '// Source: ' + file + '\n' +
              src.replace(/(^|\n).*require\(.*/g, '');
          }
        },
        src: [
          'node_modules/eventemitter2/lib/eventemitter2.js',
          'src/main.js', 'src/mode.js', 'src/model.js', 'src/view.js'
        ],
        dest: 'dist/<%= pkg.name %>.js'
      }
    },

    livereloadx: {
      static: true,
      dir: 'dist/'
    }
  });

  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('livereloadx');

  grunt.registerTask('default', ['livereloadx', 'build', 'watch']);
  grunt.registerTask('build', ['jshint', 'concat']);
};
