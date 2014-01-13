HeaderController = (cateService, $scope, $location, $routeParams) ->
    cateService.getAvailableClasses().then (classes) ->
      $scope.availableClasses = classes
    cateService.getAvailableYears().then (availableYears) ->
      $scope.availableYears = availableYears
    $scope.$on '$routeChangeSuccess', ->
      if $location.path() is '/'
        $scope.mode = 'timeline'
        # get the current year/class
        cateService.getDefaultData().then (data) ->
          $scope.year = data.currentYear
          $scope.clazz = data.clazz  
      else if $routeParams.year and $routeParams.clazz
        # we already have a route
        $scope.year = $routeParams.year
        $scope.clazz = $routeParams.clazz
        path = $location.path()
        $scope.mode = path.substring(path.lastIndexOf('/') + 1)
      $scope.$watch '[year,clazz,mode]', (->
        if $scope.year? and $scope.clazz? and $scope.mode?
          $location.path("/#{$scope.year}/#{$scope.clazz}/#{$scope.mode}"))
        , true

    $scope.setMode = (mode) ->
      $scope.mode = mode

TimelineController = ($routeParams, cateService, $scope) ->
  cateService.getCourses($routeParams.year, $routeParams.clazz).then (courses) ->
    console.log courses

CoursesController = ($routeParams, cateService, $scope) ->
  cateService.getCourses($routeParams.year, $routeParams.clazz).then (courses) ->
    $scope.year = $routeParams.year
    $scope.courses = (course for course in courses when course.notesUrl?)

CourseController = (cateService, $http, $scope) ->
  course = $scope.course
  $scope.downloadStatus = {}
  $scope.loadNotes = ->
    if course.notesUrl?
      cateService.getNotes($scope.$parent.year, course.notesUrl).then (notes) ->
        $scope.notes = notes
  $scope.downloadAll = ->
    chrome.fileSystem.chooseEntry { type: 'openDirectory' }, (directory) ->
      maxIndex = undefined
      for note in $scope.notes
        if !maxIndex? or maxIndex < note.index 
          maxIndex = note.index
      digits = (maxIndex + '').length

      for note in $scope.notes
        do (note) ->
          paddedIndex = note.index + ''
          paddedIndex = '0' + paddedIndex until paddedIndex.length == digits

          errorHandler = ->
            $scope.downloadStatus[note.index] = 'failed'

          $scope.downloadStatus[note.index] = 'downloading'

          $http(
            url: note.downloadUrl
            method: 'GET'
            responseType: 'blob')
            .success (fileContents, status, headers) ->
              disposition = headers('Content-Disposition')
              filenameMatch = /^attachment; filename=\"(.+)\"$/.exec disposition

              filename = "#{paddedIndex} - #{filenameMatch[1]}"
              
              directory.getFile filename, { create: true}, ((file) ->
                file.createWriter ((writer) ->
                  writer.onerror = errorHandler
                  writer.onwrite = ->
                    $scope.downloadStatus[note.index] = 'complete'
                  writer.write fileContents
                  ), errorHandler), errorHandler
            .error errorHandler

angular.module("cate.controllers", [])
  .controller("headerController", ['cateService', '$scope', '$location', '$routeParams', HeaderController])
  .controller("timelineController", ['$routeParams', 'cateService', '$scope', TimelineController])
  .controller("coursesController", ['$routeParams', 'cateService', '$scope', CoursesController])
  .controller("courseController", ['cateService', '$http', '$scope', CourseController])