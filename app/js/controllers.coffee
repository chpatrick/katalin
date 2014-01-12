class HeaderController
  constructor: (@cateService, @$scope) ->
    @cateService.getAvailableClasses().then (classes) ->
      $scope.availableClasses = classes
    @cateService.getDefaultData().then (data) ->
      $scope.year = data.currentYear
      $scope.availableYears = data.availableYears
      $scope.clazz = data.clazz
      $scope.$watch '[year,clazz]', (-> window.location.hash = "#/#{$scope.year}/#{$scope.clazz}"), true


angular.module("cate.controllers", [])
  .controller("headerController", ['cateService', '$scope', HeaderController])