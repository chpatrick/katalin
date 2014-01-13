HeaderController = (cateService, $scope, $location, $routeParams) ->
    console.log 'creating header controller'
    cateService.getAvailableClasses().then (classes) ->
      $scope.availableClasses = classes
    cateService.getAvailableYears().then (availableYears) ->
      $scope.availableYears = availableYears
    $scope.$on '$routeChangeSuccess', ->
      if $location.path() is '/'
        $scope.mode = 'courses'
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
        $scope.exercises = for event in course.events when event.specUrl?
          title = event.title or (event.type + ' '+ + event.index)
          {
            index: event.index
            title: title
            filename: title + '.pdf'
            downloadUrl: event.specUrl
            type: 'pdf'
          }

DownloadsController = ($http, $scope) ->
  course = $scope.course

  $scope.downloadStatus = {}
  setStatus = (item, status) -> ->
    switch $scope.$root.$$phase
      when '$apply', '$digest'
        $scope.downloadStatus[item.index] = status
      else
        $scope.$apply ->
          $scope.downloadStatus[item.index] = status

  $scope.view = (item) ->
    $http(
      url: item.downloadUrl
      method: 'GET'
      responseType: 'blob')
      .success (fileContents) ->
        reader = new FileReader()
        reader.onload = ->
          webview = $('<webview></webview>')
          webview.appendTo 'body'
          webview.attr('src', reader.result)
        reader.readAsDataURL fileContents

  $scope.download = (item) ->
    setStatus(item, 'downloading')()
    error = setStatus item, 'failed'

    $http(
      url: item.downloadUrl
      method: 'GET'
      responseType: 'blob')
      .success (fileContents, status, headers) ->
        filename = if item.filename?
          item.filename
        else
          disposition = headers('Content-Disposition')
          filenameMatch = /^attachment; filename=\"(.+)\"$/.exec disposition
          filenameMatch[1]
        
        chrome.fileSystem.chooseEntry { type: 'saveFile', suggestedName: filename}, (file) ->
          file.createWriter ((writer) ->
            writer.onerror = error
            writer.onwrite = setStatus item, 'complete'
            writer.write fileContents
            ), error
      .error error

  $scope.downloadAll = ->
    chrome.fileSystem.chooseEntry { type: 'openDirectory' }, (directory) ->
      maxIndex = undefined
      for item in $scope.items
        if !maxIndex? or maxIndex < item.index 
          maxIndex = item.index
      digits = (maxIndex + '').length

      for item in $scope.items when item.downloadUrl?
        do (item) ->
          paddedIndex = item.index + ''
          paddedIndex = '0' + paddedIndex until paddedIndex.length == digits

          setStatus(item, 'downloading')()
          error = setStatus item, 'failed'

          $http(
            url: item.downloadUrl
            method: 'GET'
            responseType: 'blob')
            .success (fileContents, status, headers) ->
              filename = if item.filename?
                item.filename
              else
                disposition = headers('Content-Disposition')
                filenameMatch = /^attachment; filename=\"(.+)\"$/.exec disposition

                filenameMatch[1]

              filename = paddedIndex + ' - ' + filename
              
              directory.getFile filename, { create: true}, ((file) ->
                file.createWriter ((writer) ->
                  writer.onerror = error
                  writer.onwrite = setStatus item, 'complete'
                  writer.write fileContents
                  ), error), error
            .error error

AuthController = (cateService, $scope) ->
  $scope.authenticated = null
  $scope.check = ->
     cateService.checkAuth().then (authenticated) ->
      $scope.authenticated = authenticated
  $scope.check()

angular.module("cate.controllers", [])
  .controller("authController", ['cateService', '$scope', AuthController])
  .controller("headerController", ['cateService', '$scope', '$location', '$routeParams', HeaderController])
  .controller("coursesController", ['$routeParams', 'cateService', '$scope', CoursesController])
  .controller("courseController", ['cateService', '$http', '$scope', CourseController])
  .controller("downloadsController", ['$http', '$scope', DownloadsController])