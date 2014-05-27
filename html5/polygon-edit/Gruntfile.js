module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    watch: {
      src: {
        files: [
          'src/**/*.js', 'src/**/*.coffee',
          'test/*.coffee', 'Gruntfile.js'
        ],
        tasks: ['build']
      }
    },

    jshint: {
      all: ['Gruntfile.js'],
      options: {
        laxcomma: true,
        node: true,
        predef: ['describe', 'it']
      }
    },

    coffeelint: {
      all: ['src/**/*.coffee', 'test/test.*.coffee']
    },

    coffee: {
      src: {
        options: {
          sourceMap: true
        },
        expand: true,
        flatten: true,
        cwd: 'src',
        src: '*.coffee',
        dest: 'src',
        ext: '.js'
      },
      models: {
        options: {
          sourceMap: true
        },
        expand: true,
        flatten: true,
        cwd: 'src/models',
        src: '*.coffee',
        dest: 'src/models',
        ext: '.js'
      },
      controllers: {
        options: {
          sourceMap: true
        },
        expand: true,
        flatten: true,
        cwd: 'src/controllers',
        src: '*.coffee',
        dest: 'src/controllers',
        ext: '.js'
      }
    },


    mochaTest: {
      test: {
        options: {
          reporter: 'spec'
        },
        src: ['test/test.*.coffee']
      }
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
          'node_modules/underscore/underscore.js',
          'src/*.js', 'src/models/*.js', 'src/controllers/*.js'
        ],
        dest: 'dist/<%= pkg.name %>.js'
      }
    },

    livereloadx: {
      static: true,
      dir: 'dist/'
    }
  });

  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-coffeelint');
  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('livereloadx');

  grunt.registerTask('default', ['livereloadx', 'watch']);
  grunt.registerTask('build', [
    'coffeelint', 'coffee', 'jshint', 'test', 'concat'
  ]);
  grunt.registerTask('test', ['mochaTest']);
};
