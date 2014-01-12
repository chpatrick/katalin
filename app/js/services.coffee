class CateService
  CATE_BASE = 'https://cate.doc.ic.ac.uk'

  constructor: (@$http) ->
    console.log 'creating cate service'

    @defaultData = null

  getPage: (path, params) ->
    @$http
      url: CATE_BASE + path
      method: 'GET'
      params: params
      responseType: 'document'

  getDefaultData: ->
    if @defaultData?
      $q.when @defaultData
    else
      @getPage('/').then (response) ->
        data = {}

        doc = response.data
        studentParams = $('a[href*="student.cgi?key="]', doc).attr('href')
        match = /student\.cgi\?key=(\d+):(\w+):(\w+)/.exec studentParams

        if match?
          [ data.currentYear, data.course, data.username ] = match[1..]
        else
          # handle parse error

        data.availableYears = $('option:contains("Change academic year")', doc).siblings().map ->
          match = /personal\.cgi\?keyp=(\d+)/.exec $(this).attr('value')

          if match?
            yearId: match[1]
            yearName: $(this).text()
          else
            null

        @defaultData = data

angular.module('cate.services', [])
  .service('cateService', ['$http', CateService])