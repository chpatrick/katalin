class CateService
  CATE_BASE = 'https://cate.doc.ic.ac.uk'

  constructor: (@$http, @$q) ->
    @defaultData = null
    @cachedCourses = undefined

  checkAuth: ->
    @$http(
      url: CATE_BASE
      method: 'HEAD'
    ).then (-> true), (-> false)

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
      @getPage('/').then (response) =>
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

        @defaultData = data

  getUsername: ->
    @getDefaultData().then (defaultData) -> defaultData.username

  getAvailableYears: ->
    @getDefaultData().then (data) -> data.availableYears

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

  monthNumbers =
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12

  parseTimetablePage: (year, clazz, period) ->
    @getUsername().then (username) =>
      @getPage('/timetable.cgi', {
        period: period,
        class: clazz,
        keyt: "#{year}:none:none:#{username}"
      }).then (response) ->
        doc = response.data

        rows = $('body > table:first > tbody > tr', doc)

        colMonth = null
        colDay = null

        courses = {}

        subscribed = true

        rowNum = 0
        while rowNum < rows.length
          row = rows.eq rowNum

          if not colMonth? and row.children().first().attr('colspan') == '4'
            # found a month row
            firstMonth = null
            for monthCell, monthCellNum in $('th:gt(0)', row)
              monthNum = monthNumbers[$(monthCell).text().trim()]
              if monthNum?
                firstMonth = monthNum - monthCellNum
                break

            colMonth = []
            for monthCell, monthCellNum in $('th:gt(0)', row)
              for i in [1..$(monthCell).attr('colspan')]
                colMonth.push (firstMonth + monthCellNum)

            # skip the week row to get to the day row
            rowNum += 2
            row = rows.eq rowNum

            colDay = []
            for dayCell in $('th:gt(0)', row)
              dayText = $(dayCell).text()
              colDay.push (if dayText isnt '' then dayText * 1 else null)
          else if row.text().indexOf('level 2 or higher') isnt -1
            # found the subscribed courses separator
            subscribed = false
          else
            courseTitle = $('td[bgcolor="white"]:nth-child(2) > b:first-child', row).first()
            if courseTitle.length
              # found a course
              courseHeader = courseTitle.parent()
              titleContents = courseTitle.contents()
              course =
                code: titleContents.eq(0).text()
                title: titleContents.eq(1).text().substring(3)
                notesUrl: courseHeader.find('a[href*="notes.cgi"]').attr('href')
                subscribed: subscribed
                events: {}

              courseRowCount = courseHeader.attr('rowspan')
              for courseRowNum in [0...courseRowCount]
                courseCells = undefined
                if courseRowNum == 0
                  courseCells = row.children().slice(3)
                else
                  rowNum++
                  row = rows.eq rowNum

                  courseCells = row.children()

                prevTermStartDay = null
                if courseCells.first().find('img[src*="arrowredright"]')
                  # first event continues from last term
                  prevTermStartDay = new Date(courseCells.first().text())
                
                courseCells = courseCells.slice 1

                nextTermEndDay = null
                if courseCells.last().find('img[src*="arrowredright"]').length
                  # last event continues next term
                  nextTermEndDay = new Date(courseCells.last().text())
                  courseCells = courseCells.slice 0, -1

                colDate = (col) ->
                  eventYear = year
                  eventMonth = colMonth[col]
                  if eventMonth > 12
                    eventMonth -= 12
                    eventYear++
                  new Date eventYear, eventMonth - 1, colDay[col]

                col = 0
                courseCells.each (courseCellNum) ->
                  colStart = col
                  col += $(this).attr('colspan') * 1
                  colEnd = col - 1

                  if not $(this).is(':empty')
                    event = {}

                    event.start = if courseCellNum is 0 and prevTermStartDay?
                      prevTermStartDay
                    else
                      colDate colStart

                    event.end = if courseCellNum is courseCells.length - 1 and nextTermEndDay?
                      nextTermEndDay
                    else
                      colDate colEnd

                    eventInfo = $('> b:first-child', this)
                    eventLink = $('> a[href*="showfile.cgi"]', this)
                    eventText = $(this).contents().eq(1).text()

                    eventInfoText = undefined
                    if eventInfo.length
                      eventInfoText = eventInfo.text()
                      if eventLink.length
                        event.title = eventLink.text()
                      else if eventText != ''
                        event.title = eventText.trim()
                    else
                      eventInfoText = eventLink.text()
                    if eventLink.length
                      event.specUrl = CATE_BASE + '/' + eventLink.attr('href')

                    [ event.index, event.type ] = eventInfoText.split(':')

                    course.events[event.index] = event

              courses[course.code] = course

          rowNum++

        courses

  getCourses: (year, clazz) ->
    if @cachedCourses? and @cachedCourses.year is year and @cachedCourses.clazz is clazz
      @$q.when @cachedCourses.courses
    else
      @$q.all(@parseTimetablePage(year, clazz, period) for period in [1..7]).then (results) =>
        courses = {}

        for result in results
          for courseCode, course of result
            if courses[courseCode] # we already have this course, merge events
              for eventIndex, event of course.events
                courses[courseCode].events[eventIndex] = event
            else
              courses[courseCode] = course

        @cachedCourses =
          year: year
          clazz: clazz

        # convert hashes to arrays
        @cachedCourses.courses = for courseCode, course of courses
          arrayEvents = []
          for eventIndex, event of course.events
            arrayEvents.push event
          course.events = arrayEvents
          course

  getNotes: (year, notesUrl) ->
    @getPage('/' + notesUrl).then (response) ->
      doc = response.data

      $('form table tbody tr:gt(1)', doc).map ->
        note =
          index: $('td:eq(0)', this).text() * 1
          title: $('td:eq(1)', this).text()
          type: $('td:eq(2)', this).text()

        switch note.type
          when 'URL*'
            # again most of the key values aren't needed
            identifierMatch = /clickpage\((\d+)\)/.exec($('td:eq(1) a', this).attr('onclick'))
            note.visitUrl = "#{CATE_BASE}/showfile.cgi?key=#{year}:0:#{identifierMatch[1]}:0:NOTES:0"
          else
            note.downloadUrl = CATE_BASE + '/' + $('td:eq(1) a', this).attr('href')
        note

angular.module('cate.services', [])
  .service('cateService', ['$http', '$q', CateService])