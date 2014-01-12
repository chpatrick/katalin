class HeaderController
  constructor: (@cateService, @$scope) ->
    $scope.mode = 'timeline'
    @cateService.getAvailableClasses().then (classes) ->
      $scope.availableClasses = classes
    @cateService.getDefaultData().then (data) ->
      $scope.year = data.currentYear
      $scope.availableYears = data.availableYears
      $scope.clazz = data.clazz
      $scope.$watch '[year,clazz,mode]', (-> window.location.hash = "#/#{$scope.year}/#{$scope.clazz}/#{$scope.mode}"), true

    $scope.setMode = (mode) ->
      $scope.mode = mode


angular.module("cate.controllers", [])
  .controller("headerController", ['cateService', '$scope', HeaderController])