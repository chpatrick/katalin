# Declare app level module which depends on filters, and services
angular.module("cate",
  [ "ngRoute",
    "cate.filters",
    "cate.services",
    "cate.directives",
    "cate.controllers"
  ])
  .config [ "$routeProvider", ($routeProvider) ->
    $routeProvider.when "/:year/:clazz/timeline",
      templateUrl: "partials/timeline.html"
      controller: "timelineController"

    $routeProvider.when "/:year/:clazz/courses",
      templateUrl: "partials/courses.html"
      controller: "coursesController"

    $routeProvider.otherwise redirectTo: "/"
  ]