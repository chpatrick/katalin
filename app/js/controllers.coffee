class HeaderController
  constructor: (@cateService) ->
    @cateService.getDefaultData().then (data) ->
      console.log data

angular.module("cate.controllers", [])
  .controller("headerController", ['cateService', HeaderController])