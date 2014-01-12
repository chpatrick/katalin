HeaderController = (cateService, $scope, $location, $routeParams) ->
    cateService.getAvailableClasses().then (classes) ->
      $scope.availableClasses = classes
    $scope.$on '$routeChangeSuccess', ->
      if $location.path() is '/'
        $scope.mode = 'timeline'
        # get the current year/class
        cateService.getDefaultData().then (data) ->
          $scope.year = data.currentYear
          $scope.availableYears = data.availableYears
          $scope.clazz = data.clazz  
      else if $routeParams.year and $routeParams.clazz
        # we already have a route
        $scope.year = $routeParams.year
        $scope.clazz = $routeParams.clazz
        path = $location.path()
        $scope.mode = path.substring(path.lastIndexOf('/') + 1)
      $scope.$watch('[year,clazz,mode]', ->
        if $scope.year? and $scope.clazz? and $scope.mode?
          $location.path("/#{$scope.year}/#{$scope.clazz}/#{$scope.mode}"))
        , true)

    $scope.setMode = (mode) ->
      $scope.mode = mode

class TimelineController
  constructor: (@$routeParams, @cateService, @$scope) ->
    @cateService.getCourses(@$routeParams.year, @$routeParams.clazz).then (courses) ->
      console.log courses

class CoursesController
  constructor: (@$routeParams, @cateService, @$scope) ->
    @cateService.getCourses(@$routeParams.year, @$routeParams.clazz).then (courses) ->
      $scope.courses = courses

angular.module("cate.controllers", [])
  .controller("headerController", ['cateService', '$scope', '$location', '$routeParams', HeaderController])
  .controller("timelineController", ['$routeParams', 'cateService', '$scope', TimelineController])
  .controller("coursesController", ['$routeParams', 'cateService', '$scope', CoursesController])