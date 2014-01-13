DownloadsDirective = ($http, $controller) ->
  templateUrl: 'partials/downloads.html'
  scope: true
  link: ($scope, elem, attrs) ->
    $controller 'downloadsController',
      $http: $http
      $scope: $scope

    $scope.$watch attrs.items, (items) ->
      $scope.items = items

angular.module('cate.directives', [])
  .directive('downloads', ['$http', '$controller', DownloadsDirective])