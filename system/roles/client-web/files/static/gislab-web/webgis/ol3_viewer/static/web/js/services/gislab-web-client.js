(function() {
	'use strict';

	angular
		.module('gl.web')
		.config(['$httpProvider', function($httpProvider) {
			// Intercept POST requests, convert to standard form encoding
			$httpProvider.defaults.headers.post["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8";
			$httpProvider.defaults.transformRequest.unshift(function (data) {
				var key, result = [];
				for (key in data) {
					if (data.hasOwnProperty(key)) {
						result.push(encodeURIComponent(key) + "=" + encodeURIComponent(data[key]));
					}
				}
				return result.join("&");
			});
		}])
		.provider('gislabClient', GislabClientProvider);

	function GislabClientProvider() {
		this.config = {};
	}

	GislabClientProvider.prototype.configure = function(config) {
		this.config = config;
	}

	GislabClientProvider.prototype.$get = ['$http', '$q', function($http, $q) {
		return new gislabClient(this.config, $http, $q);
	}];

	function gislabClient(config, $http, $q) {
		function GislabClient() {
			this.currentRequest = null;
			this.serverUrl = config.server || '';
		};

		GislabClient.prototype._deferredRequest = function(httpParams) {
			var deferredAbort = $q.defer();
			var requestParams = angular.extend({
					timeout: deferredAbort.promise
				}, httpParams);
			var request = $http(requestParams);
			var promise = request.then(
				function (response) {
					if (!response.headers('X-GIS.lab-Version')) {
						return $q.reject({
							invalid_server: true,
							canceled: false
						});
					}
					return response.data;
				}, function (response) {
					return $q.reject({
						invalid_server: response.headers('X-GIS.lab-Version')? false : true,
						canceled: promise.canceled === true,
						status_code: response.status,
					});
				}
			);
			promise.abort = function() {
				promise.canceled = true;
				deferredAbort.resolve();
			}
			promise.finally(function() {
				promise.abort = angular.noop;
				deferredAbort = request = promise = null;
			});
			this.currentRequest = promise;
			return promise;
		};

		GislabClient.prototype.abortRequest = function() {
			if (this.currentRequest && this.currentRequest.abort) {
				this.currentRequest.abort();
			}
		};

		GislabClient.prototype.login = function(server, username, password) {
			if (username && password) {
				this._secure = true;
				this.serverUrl = 'https://{0}'.format(server);
				return this._deferredRequest({
					url: '{0}/mobile/login/'.format(this.serverUrl),
					method: 'post',
					withCredentials: true,
					data: {
						username: username,
						password: password
					}
				});
			} else {
				this._secure = false;
				this.serverUrl = 'http://{0}'.format(server);
				return $q.when();
			}
			/*
			return $http({
				method: 'POST',
				url: '{0}/mobile/login/'.format(this.getServerUrl(server)),
				headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
				transformRequest: function(obj) {
					var str = [];
					for(var p in obj)
					str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
					return str.join("&");
				},
				data: {username: username, password: password},
			});*/
		};

		GislabClient.prototype.logout = function() {
			if (this.serverUrl) {
				return this._deferredRequest({
					url: '{0}/mobile/logout/'.format(this.serverUrl),
					withCredentials: true
				});
			} else {
				return $q.when();
			}
		}

		GislabClient.prototype.project = function(project) {
			var url;
			if (project && project !== 'empty') {
				url = '{0}/mobile/config.json?PROJECT={1}'.format(this.serverUrl, encodeURIComponent(project));
			} else {
				url = '{0}/mobile/config.json?'.format(this.serverUrl);
			}
			return this._deferredRequest({
				url: url,
				method: 'get',
				withCredentials: true
			});
		};

		GislabClient.prototype.userProjects = function() {
			return this._deferredRequest({
				url: '{0}/projects.json'.format(this.serverUrl),
				method: 'get',
				withCredentials: true
			});
		};

		return new GislabClient();
	};
})();
