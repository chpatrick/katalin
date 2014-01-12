class CateService
  CATE_BASE = 'https://cate.doc.ic.ac.uk'

  constructor: (@$http, @$q) ->
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
      @$q.when @defaultData
    else
      service = this

      @getPage('/').then (response) ->
        data = {}

        doc = response.data
        studentParams = $('a[href*="student.cgi?key="]', doc).attr('href')
        match = /student\.cgi\?key=(\d+):(\w+):(\w+)/.exec studentParams

        if match?
          [ data.currentYear, data.clazz, data.username ] = match[1..]
        else
          # handle parse error

        data.availableYears = $('option:contains("Change academic year")', doc).siblings().map(->
          match = /personal\.cgi\?keyp=(\d+)/.exec $(this).attr('value')

          if match? then match[1] else null).toArray()
        data.availableYears.unshift data.currentYear

        service.defaultData = data

  getAvailableClasses: ->
    courses = []
    for year in [1..4]
      courses.push
        code: 'c' + year
        degree: 'Computing'
        name: 'Computing ' + year
      courses.push
        code: 'j' + year
        degree: 'JMC'
        name: 'JMC ' + year
    for year in [2..4]
      courses.push
        code: 'i' + year
        degree: 'ISE'
        name: 'ISE ' + year
    courses.push
      code: 'v5'
      degree: 'MSc'
      name: 'MSC Computing'
    courses.push
      code: 's5'
      degree: 'MSc'
      name: 'MSC Computing Spec'
    courses.push
      code: 'a5'
      degree: 'MSc'
      name: 'MSC Advanced'
    courses.push
      code: 'r5'
      degree: 'MSc'
      name: 'MSC Research'
    courses.push
      code: 'y5'
      degree: 'MSc'
      name: 'MSC Industrial'
    courses.push
      code: 'b5'
      degree: 'MSc'
      name: 'MSC Bioinformatic'
    courses.push
      code: 'r6'
      degree: 'Other'
      name: 'PhD'
    courses.push
      code: 'occ'
      degree: 'Other'
      name: 'Occasional'
    courses.push
      code: 'ext'
      degree: 'Other'
      name: 'External'

    @$q.when courses

angular.module('cate.services', [])
  .service('cateService', ['$http', '$q', CateService])